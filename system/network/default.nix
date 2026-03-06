{ config, lib, pkgs, ... }:

{
  networking = {
    nameservers = [ "9.9.9.9#dns.quad9.net" ];

    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi.powersave = true;
    };
  };

  services = {
    resolved = {
      enable = true;
      dnsovertls = "opportunistic";
    };
  };
}
