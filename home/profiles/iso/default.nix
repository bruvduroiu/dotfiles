{
  imports = [
    # Editors - vital!
    ../../editors/nvim

    # Terminal configuration
    ../../terminal
    ../../terminal/emulators/ghostty.nix

    # Wayland/Hyprland essentials
    ../../programs/wayland
    ../../programs/gtk.nix
    ../../programs/gpg.nix

    # Desktop services
    ../../services/wayland/hyprpaper.nix
    ../../services/mako.nix
    ../../services/gpg.nix
    ../../services/media/playerctl.nix
    ../../services/trayscale.nix

    # Tailscale auto-auth (prompts for YubiKey PIN after login)
    ./tailscale.nix
  ];

  # Generic Hyprland settings for any display
  wayland.windowManager.hyprland.settings = {
    # Auto-detect monitors
    monitor = [
      ", preferred, auto, 1"
    ];

    # Generic touchpad settings
    input = {
      touchpad = {
        natural_scroll = true;
        tap-to-click = true;
      };
    };
  };
}
