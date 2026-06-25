{ config, lib, pkgs, ... }:

# Hyprland config generated natively by home-manager (configType = "lua").
#
# Replaces the hand-authored system/programs/hyprland/lua.nix: HM 26.05's
# wayland.windowManager.hyprland lua backend renders `settings` to hl.<name>(...)
# calls, with _var -> lua locals, _args -> multi-arg calls, and
# lib.generators.mkLuaInline -> verbatim raw lua. This sidesteps the
# nix-community/home-manager#9468 `$variable` bug that forced hand-authoring.
#
# Split: the NixOS module (system/programs/hyprland) keeps the UWSM session,
# portals and helper scripts and emits NO config; HM owns ~/.config/hypr/hyprland.lua.
#
# framework13-first: monitors/device/per-ws-monitor + stylix live here for now;
# generalised to a shared module + per-host overrides when phantom/iso migrate.

let
  inherit (lib.generators) mkLuaInline;

  # stylix border colours at HM level (framework13 has stylix; fall back to white).
  hasStylix = config ? lib && config.lib ? stylix;
  c = lib.optionalAttrs hasStylix config.lib.stylix.colors;
  active   = if hasStylix then "rgba(${c.base05}cc)" else "rgba(ffffffcc)";
  inactive = if hasStylix then "rgba(${c.base04}44)" else "rgba(ffffff44)";

  # framework13 touchpad accel + scroll curve (was the hosts/framework13 luaPrelude).
  accelpoints = "0.000 0.391 1.375 3.422 7.000 12.578 20.625 31.609 46.000 64.266 86.875 114.297 146.000 185.453 230.125 281.484 340.000 406.141 480.375 563.172";

  # bind helper: keys (raw lua expr) + dispatcher (raw lua expr) [+ opts attrs]
  b = keys: disp: { _args = [ (mkLuaInline keys) (mkLuaInline disp) ]; };
  bo = keys: disp: opts: { _args = [ (mkLuaInline keys) (mkLuaInline disp) opts ]; };
  # plain-key bind (no mod expression — bare key string)
  bk = key: disp: { _args = [ key (mkLuaInline disp) ]; };
  bko = key: disp: opts: { _args = [ key (mkLuaInline disp) opts ]; };

  # workspaces 1..10: switch / move / move-silent (was the genList in binds.nix /
  # the for-loop in lua.nix). key 10 -> "0".
  wsBinds = builtins.concatMap (i:
    let key = toString (lib.mod i 10); in [
      (b ''mod .. " + ${key}"''         "hl.dsp.focus({ workspace = ${toString i} })")
      (b ''mod .. " + SHIFT + ${key}"'' "hl.dsp.window.move({ workspace = ${toString i} })")
      (b ''mod .. " + CTRL + ${key}"''  "hl.dsp.window.move({ workspace = ${toString i}, follow = false })")
    ]) (lib.range 1 10);

  # vim-style window marks a..z (was markBinds): set / jump submap bodies.
  markLetters = lib.stringToCharacters "abcdefghijklmnopqrstuvwxyz";
  markSubmapBinds = action:
    (map (l: bk l ''hl.dsp.exec_cmd("hypr-mark ${action} ${l}")'') markLetters)
    ++ [ (bk "escape" ''hl.dsp.submap("reset")'') ];

  # dialog windows: float + center per title (was dialogRules).
  dialogTitles = [ "Open File" "Select a File" "Choose wallpaper" "Open Folder" "Save As" "Library" "File Upload" ];
  dialogRules = builtins.concatMap (t: [
    { match = { title = "^(${t})(.*)$"; }; float = true; }
    { match = { title = "^(${t})(.*)$"; }; center = true; }
  ]) dialogTitles;

  # place-submap: batched specific-window pixel ops have no typed helper -> exec_cmd
  # of a hyprctl --batch string in lua long-brackets [[ ]] (dodges quote/% escaping).
  placeBatch = s: ''hl.dsp.exec_cmd([[hyprctl --batch "${s}"]])'';
