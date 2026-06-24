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

    # Keys, types and defaults mirror KeePassXC's src/core/Config.cpp.
    # Section names are the prefix before "/" in that file; ungrouped keys
    # (SingleInstance, RememberLastDatabases, ...) live under [General].
    settings = {
      General = {
        # Single running instance; reopen prior databases on launch.
        SingleInstance = true;
        RememberLastDatabases = true;
        RememberLastKeyFiles = true;
        OpenPreviousDatabasesOnStartup = true;

        # Persist immediately; never lose edits on crash/exit.
        AutoSaveAfterEveryChange = true;
        AutoSaveOnExit = true;
        AutoReloadOnChange = true;

        # Tidy clipboard/window behaviour.
        MinimizeOnCopy = false;
        HideWindowOnCopy = false;

        # No update nag (NixOS owns the package).
        UpdateCheckMessageShown = true;
      };

      GUI = {
        ApplicationTheme = appTheme;
        CompactMode = true;
        ShowTrayIcon = false;
        MinimizeToTray = false;
        MinimizeOnClose = false;
        # AdvancedSettings + HidePasswords here are deprecated->Deleted in
        # Config.cpp; password masking lives under Security/PasswordsHidden.
        CheckForUpdates = false;
      };

      Security = {
        # Clipboard wiped 10s after copy.
        ClearClipboard = true;
        ClearClipboardTimeout = 10;

        # Auto-lock: idle, screen lock, user switch.
        LockDatabaseIdle = true;
        LockDatabaseIdleSeconds = 900;
        LockDatabaseScreenLock = true;
        LockDatabaseOnUserSwitch = true;

        PasswordsHidden = true;
        HidePasswordPreviewPanel = true;
      };

      Browser = {
        Enabled = true;
      };

      SSHAgent = {
        Enabled = true;
        UseOpenSSH = true;
      };
    };
  };
}
