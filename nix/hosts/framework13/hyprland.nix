{
  programs.hyprland.settings = let
    # TODO
    accelpoints = "";
  in {
    monitor = [
      "eDP-1, preferred, auto, 1.5"
    ];

    "device[pixa3854:00-093a:0274-touchpad]" = {
      natural_scroll = true;
    };
  };
}
