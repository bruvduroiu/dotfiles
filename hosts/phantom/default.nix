# Phantom USB - Host-specific configuration
# Minimal config - most functionality comes from system/default.nix phantom profile
{ config, lib, pkgs, inputs, self, ... }:

{
  imports = [
    ./disko.nix
  ];

  # System identity
  networking.hostName = "phantom";

  # System architecture
  nixpkgs.hostPlatform = "x86_64-linux";

  # Override greetd user (from desktop profile)
  desktop.greetd.user = "bogdan";

  # State version
  system.stateVersion = "25.11";
}
