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
    ]
  )
  10);

  runOnce = program: "pgrep ${program} || uwsm app -- ${program}";
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
      "$mod CTRL, ESCAPE, exec, "
      "$mod SHIFT CTRL, ESCAPE, exec, systemctl poweroff"

      # control tiling
      "$mod SHIFT, F, fullscreen,"
      "$mod, G, togglegroup,"
      "$mod, F, togglefloating,"
      "$mod ALT, , resizeactive"
      "$mod SHIFT, J, togglesplit, " # dwindle
      "$mod SHIFT, P, pseudo, " # dwindle
      "$mod SHIFT, C, centerwindow" # center

      # utilities
      "$mod, RETURN, exec, $terminal"
      "$mod, y, exec, $fileManager"
      "$mod, SPACE, exec, $menu"
      "$mod Control, Q, exec, hyprlock"

      # move focus
      "$mod, h, movefocus, l"
      "$mod, l, movefocus, r"
      "$mod, k, movefocus, u"
      "$mod, j, movefocus, d"

      # swap active window with the one next to it
      "$mod SHIFT, h, swapwindow, l"
      "$mod SHIFT, l, swapwindow, r"
      "$mod SHIFT, k, swapwindow, u"
      "$mod SHIFT, j, swapwindow, d"

      # cycle workspaces
      "$mod, bracketleft, workspace, m-1"
      "$mod, bracketright, workspace, m+1"

      # cycle monitors
      "$mod SHIFT, bracketleft, focusmonitor, l"
      "$mod SHIFT, bracketright, focusmonitor, r"

      # send focused workspace to left/right monitor
      "$mod SHIFT ALT, bracketleft, movecurrentworkspacetomonitor, l"
      "$mod SHIFT ALT, bracketright, movecurrentworkspacetomonitor, r"

      # Cycle master orientation
      "$mod SHIFT, SPACE, layoutmsg, orientationnext"
      "$mod CTRL SHIFT, SPACE, layoutmsg, orientationprev"

      # theme toggle
      "$mod, F5, exec, theme-switch"

      # screenshot
      # area
      "SHIFT, Print, exec, ${runOnce "grimblast"} --notify copysave area"
      # screen
      ", Print, exec, ${runOnce "grimblast"} --notify copysave screen"

      # screen recording (toggle)
      "$mod, Print, exec, wf-recorder-toggle"
      "$mod SHIFT, Print, exec, wf-recorder-toggle area"

      # special workspace
      "$mod, grave, togglespecialworkspace, term"
      "$mod SHIFT, grave, movetoworkspace, special:term"
      
      "$mod, N, togglespecialworkspace, notes"  # Quick notes/obsidian
      "$mod SHIFT, N, movetoworkspace, special:notes"

      "$mod, M, togglespecialworkspace, chat"
      "$mod SHIFT, M, movetoworkspace, special:chat"

      "$mod, B, togglespecialworkspace, work"
      "$mod SHIFT, B, movetoworkspace, special:work"
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
    bind=,C,exec,$webapp https://app.hey.com/calendar/weeks/"
    bind=,D,exec,$terminal -e lazydocker
    bind=,E,exec,$webapp https://app.hey.com
    bind=,O,exec, uwsm app -- obsidian -disable-gpu
    bind=,slash,exec, uwsm app -- keepassxc

    bind=,escape,submap,reset

    # Note, that after launching app submap immediately exits.
    bind=,A,submap,reset
    bind=,B,submap,reset
    bind=,C,submap,reset
    bind=,D,submap,reset
    bind=,E,submap,reset
    bind=,O,submap,reset
    bind=,slash,submap,reset

    # will reset the submap, meaning end the current one and return to the global one
    submap=reset
  '';
}
