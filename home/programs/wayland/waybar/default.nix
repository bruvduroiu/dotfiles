{ config, lib, pkgs, ... }:

let
  # This file serves both compositors: framework13 runs niri, iso still
  # runs Hyprland — only the workspace/submap cluster differs.
  isHyprland = config.wayland.windowManager.hyprland.enable;

  c = config.lib.stylix.colors.withHashtag;
  isDark = config.stylix.polarity == "dark";
  bgAlpha = if isDark then "0.6" else "0.85";
  hoverAlpha = if isDark then "0.9" else "0.95";

  # monocle dots: cyan-ish base0C to complement the base0E workspace dots;
  # light schemes wash out low pango alpha, so dim less aggressively there
  monocleAccent = c.base0C;
  monocleDimAlpha = if isDark then "40%" else "65%";

  # Combined WireGuard indicator: one widget, both tunnels. wg0 (home hub) then
  # wg-mullvad (egress), each drawn as its own glyph and colored independently
  # via inline pango — a single waybar module has only one CSS class, so
  # per-glyph state can't come from CSS. Each glyph's color IS its health:
  #   white  (foreground) = up + fresh handshake — inconspicuous, all-good
  #   orange (base09)      = up but no recent handshake (not passing traffic)
  #   red    (base08)      = interface gone (for wg-mullvad: real IP leaking)
  #
  # Up/down is interface presence (`ip link`, no privilege). Handshake freshness
  # needs `wg show … dump` (root) — the absolute path below matches the
  # passwordless sudo rules in system/network/wireguard.nix EXACTLY (sudo
  # secure_path would otherwise resolve a different store path and deny).
  wgBin = "${pkgs.wireguard-tools}/bin/wg";
  wgWhite = if isDark then c.base05 else c.base00;   # matches @foreground
  wgOrange = c.base09;
  wgRed = c.base08;
  wireguard-indicator = pkgs.writeShellApplication {
    name = "waybar-wireguard-indicator";
    runtimeInputs = with pkgs; [ iproute2 wireguard-tools jq coreutils gawk curl ];
    text = ''
      # Resolve a Mullvad relay hostname from its peer public key, e.g.
      # "de-fra-wg-001 (Frankfurt, Germany)". The relay catalog (key → name)
      # is cached and refreshed in the BACKGROUND only when missing/stale, so
      # the 10s poll never blocks on the network and works offline once warm.
      RELAY_API="https://api.mullvad.net/public/relays/wireguard/v1"
      CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/waybar-mullvad-relays.tsv"
      relay_name() {
        local pk=$1 age_s
        mkdir -p "$(dirname "$CACHE")"
        if [ ! -s "$CACHE" ]; then age_s=999999
        else age_s=$(( $(date +%s) - $(stat -c %Y "$CACHE") )); fi
        if [ "$age_s" -gt 86400 ]; then
          # detach: never let the fetch stall waybar; next poll picks it up
          ( curl -sf --max-time 15 "$RELAY_API" | jq -r '
              .countries[] as $c | $c.cities[] as $ci | $ci.relays[]
              | [.public_key, .hostname, $ci.name, $c.name] | @tsv' \
              > "$CACHE.tmp" 2>/dev/null && mv "$CACHE.tmp" "$CACHE" ) >/dev/null 2>&1 &
        fi
        [ -s "$CACHE" ] || return 0
        awk -F'\t' -v k="$pk" '$1==k {print $2" ("$3", "$4")"; exit}' "$CACHE"
      }
      # Emit "<color>\t<glyph>\t<tooltip line>" for one interface.
      state() {
        local iface=$1 glyph=$2 label=$3 downmsg=$4
        if ! ip link show "$iface" >/dev/null 2>&1; then
          printf '%s\t%s\t%s\n' '${wgRed}' "$glyph" "$downmsg"
          return
        fi
        local pk="" endpoint="" hs="" dump now age where r
        dump=$(sudo ${wgBin} show "$iface" dump 2>/dev/null || true)
        read -r pk endpoint hs < <(printf '%s\n' "$dump" | awk 'NR==2 {print $1, $3, $5}') || true
        now=$(date +%s)
        where=$endpoint
        if [ "$iface" = wg-mullvad ] && [ -n "$pk" ]; then
          r=$(relay_name "$pk"); [ -n "$r" ] && where=$r
        fi
        if [ -n "''${hs:-}" ] && [ "$hs" -gt 0 ]; then age=$(( now - hs )); else age=-1; fi
        if [ "$age" -ge 0 ] && [ "$age" -le 180 ]; then
          printf '%s\t%s\t%s\n' '${wgWhite}' "$glyph" \
            "$label connected — handshake ''${age}s ago ($where)"
        else
          printf '%s\t%s\t%s\n' '${wgOrange}' "$glyph" \
            "$label up but NO recent handshake — not passing traffic ($where)"
        fi
      }
      IFS=$'\t' read -r c0 g0 t0 < <(state wg0 "󰋜" "Home hub" \
        "Home hub DOWN — no LAN/overlay access")
      IFS=$'\t' read -r cm gm tm < <(state wg-mullvad "󰦝" "Mullvad" \
        "Mullvad DOWN — traffic unprotected (real IP leaking)")
      text="<span color='$c0'>$g0</span> <span color='$cm'>$gm</span>"
      jq -cn --arg t "$text" --arg tip "$t0"$'\n'"$tm" '{text:$t, tooltip:$tip}'
    '';
  };

  # monocle window dots: one dot per tiled window on the active workspace,
  # active window filled — only when the workspace's layout is monocle
  # (hyprctl activeworkspace -j exposes tiledLayout on 0.55). Empty text
  # otherwise, which hides the module. Event-driven via the hyprland IPC
  # event socket, so no polling.
  monocle-indicator = pkgs.writeShellApplication {
    name = "waybar-monocle-indicator";
    runtimeInputs = with pkgs; [ jq socat ];
    text = ''
      emit() {
        local ws layout wsid active out tooltip addr title
        ws=$(hyprctl activeworkspace -j)
        layout=$(jq -r .tiledLayout <<<"$ws")
        if [ "$layout" != monocle ]; then
          printf '{"text":""}\n'
          return
        fi
        wsid=$(jq -r .id <<<"$ws")
        active=$(hyprctl activewindow -j | jq -r .address)
        out=""
        tooltip=""
        while IFS=$'\t' read -r addr title; do
          if [ "$addr" = "$active" ]; then
            out+="<span color='${monocleAccent}'>󰝥</span> "
            tooltip+="● $title"$'\n'
          else
            out+="<span color='${monocleAccent}' alpha='${monocleDimAlpha}'>󰝦</span> "
            tooltip+="○ $title"$'\n'
          fi
        done < <(hyprctl clients -j \
          | jq -r --argjson w "$wsid" \
              '.[] | select(.workspace.id == $w and .mapped and (.floating | not)) | [.address, .title] | @tsv')
        jq -cn --arg t "''${out% }" --arg tip "''${tooltip%$'\n'}" '{text: $t, tooltip: $tip}'
      }
      emit || true
      socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" \
        | while read -r ev; do
            case "$ev" in
              workspace*|focusedmon*|activewindowv2*|openwindow*|closewindow*|movewindow*|changefloatingmode*|configreloaded*)
                emit || true ;;
            esac
          done
    '';
  };
  # niri column dots: the focused workspace's name plus one dot per column
  # (filled = focused column), so the horizontal shape of the scrolling
  # strip is visible at a glance — the one thing niri hides. Floating
  # windows show as a dim "+n" (they don't take part in column nav).
  # Same architecture as the old monocle-indicator: any window/workspace
  # event on the niri event stream triggers a cheap re-query; no polling.
  niri-columns = pkgs.writeShellApplication {
    name = "waybar-niri-columns";
    runtimeInputs = with pkgs; [ jq niri ];
    text = ''
      emit() {
        jq -cn \
          --argjson ws "$(niri msg --json workspaces)" \
          --argjson win "$(niri msg --json windows)" \
          --arg accent '${monocleAccent}' --arg dim '${monocleDimAlpha}' '
          (first($ws[] | select(.is_focused))) as $fw
          | ($fw.name // ($fw.idx | tostring)) as $label
          | [$win[] | select(.workspace_id == $fw.id)] as $wins
          | [$wins[] | select(.layout.pos_in_scrolling_layout != null)] as $tiled
          | ([$tiled[] | .layout.pos_in_scrolling_layout[0]] | unique | sort) as $cols
          | (first($wins[] | select(.is_focused)) // null) as $focw
          | (($focw.layout.pos_in_scrolling_layout // [-1])[0]) as $fcol
          | ([$wins[] | select(.layout.pos_in_scrolling_layout == null)] | length) as $nfloat
          | ($cols | map(
              if . == $fcol
              then "<span color=\($accent | tojson)>󰝥</span>"
              else "<span color=\($accent | tojson) alpha=\($dim | tojson)>󰝦</span>"
              end) | join(" ")) as $dots
          | ($tiled | sort_by(.layout.pos_in_scrolling_layout)
             | map((if .is_focused then "● " else "○ " end) + (.title // .app_id // "?"))
             | join("\n")) as $tip
          | { text: ($label
                     + (if $dots == "" then "" else "  " + $dots end)
                     + (if $nfloat > 0
                        then "  <span alpha=\($dim | tojson)>+\($nfloat)</span>"
                        else "" end)),
              tooltip: (if $tip == "" then "empty" else $tip end) }'
      }
      emit || true
      niri msg --json event-stream | while read -r ev; do
        case "$ev" in
          *Window*|*Workspace*) emit || true ;;
        esac
      done
    '';
  };
in {
  # Same login race as swaybg: graphical-session.target can fire before
  # niri exports WAYLAND_DISPLAY into the user manager. Retry calmly.
  systemd.user.services.waybar = lib.mkIf (!isHyprland) {
    Unit.StartLimitIntervalSec = 0;
    Service.RestartSec = 2;
  };

  programs.waybar = {
    enable = true;
    # Systemd-managed on niri: every HM activation restarts the unit, so
    # config changes actually land (a spawned waybar lives on with the
    # config it read at login). Hyprland hosts keep their exec-once spawn.
    systemd.enable = !isHyprland;
    # Theme variables come from stylix and so must be generated here; every
    # structural rule lives in ./style.css (pure CSS, referencing these names).
    # GTK CSS @define-color accepts color expressions, so the two alpha scalars
    # become fully-composited colors (@panel, @panel-hover) — the stylesheet
    # then needs zero interpolation. Order matters: @panel references
    # @background, so @background is defined first.
    style = ''
      @define-color foreground ${if isDark then c.base05 else c.base00};
      @define-color background ${if isDark then c.base00 else c.base04};
      @define-color color9 ${c.base0E};
      @define-color urgent ${c.base08};
      @define-color panel alpha(@background, ${bgAlpha});
      @define-color panel-hover alpha(@background, ${hoverAlpha});
    '' + builtins.readFile ./style.css;
    settings = [{
      layer = "top";
      position = "top";
      height = 24;
      spacing = 5;
      margin = "0";
      modules-left = ["clock" "custom/timew" "custom/playerctl"];
      # niri: column dots + focused title. The stock niri/workspaces module
      # is deliberately absent — named workspaces always exist, so it
      # renders permanent squatter entries with no way to filter them.
      modules-center = if isHyprland
        then ["hyprland/submap" "hyprland/workspaces" "custom/monocle"]
        else ["custom/niri-columns"];
      modules-right = ["custom/fcitx" "pulseaudio" "battery" "power-profiles-daemon" "custom/wireguard" "network" "group/hardware" "custom/gpu" "temperature" "idle_inhibitor" "custom/dnd" "privacy"];
      # workspace label + live column dots (see niri-columns above);
      # scroll walks the columns, click opens the overview
      "custom/niri-columns" = {
        format = "{}";
        return-type = "json";
        exec = "${niri-columns}/bin/waybar-niri-columns";
        on-click = "niri msg action toggle-overview";
        on-scroll-up = "niri msg action focus-column-left";
        on-scroll-down = "niri msg action focus-column-right";
        tooltip = true;
      };

      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "active" = "";
          "default" = "";
          "empty" = "";
          # named special workspaces (waybar strips the "special:" prefix)
          "chat" = "󰍩";
          "work" = "󰒋";
        };
        on-click = "activate";
        icon-size = 10;
        sort-by-number= true;
        show-special = true;
        persistent-workspaces = {
          "1" = [];
          "2" = [];
          "3" = [];
          "4" = [];
          "5" = [];
        };
      };

      # monocle window index dots (see monocle-indicator above); scroll cycles
      "custom/monocle" = {
        format = "{}";
        return-type = "json";
        exec = "${monocle-indicator}/bin/waybar-monocle-indicator";
        on-scroll-up = ''hyprctl dispatch "hl.dsp.layout('cyclenext')"'';
        on-scroll-down = ''hyprctl dispatch "hl.dsp.layout('cycleprev')"'';
        tooltip = true;
      };

      # Both tunnels in one widget (see wireguard-indicator above): wg0 glyph +
      # wg-mullvad glyph, each colored by its own health. Polled — the
      # connected→stale transition is time-based (handshake age), so an event
      # model alone wouldn't catch it. One widget, one click target, so buttons
      # are split across the tunnels (all in a terminal, interactive sudo — no
      # extra sudoers rule needed):
      #   left   → live `wg show` of both
      #   right  → fzf relay picker; the choice is pinned and re-resolved
      #            against Mullvad's live catalog on every interface start
      "custom/wireguard" = {
        format = "{}";
        return-type = "json";
        exec = "${wireguard-indicator}/bin/waybar-wireguard-indicator";
        interval = 10;
        on-click = "ghostty +new-window -e watch -n1 sudo wg show";
        on-click-right = "ghostty +new-window -e mullvad-jump pick";
      };

      # visible only while a submap (resize/launch/place) is active
      "hyprland/submap" = {
        format = "󰌌 {}";
        tooltip = false;
      };

      # mako do-not-disturb indicator; refreshed via RTMIN+9 from the toggle
      # bind and from meeting-guard (auto-mute while mic/screenshare live)
      "custom/dnd" = {
        format = "{}";
        return-type = "json";
        exec = "m=$(makoctl mode); if echo \"$m\" | grep -qx dnd; then printf '{\"text\":\"󰂛\",\"tooltip\":\"do not disturb\",\"class\":\"dnd\"}'; elif echo \"$m\" | grep -qx meeting; then printf '{\"text\":\"󰍬\",\"tooltip\":\"in a call — notifications muted\",\"class\":\"dnd\"}'; else printf '{\"text\":\"󰂚\",\"tooltip\":\"notifications on\"}'; fi";
        interval = "once";
        signal = 9;
        on-click = "makoctl mode -t dnd; pkill -RTMIN+9 waybar";
        on-click-right = "mako-history-menu";
      };

      "group/hardware" = {
        orientation = "inherit";
        modules = [
          "cpu"
          "memory"
          "disk"
        ];
        drawer = {
          transition-duration = 250;
        };
      };

      "custom/playerctl" = {
        format = " 󰐊 {}";
        return-type = "json";
        max-length = 40;
        exec = "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{artist}} - {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
        on-click = "playerctl play-pause";
        on-click-right = "playerctl next";
      };

      "custom/timew" = {
        format = "󰔟 {}";
        exec = "timew get dom.active.json | jq -r '.tags | join(\" \")'";
        exec-if = "timew get dom.active";
        interval = 10;
      };

      "idle_inhibitor" = {
        format = "{icon}";
        "format-icons" = {
          activated = "󰈈";
          deactivated = "󰈉";
        };
        tooltip = true;
      };

      clock = {
        format = "{:%H:%M}";
        interval = 15;
        format-alt = "󰃮 {:%Y-%m-%d}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "month";
          mode-mon-col = 3;
          weeks-pos = "right";
          on-scroll = 1;
          on-click-right = "mode";
          format = {
            months = "<span color='#d3c6aa'><b>{}</b></span>";
            days = "<span color='#e67e80'>{}</span>";
            weeks = "<span color='#a7c080'><b>W{}</b></span>";
            weekdays = "<span color='#7fbbb3'><b>{}</b></span>";
            today = "<span color='#dbbc7f'><b><u>{}</u></b></span>";
          };
        };
        actions = {
          on-click-right = "mode";
          on-click-forward = "tz_up";
          on-click-backward = "tz_down";
          on-scroll-up = "shift_up";
          on-scroll-down = "shift_down";
        };
      };

      cpu = {
        format = "󰘚 {usage}%";
        tooltip = true;
        interval = 1;
        on-click = "ghostty +new-window -e btop";
      };

      memory = {
        format = "󰍛 {used:0.1f}G/{total:0.1f}G";
        interval = 1;
        on-click = "ghostty +new-window -e btop";
      };

      temperature = {
        critical-threshold = 80;
        format = "{icon} {temperatureC}°C";
        format-icons = ["󱃃" "󰔏" "󱃂"];
        on-click = "ghostty +new-window -e s-tui";
      };

      battery = {
        states = {
          good = 95;
          warning = 30;
          critical = 1;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰚥 {capacity}%";
        format-alt = "{icon} {time}";
        format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
      };

      network = {
        format-wifi = "󰖩 {essid} ({signalStrength}%)";
        format-ethernet = "󰈀 {ifname}";
        format-linked = "󰈀 {ifname} (No IP)";
        format-disconnected = "󰖪 Disconnected";
        format-alt = "{ifname}: {ipaddr}/{cidr}";
        tooltip-format = "{ifname}: {ipaddr}";
        on-click = "ghostty +new-window -e sudo nmtui";
      };

      power-profiles-daemon = {
        format = "{icon}";
        tooltip-format = "Power profile: {profile}\nDriver: {driver}";
        tooltip = true;
        format-icons = {
          default = "󰗑";
          performance = "󰓅";
          balanced = "󰾅";
          power-saver = "󰾆";
        };
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        # no dedicated bluetooth module (duplicates badly) — BT sinks just
        # show as regular volume here
        format-bluetooth = "{icon} {volume}%";
        format-bluetooth-muted = "󰝟";
        format-muted = "󰝟";
        format-icons = {
          headphone = "󰋋";
          hands-free = "󰥰";
          headset = "󰋎";
          phone = "󰏲";
          portable = "󰄝";
          car = "󰄋";
          default = ["󰕿" "󰖀" "󰕾"];
        };
        on-click = "pwvucontrol";
        on-click-right = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        on-scroll-up = "pactl set-sink-volume @DEFAULT_SINK@ +2%";
        on-scroll-down = "pactl set-sink-volume @DEFAULT_SINK@ -2%";
      };

      "custom/gpu" = {
        format = "󰢮 {}%";
        exec = "cat /sys/class/drm/card*/device/gpu_busy_percent";
        interval = 2;
        tooltip-format = "GPU utilization";
      };

      disk = {
        interval = 30;
        format = "󰋊 {percentage_used}%";
        path = "/";
        on-click = "ghostty +new-window -e gdu /";
      };

      privacy = {
        icon-spacing = 4;
        icon-size = 16;
        modules = [
          {
            type = "screenshare";
            tooltip = true;
            tooltip-icon-size = 24;
          }
          {
            type = "audio-in";
            tooltip = true;
            tooltip-icon-size = 24;
          }
        ];
      };
    }];
  };
}
