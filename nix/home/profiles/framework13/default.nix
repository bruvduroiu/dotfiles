{
  imports = [
    # editors
    ../../editors/nvim

    # programs
    ../../programs
    # ../../programs/wayland

    # terminal emulators
    ../../terminal/emulators/ghostty.nix
  ];

  wayland.windowManager.hyprland.settings = {
    monitor = [
      ", preferred, auto, 1.60000"
    ];

    device = {
      name = "pixa3854:00-093a:0274-touchpad";
      natural_scroll = true;
    };
  };
}
