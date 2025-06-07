{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../system
  ];

  # System configuration
  networking.hostName = "framework13";
  time.timeZone = "Asia/Taipei"; # Adjust to your timezone

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.05";
}
