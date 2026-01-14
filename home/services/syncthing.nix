{ config, lib, pkgs, self, ... }:

let
  # Secrets file location
  secretsFile = "${self}/secrets/framework13/syncthing.yaml";

  # Device IDs - obtained from Syncthing on each device
  pixelDeviceId = "EHS76NL-XYJS6IK-JQOJ35O-ZPGYXC3-7WNSC6S-ZEDAJH3-4JGALW2-WKC7CA4";
  steamdeckDeviceId = "K2C4VNS-LC6JK3Y-INBSG3M-CKEHHXN-23OWLLF-KEGGS5C-GGIQIBO-Y3PHHQ6";
  iphoneDeviceId = "HECSBOL-KJFXURK-HUUTKJR-522Y3BO-TDTGBTO-YVCSBFP-SVX66UJ-SSZANQL";
  booxDeviceId = "SBYZ3UR-RBMS2SX-WRFFGOZ-5XNJIRH-TOMNMVG-55DEFJZ-UFH3I2V-XET4AQM";

  # Common versioning configuration for 3-2-1 backup strategy
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
    age.keyFile = "/home/bogdan/.config/sops/age/keys.txt";
    secrets = {
      syncthing_gui_password = {
        sopsFile = secretsFile;
      };
    };
  };

  services.syncthing = {
    enable = true;

    # Declarative configuration - overwrite any manual changes
    overrideDevices = true;
    overrideFolders = true;

    # GUI accessible from all interfaces (secured by password)
    # Access via: http://localhost:8384 or http://<tailscale-ip>:8384
    guiAddress = "0.0.0.0:8384";

    # GUI password from SOPS secrets
    passwordFile = config.sops.secrets.syncthing_gui_password.path;

    settings = {
      gui = {
        theme = "dark";
        # Hardcoded username for GUI authentication
        user = "bogdan";
      };

      options = {
        # Prefer local network syncing to save Tailscale/mobile data
        # Local discovery on LAN - primary sync method
        localAnnounceEnabled = true;
        # Global discovery as fallback when not on same LAN
        globalAnnounceEnabled = true;
        # Relay servers as last resort (uses bandwidth)
        relaysEnabled = true;
        # NAT traversal for direct connections
        natEnabled = true;
        # Limit relay usage - prefer direct connections
        relayReconnectIntervalM = 30;
        # Automatically upgrade syncthing
        autoUpgradeIntervalH = 0;  # Disabled - managed by Nix
        # Crash reporting
        crashReportingEnabled = false;
        # Start browser on startup
        startBrowser = false;
      };

      # Devices to sync with
      devices = {
        "Pixel 10 Pro" = {
          id = pixelDeviceId;
          # Auto-accept folders shared by this device
          autoAcceptFolders = false;
          # Addresses - let Syncthing discover automatically
          # Prefers local discovery, falls back to global/relay
          addresses = [ "dynamic" ];
        };
        "Steam Deck" = {
          id = steamdeckDeviceId;
          autoAcceptFolders = false;
          addresses = [ "dynamic" ];
        };
        "Boox Go Color 7" = {
          id = booxDeviceId;
          autoAcceptFolders = false;
          addresses = [ "dynamic" ];
        };
      };

      # Folders to sync - matching restic backup paths
      folders = {
        # Documents folder - bidirectional sync with Pixel, send-only to Steam Deck
        "Documents" = {
          id = "docs";
          path = "/home/bogdan/Documents";
          devices = [ "Pixel 10 Pro" ];
          # Bidirectional sync (Steam Deck is configured as receive-only on its end)
          type = "sendreceive";
          # Versioning for 3-2-1 backup (local versions)
          versioning = versioningConfig;
          # Watch for changes using inotify
          fsWatcherEnabled = true;
          # Rescan interval in seconds (fallback if inotify misses something)
          rescanIntervalS = 3600;  # 1 hour
          # Ignore permissions (mobile devices have different permission models)
          ignorePerms = true;
        };

        # Passwords folder - sync across all devices
        "Passwords" = {
          id = "passwords";
          path = "/home/bogdan/Passwords";
          devices = [ "Pixel 10 Pro" "Steam Deck" ];
          type = "sendreceive";
          versioning = versioningConfig;
          fsWatcherEnabled = true;
          rescanIntervalS = 3600;
          ignorePerms = true;
        };

        # Steam game recordings from Steam Deck - receive-only
        "Steam Recordings" = {
          id = "steam-recordings";
          path = "/home/bogdan/Videos/Steam Recordings";
          devices = [ "Steam Deck" ];
          # Receive-only: Framework13 receives recordings but doesn't modify them
          type = "receiveonly";
          # No versioning for large video files
          fsWatcherEnabled = true;
          rescanIntervalS = 3600;
          ignorePerms = true;
        };

        # Books folder - bidirectional sync with Boox eReader only
        "Books" = {
          id = "books";
          path = "/home/bogdan/Documents/Personal/Books";
          devices = [ "Boox Go Color 7" ];
          type = "sendreceive";
          versioning = versioningConfig;
          fsWatcherEnabled = true;
          rescanIntervalS = 3600;
          ignorePerms = true;
        };
      };
    };
  };

  # Ensure syncthing service waits for SOPS to decrypt secrets
  systemd.user.services.syncthing = {
    Unit = {
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
  };

  # Syncthing ignore patterns - managed declaratively
  # These files tell Syncthing which paths to exclude from syncing
  #
  # Strategy: .stignore files are NOT synced by Syncthing (by design).
  # We use #include to reference a .stignore-common file that IS synced,
  # allowing all devices to share the same ignore patterns.
  # 
  # On mobile devices (Pixel), create a .stignore with:
  #   #include .stignore-common
  home.file = {
    # Shared ignore patterns - this file IS synced to all devices
    "Documents/.stignore-common".text = ''
      // Shared ignore patterns for all devices
      // This file is synced, then included by each device's .stignore
      
      // Obsidian configuration - managed by home-manager on Framework13
      // Contains symlinks that can't sync to Android/iOS
      **/.obsidian
    '';

    # Local .stignore that includes the shared patterns
    "Documents/.stignore".text = ''
      // Include shared ignore patterns (synced across devices)
      #include .stignore-common
    '';

    # Books folder - ignore Boox-specific .sdr directories
    # These contain reading progress/annotations specific to the Boox device
    "Documents/Personal/Books/.stignore".text = ''
      // Ignore Boox eReader metadata directories
      // .sdr folders contain annotations, reading progress, and device-specific data
      **/*.sdr
    '';
  };
}
