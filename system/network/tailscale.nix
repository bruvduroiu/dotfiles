{ config, pkgs, ... }:

{
  networking = {
    firewall = {
      trustedInterfaces = [ "tailscale0" ];

      # required to connect to Tailscale exit nodes
      checkReversePath = "loose";

      allowedUDPPorts = [ config.services.tailscale.port ];
      allowedTCPPorts = [ config.services.tailscale.port ];
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraUpFlags = [ "--operator=${config.users.users.bogdan.name}" ];
  };

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";

    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

    '';

  };
}
