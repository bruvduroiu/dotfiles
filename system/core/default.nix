{ pkgs, lib, ... }:

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
    
    inputMethod = {
      type = "fcitx5";
      enable = true;

      fcitx5.addons = with pkgs; [
        fcitx5-rime
        fcitx5-gtk
        fcitx5-chewing
      ];
    };
  };

  # don't touch this
  system.stateVersion = "25.11"; # Did you read the comment?

  time.timeZone = "Asia/Taipei";
}
