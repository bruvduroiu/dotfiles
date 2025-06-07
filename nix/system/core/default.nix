{ lib, ... }:

{
  imports = [
    ./users.nix
  ];

  documentation.dev.enable = true;

  i18n = {
    defaultLocale = "en_GB.UTF-8";

    extraLocales = [
      "en_GB.UTF-8/UTF-8"
      "zh_TW.UTF-8/UTF-8"
    ];
  };

  # don't touch this
  system.stateVersion = "25.11"; # Did you read the comment?

  time.timeZone = "Asia/Taipei";
}
