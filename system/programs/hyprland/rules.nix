{
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
      "tag +im, match:class ^([Dd]iscord)$"
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

      "workspace 1, match:tag browser"
      "workspace 1, match:class ^(obsidian)$"
      "workspace 4, match:tag im"

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

      # Screen Sharing
      "no_screen_share on, match:tag im"
      "no_screen_share on, match:tag im-work"
      "no_screen_share on, match:tag passwd"

      # Dialog windows - float+center
      "center on, match:title ^(Open File)(.*)$"
      "center on, match:title ^(Select a File)(.*)$"
      "center on, match:title ^(Choose wallpaper)(.*)$"
      "center on, match:title ^(Open Folder)(.*)$"
      "center on, match:title ^(Save As)(.*)$"
      "center on, match:title ^(Library)(.*)$"
      "center on, match:title ^(File Upload)(.*)$"
      "float on, match:title ^(Open File)(.*)$"
      "float on, match:title ^(Select a File)(.*)$"
      "float on, match:title ^(Choose wallpaper)(.*)$"
      "float on, match:title ^(Open Folder)(.*)$"
      "float on, match:title ^(Save As)(.*)$"
      "float on, match:title ^(Library)(.*)$"
      "float on, match:title ^(File Upload)(.*)$"

      "center on, match:class ([Tt]hunar), match:title negative:(.*[Tt]hunar.*)"

      "workspace special:term, match:class ^(scratchterm)$"
      "float on, match:class ^(scratchterm)$"
      "size 80% 80%, match:class ^(scratchterm)$"
      "center on, match:class ^(scratchterm)$"

      # Smart borders: no border/rounding when only one tiled window
      "border_size 0, match:float 0, match:workspace w[tv1]"
      "rounding 0, match:float 0, match:workspace w[tv1]"
      "border_size 0, match:float 0, match:workspace f[1]"
      "rounding 0, match:float 0, match:workspace f[1]"
    ];

    workspace = [
      # Per-workspace layouts (0.54 native support)
      # layout:<name> sets the engine; layoutopt:<key>:<value> passes options to it
      "1, layout:scrolling"
      "2, layout:dwindle"
      "3, layout:dwindle"
      "4, layout:scrolling"
      "5, layout:scrolling"
      "special:work, layout:scrolling"

      "special:notes, gapsout:40, gapsin:20"
      "special:work, gapsout:40, gapsin:10"

      # Smart gaps: no gaps when only one tiled/fullscreen window
      "w[tv1], gapsout:0, gapsin:0"
      "f[1], gapsout:0, gapsin:0"
    ];
  };
}
