# Phantom USB - Hyprland monitor configuration
# Auto-detect displays since we don't know what machine we'll boot on
{
  wayland.windowManager.hyprland.settings = {
    # Auto-configure any connected monitor
    # This overrides the framework13 specific monitor config
    monitor = [
      # Prefer high resolution, auto-position, with scaling
      ",preferred,auto,1"
    ];

    # Generic touchpad settings (works on most laptops)
    device = {
      name = "generic-touchpad";
      natural_scroll = true;
    };

    # Input configuration for unknown hardware
    input = {
      # Enable tap-to-click for any touchpad
      touchpad = {
        tap-to-click = true;
        natural_scroll = true;
      };
    };
  };
}
