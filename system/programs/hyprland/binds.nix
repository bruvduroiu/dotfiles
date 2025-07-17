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
      "$mod, RETURN, exec, uwsm app -- $terminal"
      "$mod, y, exec, uwsm app -- $fileManager"
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

      # resize active window
      "$mod, minus, resizeactive, -100 0"
      "$mod, equal, resizeactive, 100 0"
      "$mod SHIFT, minus, resizeactive, 0 -100"
      "$mod SHIFT, equal, resizeactive, 0 100"

      # cycle workspaces
      "$mod, bracketleft, workspace, m-1"
      "$mod, bracketright, workspace, m+1"

      # cycle monitors
      "$mod SHIFT, bracketleft, focusmonitor, l"
      "$mod SHIFT, bracketright, focusmonitor, r"

      # send focused workspace to left/right monitor
      "$mod SHIFT ALT, bracketleft, movecurrentworkspacetomonitor, l"
      "$mod SHIFT ALT, bracketright, movecurrentworkspacetomonitor, r"

      # screenshot
      # area
      "SHIFT, Print, exec, ${runOnce "grimblast"} --notify copysave area"
      # screen
      ", Print, exec, ${runOnce "grimblast"} --notify copysave screen"
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
}
