# Phantom USB - Universal hardware support
# Firmware and power management for any machine
{ config, lib, pkgs, ... }:

{
  # Include all firmware for maximum hardware compatibility
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.allowUnfree = true;

  # Power management for laptops
  services.upower.enable = true;
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "ignore";
    };
  };
}
