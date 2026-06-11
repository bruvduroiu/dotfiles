{ lib, ... }:

let
  workspaces = builtins.concatLists (builtins.genList (
    x: let
      ws = let
        c = (x + 1) / 10;
      in 
        builtins.toString (x + 1 - (c * 10));
    in [
      "$mod, ${ws}, workspace, ${toString (x + 1)}"
      "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
      "$mod CTRL, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
    ]
  )
  10);

  # vim-style window marks: one bind pair per letter inside the submaps
  markLetters = lib.stringToCharacters "abcdefghijklmnopqrstuvwxyz";
  markBinds = action:
    lib.concatMapStrings (l: ''
      bind=,${l},exec,hypr-mark ${action} ${l}
      bind=,${l},submap,reset
    '') markLetters;
in {
  programs.hyprland.settings = {
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
      "$mod ALT, mouse:272, resizewindow"
    ];

    # binds
    bind = [
      # compositor commands
      "$mod Control ALT, Q, exit,"
      "$mod, Q, killactive,"
      "$mod SHIFT, ESCAPE, exec, systemctl suspend"
      "$mod SHIFT CTRL, ESCAPE, exec, systemctl poweroff"

      # control tiling
      "$mod SHIFT, F, fullscreen,"
      "$mod, G, togglegroup,"
      "$mod, F, togglefloating,"
      "$mod, T, layoutmsg, togglesplit" # dwindle
      "$mod SHIFT, P, pseudo, " # dwindle
      "$mod SHIFT, C, centerwindow"
      "$mod, P, pin,"
      "$mod, D, focusurgentorlast,"

      # group navigation
      "$mod, TAB, changegroupactive, f"
      "$mod SHIFT, TAB, changegroupactive, b"

      # move window out of group
      "$mod CTRL, G, moveoutofgroup,"

      # lock groups (prevent accidental add/remove)
      "$mod ALT, G, lockgroups, toggle"

      # utilities
      "$mod, RETURN, exec, $terminal"
      "$mod, y, exec, $fileManager"
      "$mod, SPACE, exec, $menu"
      "$mod Control, Q, exec, hyprlock"

      # walker providers
      "$mod CTRL, V, exec, walker -m clipboard"
      "$mod, W, exec, walker -m windows"
      "$mod CTRL, period, exec, walker -m symbols"
      "$mod CTRL, N, exec, walker -m todo"

      # keybind cheatsheet (live from hyprctl, never stale)
      "$mod, slash, exec, hypr-binds-menu"

      # notifications: do-not-disturb toggle + history control centre
      "$mod SHIFT, D, exec, makoctl mode -t dnd; pkill -RTMIN+9 waybar"
      "$mod CTRL, D, exec, mako-history-menu"

      # move focus (h/l directional, j/k sequential — works in monocle)
      "$mod, h, movefocus, l"
      "$mod, l, movefocus, r"
      "$mod, k, movefocus, u"
      "$mod, j, movefocus, d"

      # cycle windows in any layout ($mod TAB is reserved for group navigation)
      "ALT, TAB, cyclenext,"
      "ALT SHIFT, TAB, cyclenext, prev"

      # move window or group (swap tiled, merge/unmerge groups)
      "$mod SHIFT, h, movewindoworgroup, l"
      "$mod SHIFT, l, movewindoworgroup, r"
      "$mod SHIFT, k, movewindoworgroup, u"
      "$mod SHIFT, j, movewindoworgroup, d"

      # cycle workspaces
      "$mod, bracketleft, workspace, m-1"
      "$mod, bracketright, workspace, m+1"
      "$mod, ESCAPE, workspace, previous"

      # cycle monitors
      "$mod SHIFT, bracketleft, focusmonitor, l"
      "$mod SHIFT, bracketright, focusmonitor, r"

      # send focused workspace to left/right monitor
      "$mod SHIFT ALT, bracketleft, movecurrentworkspacetomonitor, l"
      "$mod SHIFT ALT, bracketright, movecurrentworkspacetomonitor, r"

      # Master layout
      "$mod CTRL, Return, layoutmsg, swapwithmaster master"  # promote to master

      # Column resize (cycles through explicit_column_widths)
      "$mod, equal, layoutmsg, colresize +conf"
      "$mod, minus, layoutmsg, colresize -conf"
      "$mod SHIFT, SPACE, layoutmsg, orientationnext"
      "$mod CTRL SHIFT, SPACE, layoutmsg, orientationprev"

      # Scroll layout
      "$mod, c, layoutmsg, fit active"
      "$mod SHIFT, c, layoutmsg, fit visible"
      "$mod CTRL, c, layoutmsg, fit all"
      "$mod, period, layoutmsg, move +col"
      "$mod, comma, layoutmsg, move -col"

      # theme toggle
      "$mod, F5, exec, theme-switch"

      # screenshot (grim+satty; copy in the editor also saves)
      # area, with annotation editor
      "SHIFT, Print, exec, screenshot area"
      # full screen straight to clipboard + file
      ", Print, exec, screenshot full"

      # screen recording (toggle)
      "$mod, Print, exec, wf-recorder-toggle"
      "$mod SHIFT, Print, exec, wf-recorder-toggle area"

      # special workspaces

      # chat centre: spawns telegram+signal on first use ($mod N freed —
      # notes/obsidian live on workspace 1 now)
      "$mod, M, exec, chat-toggle"
      "$mod SHIFT, M, movetoworkspace, special:chat"

      "$mod, B, togglespecialworkspace, work"
      "$mod SHIFT, B, movetoworkspace, special:work"

      # z-order management for floating windows
      "$mod ALT, k, alterzorder, top"
      "$mod ALT, j, alterzorder, bottom"
    ]
    ++ workspaces;

    bindle = [
      ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ",XF86MonBrightnessUp, exec, brightnessctl -c backlight s \"10%+\""
      ",XF86MonBrightnessDown, exec, brightnessctl -c backlight s \"10%-\""
    ];

    bindl = [
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
    ];
  };

  programs.hyprland.extraConfig = ''
    bind=$mod,R,submap,resize

    # will start a submap called "resize"
    submap=resize

    # sets repeatable binds for resizing the active window
    binde=,h,resizeactive,-100 0
    binde=,l,resizeactive,100 0
    binde=,k,resizeactive,0 -100
    binde=,j,resizeactive,0 100

    # use reset to go back to the global submap
    bind=,escape,submap,reset
    bind=,RETURN,submap,reset

    # will reset the submap, meaning end the current one and return to the global one
    submap=reset

    bind=$mod,X,submap,launch

    submap=launch

    bind=,A,exec,$webapp https://openrouter.ai/chat
    bind=,B,exec,$browser
    bind=,C,exec,$webapp https://app.hey.com/calendar/weeks/
    bind=,D,exec,$terminal -e lazydocker
    bind=,E,exec,$webapp https://app.hey.com
    bind=,O,exec, uwsm app -- obsidian -disable-gpu
    bind=,R,exec,$terminal -e newsboat
    bind=,slash,exec, uwsm app -- keepassxc

    bind=,escape,submap,reset

    # Note, that after launching app submap immediately exits.
    bind=,A,submap,reset
    bind=,B,submap,reset
    bind=,C,submap,reset
    bind=,D,submap,reset
    bind=,E,submap,reset
    bind=,O,submap,reset
    bind=,R,submap,reset
    bind=,slash,submap,reset

    # will reset the submap, meaning end the current one and return to the global one
    submap=reset

    bind=$mod,V,submap,place

    # snap floating windows to screen zones
    submap=place

    # halves
    bind=,h,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 100% ; dispatch movewindowpixel exact 0 0"
    bind=,l,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 100% ; dispatch movewindowpixel exact 50% 0"
    bind=,k,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 100% 50% ; dispatch movewindowpixel exact 0 0"
    bind=,j,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 100% 50% ; dispatch movewindowpixel exact 0 50%"

    # center variants
    bind=,c,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 70% 70% ; dispatch centerwindow"
    bind=,f,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 95% 95% ; dispatch centerwindow"
    bind=,m,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 50% ; dispatch centerwindow"

    # quadrants
    bind=,1,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 50% ; dispatch movewindowpixel exact 0 0"
    bind=,2,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 50% ; dispatch movewindowpixel exact 50% 0"
    bind=,3,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 50% ; dispatch movewindowpixel exact 0 50%"
    bind=,4,exec,hyprctl --batch "dispatch setfloating ; dispatch resizewindowpixel exact 50% 50% ; dispatch movewindowpixel exact 50% 50%"

    # incremental move (repeatable)
    binde=SHIFT,h,moveactive,-40 0
    binde=SHIFT,l,moveactive,40 0
    binde=SHIFT,k,moveactive,0 -40
    binde=SHIFT,j,moveactive,0 40

    # incremental resize (repeatable)
    binde=,equal,resizeactive,40 40
    binde=,minus,resizeactive,-40 -40

    bind=,escape,submap,reset
    bind=,RETURN,submap,reset

    submap=reset

    # vim-style window marks: $mod N <letter> sets, $mod ' <letter> jumps
    bind=$mod,N,submap,mark
    submap=mark
    ${markBinds "set"}
    bind=,escape,submap,reset
    submap=reset

    bind=$mod,apostrophe,submap,jump
    submap=jump
    ${markBinds "jump"}
    bind=,escape,submap,reset
    submap=reset
  '';
}