in {
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    configType = "lua";

    settings = {
      # ----- variables (-> lua locals) ------------------------------------
      mod         = { _var = "SUPER"; };
      menu        = { _var = "walker"; };
      terminal    = { _var = "uwsm app -- ghostty"; };
      fileManager = { _var = "uwsm app -- yazi"; };
      browser     = { _var = "uwsm app -- firefox"; };
      workBrowser = { _var = "uwsm app -- firefox -P work --no-remote"; };         # -P matches HM profile name; --no-remote = separate instance alongside personal
      hardBrowser = { _var = "uwsm app -- mullvad-browser"; };                     # ghost: Tor-Browser-minus-Tor, blends into the anti-fingerprint crowd
      webapp      = { _var = mkLuaInline ''browser .. " --new-tab"''; };

      # ----- env ----------------------------------------------------------
      env = [
        { _args = [ "HYPRCURSOR_THEME" "rose-pine-hyprcursor" ]; }
        { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
      ];

      # ----- monitors + per-device (framework13) --------------------------
      monitor = [
        { _args = [ { output = "DP-4";  mode = "3840x2160@60.00"; position = "0x0";    scale = 1;      vrr = 1; } ]; }
        { _args = [ { output = "eDP-1"; mode = "preferred";       position = "3840x0"; scale = 1.3333; vrr = 1; } ]; }
      ];
      device = [
        { _args = [ { name = "pixa3854:00-093a:0274-touchpad"; accel_profile = "custom ${accelpoints}"; scroll_points = accelpoints; natural_scroll = true; } ]; }
      ];

      # ----- autostart (was exec-once) ------------------------------------
      on = { _args = [ "hyprland.start" (mkLuaInline ''function()
        hl.exec_cmd("uwsm finalize")
        hl.exec_cmd("uwsm app -- waybar")
        hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store")
        hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")
        hl.exec_cmd("hyprlock")
        hl.exec_cmd("uwsm app -- mako")
        -- fcitx5 is owned by the NixOS i18n.inputMethod XDG-autostart systemd
        -- unit (app-org.fcitx.Fcitx5@autostart.service). Launching it again
        -- here raced that unit via --replace and left the survivor with an
        -- empty IM group: apps connected over wayland_v2 but Ctrl+Space (and
        -- even dbus -o) toggled nothing. Let systemd own the single instance.
        hl.exec_cmd("[workspace 1 silent] uwsm app -- firefox")
        hl.exec_cmd("[workspace 1 silent] uwsm app -- obsidian")
      end'') ]; };

      # ----- keyword config (hl.config) -----------------------------------
      config = {
        general = {
          gaps_in = 1; gaps_out = 0; border_size = 1;
          col = { active_border = active; inactive_border = inactive; };
          resize_on_border = false; allow_tearing = false; layout = "dwindle";
        };
        decoration = {
          rounding = 0;
          shadow = { enabled = false; range = 4; render_power = 3; color = "rgba(00000055)"; };
          blur = {
            enabled = false; size = 6; passes = 1; ignore_opacity = true;
            new_optimizations = true; special = true; popups = true; vibrancy = 0.1696;
          };
        };
        cursor = { no_hardware_cursors = false; hide_on_key_press = true; };
        master = {
          mfact = 0.60; new_status = "slave"; new_on_top = false; allow_small_split = true;
          # master on the RIGHT, stack on the left — better on the narrow laptop
          # panel than center-master. (slave_count/fallback only apply if you
          # cycle back to center via SUPER+CTRL+i.)
          orientation = "right"; slave_count_for_center_master = 2; center_master_fallback = "left";
        };
        dwindle = {
          preserve_split = true;     # keep split orientation as windows come/go
          force_split = 2;           # always split to the right / below (predictable)
          smart_split = false;       # deterministic (not cursor-position based)
          default_split_ratio = 1.0; # even 50/50 splits
        };
        scrolling = {
          column_width = 0.5; fullscreen_on_one_column = true; follow_focus = true;
          wrap_focus = true; explicit_column_widths = "0.333, 0.5, 0.667, 1.0";
        };
        misc = { force_default_wallpaper = 0; enable_swallow = true; swallow_regex = "^(com.mitchellh.ghostty)$"; vrr = 1; };
        input = {
          kb_layout = "us"; follow_mouse = 1; sensitivity = 0;
          touchpad = { natural_scroll = true; disable_while_typing = true; };
        };
        group = {
          auto_group = false;
          groupbar = {
            enabled = true; font_size = 10; height = 18; rounding = 0;
            render_titles = true; scrolling = true;
            col = { active = active; inactive = inactive; locked_active = active; locked_inactive = inactive; };
          };
          col = { border_active = active; border_inactive = inactive; border_locked_active = active; border_locked_inactive = inactive; };
        };
        binds = { window_direction_monitor_fallback = false; allow_workspace_cycles = true; };
        animations = { enabled = false; };
      };

      # ----- gestures -----------------------------------------------------
      gesture = [
        { fingers = 3; direction = "left";  action = mkLuaInline ''function() hl.dispatch(hl.dsp.layout("move +col")) end''; }
        { fingers = 3; direction = "right"; action = mkLuaInline ''function() hl.dispatch(hl.dsp.layout("move -col")) end''; }
        # 4-finger vertical: pull the comms scratchpads up/down
        { fingers = 4; direction = "up";   action = mkLuaInline ''function() hl.dispatch(hl.dsp.workspace.toggle_special("chat")) end''; }
        { fingers = 4; direction = "down"; action = mkLuaInline ''function() hl.dispatch(hl.dsp.workspace.toggle_special("work")) end''; }
      ];

      # ----- keybinds (was bind / bindm / bindle / bindl) -----------------
      bind = [
        # mouse (bindm)
        (bo ''mod .. " + mouse:272"''       "hl.dsp.window.drag()"   { mouse = true; })
        (bo ''mod .. " + mouse:273"''       "hl.dsp.window.resize()" { mouse = true; })
        (bo ''mod .. " + ALT + mouse:272"'' "hl.dsp.window.resize()" { mouse = true; })

        # compositor
        (b ''mod .. " + CTRL + ALT + Q"''      "hl.dsp.exit()")
        (b ''mod .. " + Q"''                   "hl.dsp.window.close()")
        (b ''mod .. " + SHIFT + ESCAPE"''      ''hl.dsp.exec_cmd("systemctl suspend")'')
        (b ''mod .. " + SHIFT + CTRL + ESCAPE"'' ''hl.dsp.exec_cmd("systemctl poweroff")'')

        # tiling control
        (b ''mod .. " + SHIFT + F"''  ''hl.dsp.window.fullscreen({ action = "toggle" })'')
        (b ''mod .. " + G"''         "hl.dsp.group.toggle()")
        (b ''mod .. " + F"''         ''hl.dsp.window.float({ action = "toggle" })'')
        (b ''mod .. " + T"''         ''hl.dsp.layout("togglesplit")'')
        (b ''mod .. " + SHIFT + P"'' "hl.dsp.window.pseudo()")
        (b ''mod .. " + SHIFT + C"'' "hl.dsp.window.center()")
        (b ''mod .. " + P"''         ''hl.dsp.window.pin({ action = "toggle" })'')
        (b ''mod .. " + D"''         "hl.dsp.focus({ urgent_or_last = true })")

        # window cycling — universal incl. monocle (tiled=true is the monocle-safe form)
        (b ''mod .. " + TAB"''         "hl.dsp.window.cycle_next({ tiled = true })")
        (b ''mod .. " + SHIFT + TAB"'' "hl.dsp.window.cycle_next({ tiled = true, next = false })")
        (b ''mod .. " + CTRL + G"''    "hl.dsp.window.move({ out_of_group = true })")
        (b ''mod .. " + ALT + G"''     ''hl.dsp.exec_cmd("hyprctl dispatch lockgroups toggle")'')

        # utilities
        (b ''mod .. " + RETURN"''  "hl.dsp.exec_cmd(terminal)")
        (b ''mod .. " + y"''       "hl.dsp.exec_cmd(fileManager)")
        (b ''mod .. " + SPACE"''   "hl.dsp.exec_cmd(menu)")
        (b ''mod .. " + CTRL + Q"'' ''hl.dsp.exec_cmd("hyprlock")'')

        # walker providers
        (b ''mod .. " + CTRL + V"''      ''hl.dsp.exec_cmd("walker -m clipboard")'')
        (b ''mod .. " + W"''             ''hl.dsp.exec_cmd("walker -m windows")'')
        (b ''mod .. " + CTRL + period"'' ''hl.dsp.exec_cmd("walker -m symbols")'')
        (b ''mod .. " + CTRL + N"''      ''hl.dsp.exec_cmd("walker -m todo")'')

        # keybind cheatsheet
        (b ''mod .. " + slash"'' ''hl.dsp.exec_cmd("hypr-binds-menu")'')

        # notifications
        (b ''mod .. " + SHIFT + D"'' ''hl.dsp.exec_cmd("makoctl mode -t dnd; pkill -RTMIN+9 waybar")'')
        (b ''mod .. " + CTRL + D"''  ''hl.dsp.exec_cmd("mako-history-menu")'')

        # move focus
        (b ''mod .. " + h"'' ''hl.dsp.focus({ direction = "left" })'')
        (b ''mod .. " + l"'' ''hl.dsp.focus({ direction = "right" })'')
        (b ''mod .. " + k"'' ''hl.dsp.focus({ direction = "up" })'')
        (b ''mod .. " + j"'' ''hl.dsp.focus({ direction = "down" })'')

        # group tab cycling (moved off SUPER+TAB, now the window cycler)
        (bk "ALT + TAB"         "hl.dsp.group.next()")
        (bk "ALT + SHIFT + TAB" "hl.dsp.group.prev()")

        # move window or group
        (b ''mod .. " + SHIFT + h"'' ''hl.dsp.window.move({ direction = "l", group_aware = true })'')
        (b ''mod .. " + SHIFT + l"'' ''hl.dsp.window.move({ direction = "r", group_aware = true })'')
        (b ''mod .. " + SHIFT + k"'' ''hl.dsp.window.move({ direction = "u", group_aware = true })'')
        (b ''mod .. " + SHIFT + j"'' ''hl.dsp.window.move({ direction = "d", group_aware = true })'')

        # cycle workspaces
        (b ''mod .. " + bracketleft"''  ''hl.dsp.focus({ workspace = "m-1" })'')
        (b ''mod .. " + bracketright"'' ''hl.dsp.focus({ workspace = "m+1" })'')
        (b ''mod .. " + ESCAPE"''       ''hl.dsp.focus({ workspace = "previous" })'')

        # cycle monitors
        (b ''mod .. " + SHIFT + bracketleft"''  ''hl.dsp.focus({ monitor = "l" })'')
        (b ''mod .. " + SHIFT + bracketright"'' ''hl.dsp.focus({ monitor = "r" })'')

        # send workspace to monitor
        (b ''mod .. " + SHIFT + ALT + bracketleft"''  ''hl.dsp.workspace.move({ monitor = "l" })'')
        (b ''mod .. " + SHIFT + ALT + bracketright"'' ''hl.dsp.workspace.move({ monitor = "r" })'')

        # master: promote to master
        (b ''mod .. " + CTRL + RETURN"'' ''hl.dsp.layout("swapwithmaster master")'')

        # column resize (scrolling)
        (b ''mod .. " + equal"''               ''hl.dsp.layout("colresize +conf")'')
        (b ''mod .. " + minus"''               ''hl.dsp.layout("colresize -conf")'')
        (b ''mod .. " + SHIFT + SPACE"''        ''hl.dsp.layout("orientationnext")'')
        (b ''mod .. " + CTRL + SHIFT + SPACE"'' ''hl.dsp.layout("orientationprev")'')

        # scroll layout
        (b ''mod .. " + c"''         ''hl.dsp.layout("fit active")'')
        (b ''mod .. " + SHIFT + c"'' ''hl.dsp.layout("fit visible")'')
        (b ''mod .. " + CTRL + c"''  ''hl.dsp.layout("fit all")'')
        (b ''mod .. " + period"''    ''hl.dsp.layout("move +col")'')
        (b ''mod .. " + comma"''     ''hl.dsp.layout("move -col")'')

        # theme toggle
        (b ''mod .. " + F5"'' ''hl.dsp.exec_cmd("theme-switch")'')

        # screenshot
        (bk "SHIFT + Print" ''hl.dsp.exec_cmd("screenshot area")'')
        (bk "Print"         ''hl.dsp.exec_cmd("screenshot full")'')

        # screen recording
        (b ''mod .. " + Print"''         ''hl.dsp.exec_cmd("wf-recorder-toggle")'')
        (b ''mod .. " + SHIFT + Print"'' ''hl.dsp.exec_cmd("wf-recorder-toggle area")'')

        # special workspaces (chat-toggle retired -> plain toggle)
        (b ''mod .. " + M"''         ''hl.dsp.workspace.toggle_special("chat")'')
        (b ''mod .. " + SHIFT + M"'' ''hl.dsp.window.move({ workspace = "special:chat" })'')
        (b ''mod .. " + B"''         ''hl.dsp.workspace.toggle_special("work")'')
        (b ''mod .. " + SHIFT + B"'' ''hl.dsp.window.move({ workspace = "special:work" })'')

        # z-order for floating windows
        (b ''mod .. " + ALT + k"'' ''hl.dsp.window.alter_zorder({ mode = "top" })'')
        (b ''mod .. " + ALT + j"'' ''hl.dsp.window.alter_zorder({ mode = "bottom" })'')

        # submap entries
        (b ''mod .. " + R"''          ''hl.dsp.submap("resize")'')
        (b ''mod .. " + X"''          ''hl.dsp.submap("launch")'')
        (b ''mod .. " + V"''          ''hl.dsp.submap("place")'')
        (b ''mod .. " + N"''          ''hl.dsp.submap("mark")'')
        (b ''mod .. " + apostrophe"'' ''hl.dsp.submap("jump")'')

        # dynamic layout control --------------------------------------------
        # scrolling tape (ws1/3/5 + specials): swap columns / promote / recentre.
        # (consume/expel dropped — SUPER+SHIFT+h/l already moves windows between
        # columns. layoutmsg is layout-scoped, so these no-op off scrolling.)
        (b ''mod .. " + SHIFT + u"'' ''hl.dsp.layout("swapcol l")'')
        (b ''mod .. " + SHIFT + o"'' ''hl.dsp.layout("swapcol r")'')
        (b ''mod .. " + CTRL + u"''  ''hl.dsp.layout("promote")'')
        (b ''mod .. " + CTRL + o"''  ''hl.dsp.layout("center")'')
        # master stack (ws2 coding): add/remove a master window, cycle orientation
        (b ''mod .. " + i"''         ''hl.dsp.layout("addmaster")'')
        (b ''mod .. " + SHIFT + i"'' ''hl.dsp.layout("removemaster")'')
        (b ''mod .. " + CTRL + i"''  ''hl.dsp.layout("orientationcycle")'')

        # locked / repeating media + brightness (bindle / bindl)
        (bko "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")'' { locked = true; repeating = true; })
        (bko "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")''   { locked = true; repeating = true; })
        (bko "XF86AudioMute"        ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")''   { locked = true; repeating = true; })
        (bko "XF86AudioMicMute"     ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")'' { locked = true; repeating = true; })
        (bko "XF86MonBrightnessUp"   ''hl.dsp.exec_cmd("brightnessctl -c backlight s 10%+")'' { locked = true; repeating = true; })
        (bko "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("brightnessctl -c backlight s 10%-")'' { locked = true; repeating = true; })
        (bko "XF86AudioNext"  ''hl.dsp.exec_cmd("playerctl next")''       { locked = true; })
        (bko "XF86AudioPause" ''hl.dsp.exec_cmd("playerctl play-pause")'' { locked = true; })
        (bko "XF86AudioPlay"  ''hl.dsp.exec_cmd("playerctl play-pause")'' { locked = true; })
        (bko "XF86AudioPrev"  ''hl.dsp.exec_cmd("playerctl previous")''   { locked = true; })
      ] ++ wsBinds;

      # ----- window rules -------------------------------------------------
      window_rule = [
        # tags
        { match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$"; }; tag = "+browser"; }
        { match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$"; }; tag = "+browser"; }
        { match = { class = "^([Cc]hromium)$"; }; tag = "+browser"; }
        { match = { class = "^([Cc]hromium-browser)$"; }; tag = "+browser"; }
        { match = { class = "^(com.mitchellh.ghostty)$"; }; tag = "+terminal"; }
        { match = { class = "^([Tt]hunderbird)$"; }; tag = "+im-work"; }
        { match = { class = "^([Ss]lack)$"; }; tag = "+im-work"; }
        { match = { class = "^([Dd]iscord).*$"; }; tag = "+im"; }
        { match = { class = "^(org.telegram.desktop)$"; }; tag = "+im"; }
        { match = { class = "^([Ss]ignal)$"; }; tag = "+im"; }
        { match = { class = "^([Tt]hunar|org.gnome.Nautilus)$"; }; tag = "+file-manager"; }
        { match = { class = "^(firefox)$"; title = "^(Picture-in-Picture)$"; }; tag = "+pip"; }
        { match = { class = "^(org.keepassxc.KeePassXC)$"; }; tag = "+passwd"; }

        { match = { class = ".*"; }; suppress_event = "maximize"; }
        { match = { class = "^$"; title = "^$"; xwayland = true; float = true; fullscreen = false; pin = false; }; no_focus = true; }

        # opacity
        { match = { class = ".*"; }; opacity = "1.0 0.97"; }
        { match = { tag = "file-manager"; }; opacity = "0.97 0.8"; }

        { match = { tag = "im-work"; }; workspace = "special:work"; }
        { match = { tag = "im"; }; workspace = "special:chat"; }

        # notes = obsidian beside firefox on ws1
        { match = { tag = "browser"; }; workspace = "1"; }
        { match = { class = "^(obsidian)$"; }; workspace = "1"; }

        { match = { title = "^(Grayjay)$"; }; float = false; }
        { match = { title = "^(Grayjay)$"; }; workspace = "4"; }

        # picture-in-picture
        { match = { initial_title = "^Picture-in-Picture$"; }; opacity = "1 1"; }
        { match = { tag = "pip"; }; float = true; }
        { match = { tag = "pip"; }; pin = true; }
        { match = { tag = "pip"; }; no_focus = true; }
        { match = { tag = "pip"; }; size = "300 169"; }
        { match = { tag = "pip"; }; move = "100%-320 100%-190"; }
        { match = { tag = "pip"; }; keep_aspect_ratio = true; }

        # keepassxc
        { match = { tag = "passwd"; }; float = true; }
        { match = { tag = "passwd"; }; center = true; }
        { match = { tag = "passwd"; }; size = "60% 70%"; }

        { match = { tag = "terminal"; }; tile = true; }

        # scrolling layout column widths
        { match = { class = "^(obsidian)$"; }; scrolling_width = 0.333; }
        { match = { tag = "terminal"; }; scrolling_width = 0.5; }
        { match = { tag = "browser"; }; scrolling_width = 0.667; }
        { match = { tag = "im-work"; }; scrolling_width = 0.333; }
        { match = { tag = "im"; }; scrolling_width = 0.5; }

        # screen sharing
        { match = { tag = "im"; }; no_screen_share = true; }
        { match = { tag = "im-work"; }; no_screen_share = true; }
        { match = { tag = "passwd"; }; no_screen_share = true; }

        { match = { class = "([Tt]hunar)"; title = "negative:(.*[Tt]hunar.*)"; }; center = true; }

        # satty annotation editor
        { match = { class = "^(com.gabm.satty)$"; }; float = true; }
        { match = { class = "^(com.gabm.satty)$"; }; size = "80% 80%"; }
        { match = { class = "^(com.gabm.satty)$"; }; center = true; }

        # smart borders
        { match = { float = false; workspace = "w[tv1]"; }; border_size = 0; }
        { match = { float = false; workspace = "w[tv1]"; }; rounding = 0; }
        { match = { float = false; workspace = "f[1]"; }; border_size = 0; }
        { match = { float = false; workspace = "f[1]"; }; rounding = 0; }
      ] ++ dialogRules;

      # ----- workspace rules ----------------------------------------------
      workspace_rule = [
        # per-workspace layouts
        { workspace = "1"; layout = "scrolling"; }
        { workspace = "2"; layout = "master"; }
        { workspace = "3"; layout = "scrolling"; }
        { workspace = "4"; layout = "monocle"; }
        { workspace = "5"; layout = "scrolling"; }
        { workspace = "special:work"; layout = "scrolling"; }
        { workspace = "special:chat"; layout = "scrolling"; }

        { workspace = "special:work"; gaps_out = 40; gaps_in = 10; }
        { workspace = "special:chat"; gaps_out = 40; gaps_in = 10; }

        # smart gaps
        { workspace = "w[tv1]"; gaps_out = 0; gaps_in = 0; }
        { workspace = "f[1]"; gaps_out = 0; gaps_in = 0; }

        # per-workspace monitor pins (framework13)
        { workspace = "1"; monitor = "DP-4"; default = true; }
        { workspace = "2"; monitor = "DP-4"; }
        { workspace = "3"; monitor = "DP-4"; }
        { workspace = "4"; monitor = "eDP-1"; default = true; }
        { workspace = "5"; monitor = "eDP-1"; }
      ];
    };

    # ----- submaps --------------------------------------------------------
    submaps = {
      # resize: sticky, repeatable; exit with escape/return
      resize.settings.bind = [
        (bko "h" "hl.dsp.window.resize({ x = -100, y = 0, relative = true })" { repeating = true; })
        (bko "l" "hl.dsp.window.resize({ x = 100, y = 0, relative = true })"  { repeating = true; })
        (bko "k" "hl.dsp.window.resize({ x = 0, y = -100, relative = true })" { repeating = true; })
        (bko "j" "hl.dsp.window.resize({ x = 0, y = 100, relative = true })"  { repeating = true; })
        (bk "escape" ''hl.dsp.submap("reset")'')
        (bk "RETURN" ''hl.dsp.submap("reset")'')
      ];

      # launch: auto-resets to global after each action
      launch = {
        onDispatch = "reset";
        settings.bind = [
          (bk "A" ''hl.dsp.exec_cmd(webapp .. " https://openrouter.ai/chat")'')
          (bk "B" "hl.dsp.exec_cmd(browser)")
          (bk "W" "hl.dsp.exec_cmd(workBrowser)")
          (bk "H" "hl.dsp.exec_cmd(hardBrowser)")
          (bk "C" ''hl.dsp.exec_cmd(webapp .. " https://app.hey.com/calendar/weeks/")'')
          (bk "D" ''hl.dsp.exec_cmd(terminal .. " -e lazydocker")'')
          (bk "E" ''hl.dsp.exec_cmd(webapp .. " https://app.hey.com")'')
          (bk "O" ''hl.dsp.exec_cmd("uwsm app -- obsidian")'')
          (bk "R" ''hl.dsp.exec_cmd(terminal .. " -e newsboat")'')
          (bk "slash" ''hl.dsp.exec_cmd("uwsm app -- keepassxc")'')
          (bk "escape" ''hl.dsp.submap("reset")'')
        ];
      };

      # place: snap floating windows to zones; stays active for multiple placements
      place.settings.bind = [
        # halves
        (bk "h" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 100% ; dispatch movewindowpixel exact 0 0"))
        (bk "l" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 100% ; dispatch movewindowpixel exact 50% 0"))
        (bk "k" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 100% 50% ; dispatch movewindowpixel exact 0 0"))
        (bk "j" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 100% 50% ; dispatch movewindowpixel exact 0 50%"))
        # center variants
        (bk "c" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 70% 70% ; dispatch centerwindow"))
        (bk "f" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 95% 95% ; dispatch centerwindow"))
        (bk "m" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 50% ; dispatch centerwindow"))
        # quadrants
        (bk "1" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 50% ; dispatch movewindowpixel exact 0 0"))
        (bk "2" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 50% ; dispatch movewindowpixel exact 50% 0"))
        (bk "3" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 50% ; dispatch movewindowpixel exact 0 50%"))
        (bk "4" (placeBatch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 50% ; dispatch movewindowpixel exact 50% 50%"))
        # incremental move (repeatable)
        (bko "SHIFT + h" "hl.dsp.window.move({ x = -40, y = 0, relative = true })" { repeating = true; })
        (bko "SHIFT + l" "hl.dsp.window.move({ x = 40, y = 0, relative = true })"  { repeating = true; })
        (bko "SHIFT + k" "hl.dsp.window.move({ x = 0, y = -40, relative = true })" { repeating = true; })
        (bko "SHIFT + j" "hl.dsp.window.move({ x = 0, y = 40, relative = true })"  { repeating = true; })
        # incremental resize (repeatable)
        (bko "equal" "hl.dsp.window.resize({ x = 40, y = 40, relative = true })"   { repeating = true; })
        (bko "minus" "hl.dsp.window.resize({ x = -40, y = -40, relative = true })" { repeating = true; })
        (bk "escape" ''hl.dsp.submap("reset")'')
        (bk "RETURN" ''hl.dsp.submap("reset")'')
      ];

      # vim marks: set / jump, auto-reset after each letter
      mark = { onDispatch = "reset"; settings.bind = markSubmapBinds "set"; };
      jump = { onDispatch = "reset"; settings.bind = markSubmapBinds "jump"; };
    };
  };
}
