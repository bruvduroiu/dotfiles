{ config, lib, pkgs, self, ... }:

let
  # Secrets file location
  secretsFile = "${self}/secrets/steamdeck/syncthing.yaml";

  # Device IDs - obtained from Syncthing on each device
  pixelDeviceId = "EHS76NL-XYJS6IK-JQOJ35O-ZPGYXC3-7WNSC6S-ZEDAJH3-4JGALW2-WKC7CA4";
  
  # Framework13 device ID - get this from Framework13's Syncthing
  # Run: syncthing cli show system | grep myID
  framework13DeviceId = "U2HCYXA-75I4XWY-SNDJ6TQ-XKW36GG-USC5ZX2-VPOVYTZ-DX3ZS6E-X7JEAQZ";

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

    # Note: We use 127.0.0.1 here because home-manager's syncthing-init service
    # uses guiAddress for API calls (0.0.0.0 is not a valid connect address).
    # The actual binding address (0.0.0.0:8384) is set via ExecStartPost below.
    guiAddress = "127.0.0.1:8384";

    # GUI password from SOPS secrets
    passwordFile = config.sops.secrets.syncthing_gui_password.path;

    settings = {
      gui = {
        theme = "dark";
        user = "deck";
        # Note: address is set via systemd ExecStartPost below because
        # home-manager's syncthing module overwrites settings.gui.address
        # with guiAddress at the end of the init script.
      };

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
          id = framework13DeviceId;
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

  systemd.user.services.syncthing-init = {
    Unit = {
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
    Service = {
      # After the init script runs, set the GUI address to 0.0.0.0:8384 for remote access.
      # This is needed because home-manager's syncthing module uses guiAddress for both
      # API calls (must be 127.0.0.1) and the final bind address (we want 0.0.0.0).
      ExecStartPost = let
        script = pkgs.writeShellScript "syncthing-set-gui-address" ''
          API_KEY=$(${pkgs.gnugrep}/bin/grep -oP '(?<=<apikey>)[^<]+' ~/.local/state/syncthing/config.xml)
          ${pkgs.curl}/bin/curl -s -X PATCH \
            -H "X-API-Key: $API_KEY" \
            -d '{"address": "0.0.0.0:8384"}' \
            http://127.0.0.1:8384/rest/config/gui
          # Restart syncthing to apply the address change
          ${pkgs.curl}/bin/curl -s -X POST \
            -H "X-API-Key: $API_KEY" \
            http://127.0.0.1:8384/rest/system/restart
        '';
      in "${script}";
    };
  };
}
