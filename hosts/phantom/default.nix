# Phantom USB - Host-specific configuration
# Minimal config - most functionality comes from system/default.nix phantom profile
{ pkgs, ... }:

{
  imports = [
    ./disko.nix
  ];

  # System identity
  networking.hostName = "phantom";

  # Same static fallback as Framework; Noctalia owns live application colors.
  stylix = {
    enable = true;
    image = ../../home/wallpapers/taipei-toner-4k-negative.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    polarity = "dark";
    fonts.monospace = {
      package = pkgs.nerd-fonts.hack;
      name = "Hack Nerd Font Mono";
    };
    fonts.sizes.terminal = 13;
    opacity.terminal = 0.9;
  };

  # System architecture
  nixpkgs.hostPlatform = "x86_64-linux";

  # Override greetd user (from desktop profile)
  desktop.greetd.user = "bogdan";

  # State version
  system.stateVersion = "25.11";
}
