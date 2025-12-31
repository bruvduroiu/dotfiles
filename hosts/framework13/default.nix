{ lib, pkgs, self, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hyprland.nix
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;
  };

  # System configuration
  networking.hostName = "framework13";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services = {
    kanata.keyboards.io = {
      config = builtins.readFile "${self}/system/services/kanata/main.kbd";
      devices = [
        "/dev/input/by-path/platform-AMDI0010:01-event"
        "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
      ];
    };
  };
}
