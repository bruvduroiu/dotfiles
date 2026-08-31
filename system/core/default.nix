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

            # Kill the bare-Shift_L "alt trigger". fcitx5 ships it enabled, and
            # it activates the group's *default* IM — which is chewing, not
            # keyboard-us: with >1 item fcitx5 forces DefaultIM to item[1] and
            # rewrites ~/.config/fcitx5/profile to say so, so pinning
            # DefaultIM=keyboard-us here would just get normalised away. One
            # stray Shift tap therefore dropped a terminal into Bopomofo, and
            # chewing eats Esc into its preedit-clear — Helix and fish-helix
            # both lose normal mode while every other app looks fine.
            # Ctrl+Space (Hotkey/TriggerKeys) still toggles deliberately.
            #
            # `Key = ""` is how fcitx5 itself serialises an empty key list
            # (cf. the EnumerateForwardKeys= lines it writes); a populated list
            # is a [Hotkey/AltTriggerKeys] subsection instead, and an empty
            # subsection would NOT clear the default — fcitx5's ini reader only
            # materialises a node when it sees a key=value line.
            Hotkey.AltTriggerKeys = "";
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
          # Layout override only works on KDE/GNOME; on Hyprland it just
          # triggers the "Wayland Diagnose" notification at boot. Layouts
          # already match manually (kb_layout above).
          addons.wayland.globalSection."Allow Overriding System XKB Settings" =
            "False";
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
