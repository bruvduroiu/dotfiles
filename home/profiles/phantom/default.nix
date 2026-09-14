# Phantom USB - Home Manager configuration
# Inherits from framework13 profile for familiar environment
# Adds phantom-specific overrides for ephemeral usage
{
  imports = [
    # Inherit the full framework13 experience
    ../framework13

  ];

  # Keep the shared bindings/layout without Framework's monitor placement.
  desktop.niri.portable = true;
}
