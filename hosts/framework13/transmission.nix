{ config, inputs, ... }:

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
    sopsFile = "${inputs.secrets}/secrets/framework13/transmission.json";
    format = "binary";
    owner = "transmission";
    group = "users";
  };

  # The prestart merges the credentials into settings.json once, at start;
  # wait for the late YubiKey decrypt (system/core/sops.nix).
  yubikeySops.consumers.transmission =
    config.sops.secrets."transmission/credentials".path;
}
