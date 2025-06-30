{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Latest kernel for Framework hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
