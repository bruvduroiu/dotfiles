{
  programs.hyprland.settings = let
    # TODO
    accelpoints = "";
  in {
    monitor = [
      "eDP-1, preferred, 3840x0, 1.5"
      "DP-3, 3840x2160@60.00, 0x0, 1"
    ];

    "device[pixa3854:00-093a:0274-touchpad]" = {
      natural_scroll = true;
    };
  };
}
