{ config, self, pkgs, ... }:

let
  secretsFile = "${self}/secrets/framework13/rental-bot.yaml";
in {
  # sops secrets configuration
  sops = {
    age.keyFile = "/home/bogdan/.config/sops/age/keys.txt";

    secrets.telegram_bot_token.sopsFile = secretsFile;
    secrets.telegram_user_id.sopsFile = secretsFile;

    templates."rental-bot.env" = {
      content = ''
        TELEGRAM_BOT_TOKEN=${config.sops.placeholder.telegram_bot_token}
        TELEGRAM_USER_ID=${config.sops.placeholder.telegram_user_id}
      '';
    };
  };

  # rental-bot service configuration
  services.rental-bot = {
    enable = true;
    telegramTokenFile = config.sops.templates."rental-bot.env".path;
    dataDir = "/home/bogdan/Documents/591-bot";
    scrapeSchedule = [ "09:00" "21:00" ];
    user = "bogdan";
  };

  # Ensure rental-bot waits for sops secrets to be available
  # and has access to geckodriver
  systemd.services.rental-bot = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    environment = {
      GECKODRIVER_PATH = "${pkgs.geckodriver}/bin/geckodriver";
    };
    serviceConfig = {
      ReadWritePaths = [ "/home/bogdan/.cache/dconf" ];
    };
  };
}
