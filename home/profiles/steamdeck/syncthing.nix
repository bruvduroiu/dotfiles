{ config, lib, pkgs, inputs, ... }:

let
  # Secrets file location
  secretsFile = "${inputs.secrets}/secrets/steamdeck/syncthing.yaml";

  # Device IDs - obtained from Syncthing on each device (run:
  # syncthing cli show system | grep myID); kept in the private
  # flake's vars so they stay out of the public repo
  deviceIds = inputs.secrets.vars.syncthing.deviceIds;

  # Common versioning configuration
  # Trashcan versioning moves deleted/replaced files to .stversions
  versioningConfig = {
    type = "trashcan";
    params = {
      cleanoutDays = "30";  # Keep deleted files for 30 days
    };
  };
in {
  # SOPS secrets configuration for Syncthing GUI authentication
  sops = {
    age.keyFile = "/home/deck/.config/sops/age/keys.txt";
    secrets = {
      syncthing_gui_password = {
        sopsFile = secretsFile;
      };
    };
  };

  services.syncthing = {
    enable = true;

    # Declarative configuration
    overrideDevices = true;
    overrideFolders = true;

    # GUI reachable from the home overlay (secured by the password below).
    # guiAddress does double duty in the HM module: it becomes Syncthing's
    # `--gui-address` (the real bind) and the curl target for the init script.
    # 0.0.0.0 is fine for both — the kernel routes a connect to 0.0.0.0 to
    # loopback — and a non-default value makes the module PATCH the stored
    # address itself. Matches home/services/syncthing.nix.
    guiAddress = "0.0.0.0:8384";

    # GUI credentials from SOPS secrets
    guiCredentials = {
      username = "deck";
      passwordFile = config.sops.secrets.syncthing_gui_password.path;
    };

    settings = {
      # NO `gui` block here, deliberately — not even a theme. home-manager's
      # merge-syncthing-config PATCHes the password from the sops secret first,
      # then PUTs settings.gui afterwards; Syncthing's REST PUT replaces the
      # whole gui object, so any key declared here blanks the password that was
      # just installed and every login fails as "invalid password". Set the
      # theme in the web UI instead. Same rule as home/services/syncthing.nix.

      options = {
        localAnnounceEnabled = true;
        globalAnnounceEnabled = true;
        relaysEnabled = true;
        natEnabled = true;
        relayReconnectIntervalM = 30;
        autoUpgradeIntervalH = 0;  # Disabled - managed by Nix
        crashReportingEnabled = false;
        startBrowser = false;
      };

      devices = {
        "Framework13" = {
          id = deviceIds.framework13;
          autoAcceptFolders = false;
          addresses = [ "dynamic" ];
        };
      };

      folders = {
        # Passwords folder - bidirectional sync with Framework13
        "Passwords" = {
          id = "passwords";
          path = "/home/deck/Passwords";
          devices = [ "Framework13" ];
          type = "sendreceive";
          versioning = versioningConfig;
          fsWatcherEnabled = true;
          rescanIntervalS = 3600;
          ignorePerms = true;
        };

        # Steam game recordings - send-only to Framework13
        # Recordings made on Steam Deck sync to Framework13 for backup/editing
        "Steam Recordings" = {
          id = "steam-recordings";
          path = "/home/deck/.local/share/Steam/userdata/1834090003/gamerecordings";
          devices = [ "Framework13" ];
          # Send-only: Steam Deck sends recordings but doesn't receive changes
          type = "sendonly";
          # No versioning needed for recordings (large files, append-only)
          fsWatcherEnabled = true;
          rescanIntervalS = 300;  # Check every 5 minutes for new recordings
          ignorePerms = true;
        };
      };
    };
  };

  # Ensure syncthing and syncthing-init services wait for SOPS to decrypt secrets
  systemd.user.services.syncthing = {
    Unit = {
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
  };

  # No ExecStartPost address fix-up any more: it hand-rolled the same
  # `PATCH /rest/config/gui {"address": …}` the HM module already emits for a
  # non-default guiAddress, and forced a restart to apply it. Setting
  # guiAddress = "0.0.0.0:8384" gets the bind right from the start instead.
  systemd.user.services.syncthing-init = {
    Unit = {
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
  };
}
