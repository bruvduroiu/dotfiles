{
  # qBittorrent firewall configuration
  # Opens ports for incoming peer connections to enable seeding

  networking.firewall = {
    # qBittorrent default port for incoming connections
    # TCP: For peer connections and data transfer
    # UDP: For DHT (Distributed Hash Table) and peer discovery
    allowedTCPPorts = [ 6881 ];
    allowedUDPPorts = [ 6881 ];

    # If you need to support a range of ports, uncomment:
    # allowedTCPPortRanges = [{ from = 6881; to = 6889; }];
    # allowedUDPPortRanges = [{ from = 6881; to = 6889; }];
  };
}
