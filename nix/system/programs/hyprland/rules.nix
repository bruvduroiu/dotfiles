{
  programs.hyprland.settings = {
    windowrule = [
      "suppressevent maximize, class:.*"
      "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

      "opacity 0.97 0.9, class:*"
      "opacity 1 0.97, class:^(firefox)$"
      "opacity 1 1, initialTitle:^(youtube.com_/)$"
      "opacity 1 1, class:^(obsidian)$"
    ];
  };
}
