{ pkgs, lib, ... }:

{
  imports = [
    ./users.nix
    ./sops.nix
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

      fcitx5 = {
        addons = with pkgs; [
          rime-data
          fcitx5-rime
          fcitx5-gtk
          fcitx5-chewing
          fcitx5-rose-pine
        ];

        settings = {
          inputMethod = {
            GroupOrder."0" = "Default";
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "gb";
            };
            "Groups/0/Items/0".Name = "keyboard-gb";
            "Groups/0/Items/1".Name = "chewing";
          };
          addons.classicui.globalSection = {
            Theme = "rose-pine-dawn";
            DarkTheme = "rose-pine-moon";
            UseDarkTheme = true;
          };
        };

        # waylandFrontend = true;

      };
    };
  };

  # don't touch this
  system.stateVersion = "25.11"; # Did you read the comment?

  time.timeZone = "Asia/Taipei";
}
