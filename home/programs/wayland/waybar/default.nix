{ config, pkgs, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
  isDark = config.stylix.polarity == "dark";
  bgAlpha = if isDark then "0.6" else "0.85";
  hoverAlpha = if isDark then "0.9" else "0.95";

  # monocle dots: cyan-ish base0C to complement the base0E workspace dots;
  # light schemes wash out low pango alpha, so dim less aggressively there
  monocleAccent = c.base0C;
  monocleDimAlpha = if isDark then "40%" else "65%";

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
in {
  programs.waybar = {
    enable = true;
    style = ''
      @define-color foreground ${if isDark then c.base05 else c.base00};
      @define-color foreground-inactive ${if isDark then c.base04 else c.base03};
      @define-color background ${if isDark then c.base00 else c.base04};
      @define-color color9 ${c.base0E};

      * {
        font-family: JetBrainsMono Nerd Font;
        font-size: 17px;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        all: unset;
        color: @foreground;
      }

      .modules-left,
      .modules-center,
      .modules-right {
        color: @foreground;
        background: alpha(@background, ${bgAlpha});
        margin: 5px 10px;
        padding: 0 5px;
        border-radius: 15px;
      }
      .modules-left {
        padding: 0 5px;
      }
      .modules-center {
        padding: 0 10px;
        margin: 5 0 5 0;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #network,
      #pulseaudio,
      #custom-gpu,
      #custom-dnd,
      #custom-fcitx,
      #idle_inhibitor,
      #power-profiles-daemon {
        padding: 0 10px;
        border-radius: 15px;
      }

      #submap {
        padding: 0 10px;
        border-radius: 15px;
        color: @color9;
        font-style: italic;
      }

      #custom-dnd.dnd {
        color: @color9;
      }

      #custom-fcitx.zh {
        color: @color9;
      }

      #idle_inhibitor.activated {
        color: @color9;
      }

      #clock:hover,
      #battery:hover,
      #cpu:hover,
      #memory:hover,
      #disk:hover,
      #temperature:hover,
      #network:hover,
      #pulseaudio:hover,
      #custom-gpu:hover,
      #idle_inhibitor:hover,
      #power-profiles-daemon:hover {
        background: alpha(@background, ${hoverAlpha});
      }

      #workspaces {
        padding: 0px 5px;
      }

      #custom-monocle {
        padding: 0px 5px;
      }

      #workspaces button {
        all: unset;
        padding: 0px 5px;
        color: alpha(@color9, 0.4);
        transition: all 0.2s ease;
      }

      #workspaces button:hover {
        color: alpha(@color9, 0.7);
        border: none;
        text-shadow: 0px 0px 1.5px alpha(@color9, 0.5);
        transition: all 1s ease;
      }
      #workspaces button.active {
        color: @color9;
        border: none;
        text-shadow: 0px 0px 2px alpha(@color9, 0.5);
      }
      #workspaces button.empty {
        color: alpha(@foreground, 0.15);
        border: none;
        text-shadow: 0px 0px 1.5px alpha(@foreground, 0.1);
      }
      #workspaces button.empty:hover {
        color: alpha(@foreground, 0.3);
        border: none;
        text-shadow: 0px 0px 1.5px alpha(@foreground, 0.3);
        transition: all 1s ease;
      }
      #workspaces button.empty.active {
        color: @color9;
        border: none;
        text-shadow: 0px 0px 2px alpha(@color9, 0.5);
      }
      #workspaces button.urgent {
        color: ${c.base08};
        border: none;
        text-shadow: 0px 0px 2px alpha(${c.base08}, 0.7);
      }
    '';
    settings = [{
      layer = "top";
      position = "top";
      height = 24;
      spacing = 5;
      margin = "0";
      modules-left = ["clock" "custom/timew" "custom/playerctl"];
      modules-center = ["hyprland/submap" "hyprland/workspaces" "custom/monocle"];
      modules-right = ["custom/fcitx" "pulseaudio" "battery" "power-profiles-daemon" "network" "group/hardware" "custom/gpu" "temperature" "idle_inhibitor" "custom/dnd" "privacy"];
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
        on-click = "ghostty -e btop";
      };

      memory = {
        format = "󰍛 {used:0.1f}G/{total:0.1f}G";
        interval = 1;
        on-click = "ghostty -e btop";
      };

      temperature = {
        critical-threshold = 80;
        format = "{icon} {temperatureC}°C";
        format-icons = ["󱃃" "󰔏" "󱃂"];
        on-click = "ghostty -e s-tui";
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
        on-click = "ghostty -e sudo nmtui";
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
        on-click = "ghostty -e gdu /";
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
