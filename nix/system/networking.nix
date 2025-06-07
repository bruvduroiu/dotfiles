{ config, pkgs, ... }:

{
  networking = {
    networkmanager.enable = true;
    
    # Enable Bluetooth
    bluetooth = {
      enable = true;

    }
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;

    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
    firewall = {
      enable = true;

      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];

      allowedUDPPorts = [ config.services.tailscale.port ];
      allowedTCPPorts = [ config.services.tailscale.port ];
    };
  };
}
