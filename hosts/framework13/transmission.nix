{ config, self, ... }:

{
  services.transmission = {
    group = "users";

    settings = {
      download-dir = "/home/bogdan/torrents";
      incomplete-dir = "/home/bogdan/torrents/.incomplete";
    };

    credentialsFile = config.sops.secrets."transmission/credentials".path;
  };

  sops.secrets."transmission/credentials" = {
    sopsFile = "${self}/secrets/framework13/transmission.json";
    format = "binary";
    owner = "transmission";
    group = "users";
  };
}
