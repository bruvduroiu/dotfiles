{
  programs.hyprland.settings = {
    windowrule = [
      "suppressevent maximize, class:.*"
      "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

      "opacity 0.97 0.9, class:*"
      "opacity 1 0.97, class:^(firefox)$"

      "opacity 1 1, initialTitle:^Picture-in-Picture$"
      "float, class:^(firefox)$, title:^(Picture-in-Picture)$"
      "pin, class:^(firefox)$, title:^(Picture-in-Picture)$"
      "nofocus, class:^(firefox)$, title:^(Picture-in-Picture)$"
      "size 300 169, class:^(firefox)$, title:^(Picture-in-Picture)$"
      "move 100%-320 100%-190, class:(firefox), title:(Picture-in-Picture)"
      "keepaspectratio, class:(firefox), title:(Picture-in-Picture)"

    ];
  };
}
