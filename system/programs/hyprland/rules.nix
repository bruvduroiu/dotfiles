let
  # Dialog windows: float + center each of these title patterns
  dialogTitles = [
    "Open File"
    "Select a File"
    "Choose wallpaper"
    "Open Folder"
    "Save As"
    "Library"
    "File Upload"
  ];
  dialogRules = builtins.concatMap (t: [
    "float on, match:title ^(${t})(.*)$"
    "center on, match:title ^(${t})(.*)$"
  ]) dialogTitles;
in {
  programs.hyprland.settings = {
    windowrule = [
      # Tags
      "tag +browser, match:class ^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$"
      "tag +browser, match:class ^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$"
      "tag +browser, match:class ^([Cc]hromium)$"
      "tag +browser, match:class ^([Cc]hromium-browser)$"
      "tag +terminal, match:class ^(com.mitchellh.ghostty)$"
      "tag +im-work, match:class ^([Tt]hunderbird)$"
      "tag +im-work, match:class ^([Ss]lack)$"
      "tag +im, match:class ^([Dd]iscord).*$"
      "tag +im, match:class ^(org.telegram.desktop)$"
      "tag +im, match:class ^([Ss]ignal)$"
      "tag +file-manager, match:class ^([Tt]hunar|org.gnome.Nautilus)$"
      "tag +pip, match:class ^(firefox)$, match:title ^(Picture-in-Picture)$"
      "tag +passwd, match:class ^(org.keepassxc.KeePassXC)$"

      "suppress_event maximize, match:class .*"
      "no_focus on, match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false"

      # Opacity
      "opacity 1.0 0.97, match:tag *"
      "opacity 0.97 0.8, match:tag file-manager"

      "workspace special:work, match:tag im-work"
      "workspace special:chat, match:tag im"

      # notes = obsidian beside firefox on ws1 (0.333 + 0.667 scrolling columns)
      "workspace 1, match:tag browser"
      "workspace 1, match:class ^(obsidian)$"

      "float off, match:title ^(Grayjay)$"
      "workspace 4, match:title ^(Grayjay)$"

      "opacity 1 1, match:initial_title ^Picture-in-Picture$"
      "float on, match:tag pip"
      "pin on, match:tag pip"
      "no_focus on, match:tag pip"
      "size 300 169, match:tag pip"
      "move 100%-320 100%-190, match:tag pip"
      "keep_aspect_ratio on, match:tag pip"

      "float on, match:tag passwd"
      "center on, match:tag passwd"
      "size 60% 70%, match:tag passwd"

      "tile on, match:tag terminal"

      # Scrolling layout column widths
      "scrolling_width 0.333, match:class ^(obsidian)$"
      "scrolling_width 0.5, match:tag terminal"
      "scrolling_width 0.667, match:tag browser"
      "scrolling_width 0.333, match:tag im-work"
      "scrolling_width 0.5, match:tag im"

      # Screen Sharing
      "no_screen_share on, match:tag im"
      "no_screen_share on, match:tag im-work"
      "no_screen_share on, match:tag passwd"

      "center on, match:class ([Tt]hunar), match:title negative:(.*[Tt]hunar.*)"

      # satty annotation editor: comfortable floating window
      "float on, match:class ^(com.gabm.satty)$"
      "size 80% 80%, match:class ^(com.gabm.satty)$"
      "center on, match:class ^(com.gabm.satty)$"

      # Smart borders: no border/rounding when only one tiled window
      "border_size 0, match:float 0, match:workspace w[tv1]"
      "rounding 0, match:float 0, match:workspace w[tv1]"
      "border_size 0, match:float 0, match:workspace f[1]"
      "rounding 0, match:float 0, match:workspace f[1]"
    ] ++ dialogRules;

    workspace = [
      # Per-workspace layouts (0.54 native support)
      # layout:<name> sets the engine; layoutopt:<key>:<value> passes options to it
      "1, layout:scrolling"
      "2, layout:master" # center-master config in settings.nix; orientation binds live here
      "3, layout:dwindle"
      "4, layout:scrolling"
      "5, layout:scrolling"
      "special:work, layout:scrolling"
      "special:chat, layout:scrolling"

      "special:work, gapsout:40, gapsin:10"
      "special:chat, gapsout:40, gapsin:10"

      # Smart gaps: no gaps when only one tiled/fullscreen window
      "w[tv1], gapsout:0, gapsin:0"
      "f[1], gapsout:0, gapsin:0"
    ];
  };
}
