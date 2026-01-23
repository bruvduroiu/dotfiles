{ pkgs, ... }:

{
  # Transmission BitTorrent daemon (sandboxed system service)
  # Host-specific settings (download paths, credentials) are in hosts/<hostname>/transmission.nix
  services.transmission = {
    enable = true;

    # Pin to 4.0.5 (tracker whitelist requirement — 4.0.6 is not whitelisted)
    package = pkgs.transmission_4.overrideAttrs (old: rec {
      version = "4.0.5";
      src = pkgs.fetchurl {
        url = "https://github.com/transmission/transmission/releases/download/${version}/transmission-${version}.tar.xz";
        hash = "sha256-/Wj/EUpHkgAEPDDH5p26TBky9682ykxbXS7ctYZuY1c=";
      };
    });

    # Firewall
    openPeerPorts = true;   # Open peer port (TCP + UDP) for seeding
    openRPCPort = true;     # Open RPC port for WebUI access

    # Directory permissions: group-writable so user can access downloads
    downloadDirPermissions = "0775";

    # Kernel network tuning for better torrent performance
    performanceNetParameters = true;

    settings = {
      # Peer settings
      peer-port = 6881;
      peer-port-random-on-start = false;
      utp-enabled = true;           # μTP for NAT traversal and congestion control
      port-forwarding-enabled = true; # UPnP/NAT-PMP for router port forwarding

      # Private tracker requirements (DHT/PEX/LPD leak peer info — trackers ban for this)
      dht-enabled = false;
      pex-enabled = false;
      lpd-enabled = false;

      # Seeding: never auto-stop (let the tracker manage ratio)
      ratio-limit-enabled = false;
      idle-seeding-limit-enabled = false;
      seed-queue-enabled = false;

      # Upload: no speed cap (maximize ratio)
      speed-limit-up-enabled = false;
      upload-slots-per-torrent = 14;

      # RPC / WebUI
      rpc-port = 9091;
      rpc-bind-address = "0.0.0.0";
      rpc-authentication-required = true;
      rpc-username = "bogdan";
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;

      # Encryption: prefer encrypted connections (1 = prefer, 2 = require)
      encryption = 1;

      # File handling
      incomplete-dir-enabled = true;
      rename-partial-files = true;
      trash-original-torrent-files = false;
      umask = 2;  # Files created as group-writable (002)

      # Logging
      message-level = 2;  # 0=none, 1=error, 2=info, 3=debug
    };
  };
}
