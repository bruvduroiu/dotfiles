{ config, ... }:

let
  # Stylix is only wired on framework13; live-iso/phantom lack it.
  hasStylix = config ? lib && config.lib ? stylix;
  # KeePassXC ApplicationTheme: "auto" follows the desktop, else light/dark.
  # config.stylix.polarity is "dark"/"light", which are valid theme values.
  appTheme = if hasStylix then config.stylix.polarity else "auto";
in
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
        ApplicationTheme = appTheme;
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
