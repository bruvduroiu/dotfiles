{ lib, pkgs, ... }:

{
  virtualisation = {
    containers.enable = true;
    oci-containers.backend = "podman";
    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
      extraPackages = with pkgs; [
        iptables
      ];
    };
  };

  users.groups.podman = {
    name = "podman";
  };

  environment.systemPackages = with pkgs; [
    dive
    podman-tui
    podman-compose
    podman-desktop
    kind
  ];
}
