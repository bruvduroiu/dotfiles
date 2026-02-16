{ config, lib, self, ... }:

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

  sops.age.keyFile = lib.mkForce "/home/deck/.config/sops/age/keys.txt";

  sops.secrets."transmission/credentials" = {
    sopsFile = "${self}/secrets/steamdeck/transmission.json";
    format = "binary";
    owner = "transmission";
    group = "users";
  };
}
