# Phantom USB - Home Manager configuration
# Inherits from framework13 profile for familiar environment
# Adds phantom-specific overrides for ephemeral usage
{
  imports = [
    # Inherit the full framework13 experience
    ../framework13

    # Override monitor config for unknown displays
    ./hyprland.nix
  ];

  # Phantom-specific home settings can go here
  # Most config comes from framework13 profile
}
