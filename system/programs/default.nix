{
  imports = [
    ./fonts.nix
    ./xdg.nix
    ./home-manager.nix
    ./nix-ld.nix
  ];

  programs = {
    dconf.enable = true;
  };

  # KDE Connect requires ports 1714-1764 for TCP and UDP
  # Shared across all hosts for device discovery/communication
  networking.firewall = {
    allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
    allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
  };
}
