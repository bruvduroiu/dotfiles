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

      # Serve org.freedesktop.secrets (gnome-keyring is off, see
      # system/programs/niri). This is for credentials an app rewrites at
      # runtime, like hey's rotating OAuth token, which sops can't hold:
      # sops stays the store for static and boot-time secrets (docs/secrets.md).
      # Clients only see the groups exposed under Database Settings → Secret
      # Service Integration; that choice lives in the .kdbx, not here.
      FdoSecrets = {
        Enabled = true;
        # No per-read prompt. KeePassXC 2.7 remembers "Allow All & Future"
        # only for the requesting process (an in-memory DBusClient), and every
        # hey/codex/podman run is a new process, so it asked on every command.
        # The boundary is what you expose instead: only a dedicated group of
        # app tokens, never the database root (docs/secrets.md). A process
        # running as you could run the approved tools anyway.
        ConfirmAccessItem = false;
        ConfirmDeleteItem = true;
        # A locked database asks to unlock instead of looking empty.
        UnlockBeforeSearch = true;
      };
    };
  };
}
