{ config, lib, pkgs, ... }:

{
  # Network manager applet for system tray
  environment.systemPackages = [ pkgs.networkmanagerapplet ];

  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
    
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
  };

  services = {
    resolved = {
      enable = true;
      # dnsovertls = "opportunistic";
    };
  };
}
