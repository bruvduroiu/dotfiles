{
  imports = [
    # editors
    ../../editors/nvim

    # programs
    ../../programs
    ../../programs/keepassxc.nix
    ../../programs/wayland
    ../../programs/yt-dlp.nix

    # terminal emulators
    ../../terminal/emulators/ghostty.nix

    ../../services/system/syncthing.nix
    ../../services/wayland/hyprpaper.nix
    ../../services/mako.nix
    ../../services/podman.nix
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
