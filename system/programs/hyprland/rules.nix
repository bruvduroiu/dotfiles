{
  programs.hyprland.settings = {
    windowrule = [
      "suppressevent maximize, class:.*"
      "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

      "opacity 0.97 0.9, class:*"
      "opacity 1 0.97, class:^(firefox)$"

      "workspace 1,class:firefox,title:Mozilla Firefox"
      "workspace 4,class:Slack"
      "workspace 4,class:thunderbird"
      "workspace 5,class:org.telegram.desktop"
      "workspace 5,class:discord"

      "opacity 1 1, initialTitle:^Picture-in-Picture$"
      "float, class:^(firefox)$, title:^(Picture-in-Picture)$"
      "pin, class:^(firefox)$, title:^(Picture-in-Picture)$"
      "nofocus, class:^(firefox)$, title:^(Picture-in-Picture)$"
      "size 300 169, class:^(firefox)$, title:^(Picture-in-Picture)$"
      "move 100%-320 100%-190, class:(firefox), title:(Picture-in-Picture)"
      "keepaspectratio, class:(firefox), title:(Picture-in-Picture)"

      # Slack
      "float, class:^(Slack)$, title:^(.*)(DM)(.*)$"
      "center, class:^(Slack)$, title:^(.*)(DM)(.*)$"

      "tile, class:^com.mitchellh.ghostty$"

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
    ];
  };
}
