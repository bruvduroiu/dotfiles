{ config, lib, inputs, ... }:

{
  services.transmission = {
    group = "users";

    settings = {
      download-dir = "/srv/torrents/downloads";
      incomplete-dir = "/srv/torrents/incomplete";
    };

    credentialsFile = config.sops.secrets."transmission/credentials".path;
  };

  systemd.tmpfiles.rules = [
    "d /srv/torrents/downloads 0775 transmission users -"
    "d /srv/torrents/incomplete 0775 transmission users -"
  ];

  sops.secrets."transmission/credentials" = {
    sopsFile = "${inputs.secrets}/secrets/steamdeck/transmission.json";
    format = "binary";
    owner = "transmission";
    group = "users";
  };
}
