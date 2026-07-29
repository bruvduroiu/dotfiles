{ ... }:

{
  programs.keepassxc = {
    enable = true;
    autostart = true;
    settings = {
      General = {
        ConfigVersion = 2;
        # Single running instance; reopen prior databases on launch.
        SingleInstance = true;
        RememberLastDatabases = true;
        RememberLastKeyFiles = true;
        OpenPreviousDatabasesOnStartup = true;
        AutoSaveAfterEveryChange = true;
        AutoSaveOnExit = true;
        AutoReloadOnChange = true;
        # No update nag (NixOS owns the package).
        UpdateCheckMessageShown = true;
      };

      GUI = {
        # "auto" follows the XDG appearance portal live (KeePassXC listens for
        # org.freedesktop.portal.Settings SettingChanged). Baking in
        # stylix.polarity instead would only apply on the next launch, since the
        # theme is read once at startup — and restarting means re-unlocking.
        ApplicationTheme = "auto";
        CompactMode = true;
        CheckForUpdates = false;
        # Close button minimises instead of quitting -> process stays alive so
        # Firefox's KeePassXC-Browser connection survives. Quit deliberately
        # with Ctrl+Q. MinimizeToTray hides the window on Wayland/Hyprland
        # (no visible tray icon without a tray host, which is fine).
        MinimizeOnClose = true;
        MinimizeToTray = true;
        ShowTrayIcon = true;
      };

      Security = {
        ClearClipboard = true;
        ClearClipboardTimeout = 10;

        LockDatabaseIdle = false;
        LockDatabaseIdleSeconds = 900;
        LockDatabaseScreenLock = true;
        LockDatabaseOnUserSwitch = true;

        PasswordsHidden = true;
        HidePasswordPreviewPanel = true;
      };

      Browser = {
        Enabled = true;
      };
    };
  };
}
