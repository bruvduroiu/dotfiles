{
  programs.hyprland.settings = let
    # TODO
    accelpoints = "0.000 0.391 1.375 3.422 7.000 12.578 20.625 31.609 46.000 64.266 86.875 114.297 146.000 185.453 230.125 281.484 340.000 406.141 480.375 563.172";
  in {
    monitor = [
      "DP-4, 3840x2160@60.00, 0x0, 1"
      "eDP-1, preferred, 3840x0, 1.5"
    ];

    "device[pixa3854:00-093a:0274-touchpad]" = {
      accel_profile = "custom ${accelpoints}";
      scroll_points = accelpoints;
      natural_scroll = true;
    };
  };
}
