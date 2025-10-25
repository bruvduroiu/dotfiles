{
  programs.hyprland.settings = {
    windowrule = [
      # Tags
      "tag +browser, class:^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$"
      "tag +browser, class:^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$"
      "tag +browser, class:^([Cc]hromium)$"
      "tag +terminal, class:^(com.mitchellh.ghostty)$"
      "tag +email, class:^([Tt]hunderbird)$"
      "tag +im-work, class:^([Ss]lack)$"
      "tag +im, class:^([Dd]iscord)$"
      "tag +im, class:^([Ww]hatsapp-for-linux)$"
      "tag +im, class:^(org.telegram.desktop)$"
      "tag +file-manager, class:^([Tt]hunar|org.gnome.Nautilus)$"
      "tag +pip, class:^(firefox)$, title:^(Picture-in-Picture)$"
      "tag +passwd, class:^(org.keepassxc.KeePassXC)$"

      "suppressevent maximize, class:.*"
      "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

      # Opacity
      "opacity 1.0 0.97, tag:*"
      "opacity 0.97 0.8, tag:file-manager"
      "opacity 0.95 0.9, tag:terminal"

      "workspace special:chat, tag:im"
      "workspace special:work, tag:im-work"
      "workspace special:work, tag:email"
      "workspace special:notes, class:^(obsidian)$"

      "workspace 1,tag:browser"

      "opacity 1 1, initialTitle:^Picture-in-Picture$"
      "float, tag:pip"
      "pin, tag:pip"
      "nofocus, tag:pip"
      "size 300 169, tag:pip"
      "move 100%-320 100%-190, tag:pip"
      "keepaspectratio, tag:pip"

      "float, tag:passwd"
      "center, tag:passwd"
      "size 60% 70%, tag:passwd"

      "tile, tag:terminal"

      # Screen Sharing
      "noscreenshare, tag:im"
      "noscreenshare, tag:email"
      "noscreenshare, tag:passwd"

      # Dialog windows - float+center
      "center, title:^(Open File)(.*)$"
      "center, title:^(Select a File)(.*)$"
      "center, title:^(Choose wallpaper)(.*)$"
      "center, title:^(Open Folder)(.*)$"
      "center, title:^(Save As)(.*)$"
      "center, title:^(Library)(.*)$"
      "center, title:^(File Upload)(.*)$"
      "float, title:^(Open File)(.*)$"
      "float, title:^(Select a File)(.*)$"
      "float, title:^(Choose wallpaper)(.*)$"
      "float, title:^(Open Folder)(.*)$"
      "float, title:^(Save As)(.*)$"
      "float, title:^(Library)(.*)$"
      "float, title:^(File Upload)(.*)$"

      "center, class:([Tt]hunar), title:negative:(.*[Tt]hunar.*)"

      "workspace special:term, class:^(scratchterm)$"
      "float, class:^(scratchterm)$"
      "size 80% 80%, class:^(scratchterm)$"
      "center, class:^(scratchterm)$"
    ];

    workspace = [
      "1, layoutopt:orientation:left"
      "1, gapsout:40, gapsin:5, layoutopt:orientation:center"
      "special:notes, layoutopt:orientation:center"
      "special:notes, gapsout:40, gapsin:20, layoutopt:orientation:center"
      "special:chat, gapsout:40, gapsin:10, layoutopt:orientation:center"
    ];
  };
}
