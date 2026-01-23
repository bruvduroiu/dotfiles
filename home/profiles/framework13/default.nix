{
  imports = [
    # editors
    ../../editors/nvim

    # programs
    ../../programs
    ../../programs/keepassxc.nix
    ../../programs/wayland
    ../../programs/gtk.nix
    ../../programs/yt-dlp.nix
    ../../programs/gpg.nix

    # terminal emulators
    ../../terminal/emulators/ghostty.nix

    ../../services/wayland/hyprpaper.nix
    ../../services/mako.nix
    ../../services/podman.nix
    ../../services/gpg.nix
    ../../services/syncthing.nix
    ../../services/trayscale.nix
    ../../services/media/playerctl.nix
  ];

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-4, 3840x2160@60.00, 0x0, 1"
      "eDP-1, preferred, 3840x0, 1.5"
    ];

    device = {
      name = "pixa3854:00-093a:0274-touchpad";
      natural_scroll = true;
    };
  };
}
