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

  sops.age.keyFile = lib.mkForce "/home/deck/.config/sops/age/keys.txt";

  sops.secrets."transmission/credentials" = {
    sopsFile = "${self}/secrets/steamdeck/transmission.json";
    format = "binary";
    owner = "transmission";
    group = "users";
  };
}
