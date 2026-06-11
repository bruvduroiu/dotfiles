{ pkgs, lib, ... }:

{
  imports = [
    ./users.nix
    ./sops.nix
  ];

  environment.variables.EDITOR = "nvim";

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
          globalOptions = {
            # Per-program IM state: chat apps stay in chewing, terminals stay
            # in English — switching focus doesn't drag the mode along.
            Behavior.ShareInputState = "Program";
          };

          inputMethod = {
            GroupOrder."0" = "Default";
            "Groups/0" = {
              Name = "Default";
              # Must match hyprland's input:kb_layout — fcitx can't push
              # layouts to wlroots compositors, matching bypasses its key
              # conversion (see fcitx wiki: Using Fcitx 5 on Wayland).
              "Default Layout" = "us";
            };
            "Groups/0/Items/0".Name = "keyboard-us";
            "Groups/0/Items/1".Name = "chewing";
          };
          addons.classicui.globalSection = {
            Theme = "rose-pine-dawn";
            DarkTheme = "rose-pine-moon";
            UseDarkTheme = true;
          };
        };

        # Leaves QT_IM_MODULE/GTK_IM_MODULE unset so Qt apps use native
        # wayland text-input-v3 and fcitx5 draws candidates server-side.
        # With QT_IM_MODULE=fcitx, the in-process fcitx5-qt plugin segfaults
        # Qt apps (FcitxCandidateWindow ctor) — killed Telegram on launch and
        # hyprland-share-picker. GTK apps keep the dbus module via gtk.nix.
        waylandFrontend = true;
      };
    };
  };

  # don't touch this
  system.stateVersion = "25.11"; # Did you read the comment?

  time.timeZone = "Europe/Bucharest";
}
