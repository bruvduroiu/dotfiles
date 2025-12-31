{ config, lib, pkgs, ... }:

let
  qbtConfigTemplate = pkgs.writeText "qbittorrent.conf" ''
    [LegalNotice]
    Accepted=true

    [Preferences]
    # Downloads
    Downloads\SavePath=${config.home.homeDirectory}/torrents
    Downloads\TempPath=${config.home.homeDirectory}/torrents/.incomplete
    Downloads\TempPathEnabled=true
    Downloads\StartInPause=false

    # Connection
    Connection\PortRangeMin=6881
    Connection\UPnP=true
    Connection\GlobalDLLimitAlt=0
    Connection\GlobalUPLimitAlt=0

    # BitTorrent
    Bittorrent\DHT=true
    Bittorrent\PeX=true
    Bittorrent\LSD=true
    Bittorrent\Encryption=1

    # WebUI
    WebUI\Enabled=true
    WebUI\Address=0.0.0.0
    WebUI\Port=9091
    WebUI\Username=admin
    WebUI\Password_PBKDF2="@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)"
    WebUI\LocalHostAuth=false
    WebUI\AuthSubnetWhitelistEnabled=false
    WebUI\CSRFProtection=false
    WebUI\ClickjackingProtection=false
    WebUI\HostHeaderValidation=false

    # Advanced
    Advanced\RecheckOnCompletion=false
    Advanced\useSystemIconTheme=false
  '';
in
{
  # qBittorrent daemon configuration
  # WebUI accessible at http://localhost:9091 or http://<tailscale-ip>:9091
  # Default credentials: admin / adminadmin (will be disabled for Tailscale access)

  # Copy config template as writable file (qBittorrent needs to modify it)
  home.activation.qbittorrentConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/.config/qBittorrent
    if [ ! -f $HOME/.config/qBittorrent/qBittorrent.conf ]; then
      $DRY_RUN_CMD cp ${qbtConfigTemplate} $HOME/.config/qBittorrent/qBittorrent.conf
      $DRY_RUN_CMD chmod 644 $HOME/.config/qBittorrent/qBittorrent.conf
    fi
  '';

  # Systemd user service for qBittorrent
  systemd.user.services.qbittorrent = {
    Unit = {
      Description = "qBittorrent-nox BitTorrent Client";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
