{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  
  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
