{ config, lib, pkgs, self, ... }:

let
  # Storage Box configuration
  storageBoxUser = "u519963-sub1";
  storageBoxHost = "u519963-sub1.your-storagebox.de";

  # Repository URL format for Hetzner Storage Box
  # Sub-account lands in /home, so we use //home/restic for absolute path
  repository = "sftp:${storageBoxUser}@${storageBoxHost}:23//home/restic";

  # Secrets file location
  secretsFile = "${self}/secrets/framework13/backup.yaml";

  # Wrapper script to use the security wrapper
  resticWrapper = pkgs.writeShellScriptBin "restic" ''
    exec /run/wrappers/bin/restic "$@"
  '';

  # SFTP command with sshpass for password authentication
  sftpCommand = "${pkgs.sshpass}/bin/sshpass -f ${config.sops.secrets.sftp_password.path} ssh ${storageBoxUser}@${storageBoxHost} -p 23 -o StrictHostKeyChecking=accept-new -s sftp";
in {
  # Create restic system user and group
  users.users.restic = {
    group = "restic";
    isSystemUser = true;
    home = "/var/lib/restic";
    createHome = true;
  };
  users.groups.restic = {};

  # Security wrapper for restic with cap_dac_read_search capability
  # This allows restic to read all files without running as root
  security.wrappers.restic = {
    source = lib.getExe pkgs.restic;
    owner = "restic";
    group = "restic";
    permissions = "u=rx,g=,o=";  # 500
    capabilities = "cap_dac_read_search+ep";
  };

  # sops secrets for backup
  sops.secrets = {
    # Restic repository encryption password
    restic_password = {
      sopsFile = secretsFile;
      owner = "restic";
      group = "restic";
    };
    # SFTP password for Storage Box authentication
    sftp_password = {
      sopsFile = secretsFile;
      owner = "restic";
      group = "restic";
      mode = "0400";
    };
  };

  # Restic backup configuration
  services.restic.backups.hetzner = {
    # Run as restic user with security wrapper
    user = "restic";
    package = resticWrapper;

    # Repository and credentials
    inherit repository;
    passwordFile = config.sops.secrets.restic_password.path;

    # Initialize repository if it doesn't exist
    initialize = true;

    # Paths to back up
    paths = [
      "/home/bogdan/Documents"
      "/home/bogdan/Pictures"
      "/home/bogdan/Passwords"
      "/home/bogdan/password.kdbx"
      # Add more paths as needed:
      # "/home/bogdan/.local/share/keyrings"
    ];

    # Exclusions
    exclude = [
      "**/.git/objects"
      "**/node_modules"
      "**/__pycache__"
      "**/.cache"
      "**/Cache"
      "**/*.tmp"
      "**/.Trash*"
      "**/lost+found"
      "**/.thumbnails"
    ];

    # Retention policy: 7 daily, 4 weekly, 6 monthly, 1 yearly
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
      "--keep-yearly 1"
    ];

    # Extra arguments for restic backup
    extraBackupArgs = [
      "--limit-upload=5000"  # 5 MB/s upload limit
      "--verbose"
    ];

    # Extra options (SFTP connection with password via sshpass)
    extraOptions = [
      "sftp.command='${sftpCommand}'"
    ];

    # Syncthing pause/resume hooks
    # Syncthing runs as user bogdan via home-manager, so we use sudo
    backupPrepareCommand = ''
      # Pause Syncthing to ensure file consistency
      ${pkgs.sudo}/bin/sudo -u bogdan ${pkgs.syncthing}/bin/syncthing cli operations pause || true
    '';

    backupCleanupCommand = ''
      # Resume Syncthing after backup (runs even on failure)
      ${pkgs.sudo}/bin/sudo -u bogdan ${pkgs.syncthing}/bin/syncthing cli operations resume || true
    '';

    # Schedule: daily at 02:00
    timerConfig = {
      OnCalendar = "02:00";
      RandomizedDelaySec = "1h";
      Persistent = true;  # Run if missed (e.g., laptop was off)
    };
  };

  # Ensure restic service waits for sops secrets
  systemd.services.restic-backups-hetzner = {
    after = [ "sops-nix.service" "network-online.target" ];
    wants = [ "sops-nix.service" "network-online.target" ];

    # Allow the restic user to access bogdan's home directory
    serviceConfig = {
      SupplementaryGroups = [ "users" ];
    };
  };

  # Weekly integrity check service
  systemd.services.restic-check-hetzner = {
    description = "Restic backup integrity check";
    after = [ "sops-nix.service" "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "restic";
      Group = "restic";
      SupplementaryGroups = [ "users" ];
    };

    script = ''
      export RESTIC_REPOSITORY="${repository}"
      export RESTIC_PASSWORD_FILE="${config.sops.secrets.restic_password.path}"

      # Run integrity check with 1% data sampling
      /run/wrappers/bin/restic check \
        --read-data-subset=1% \
        -o sftp.command='${sftpCommand}'
    '';
  };

  # Timer for weekly integrity check
  systemd.timers.restic-check-hetzner = {
    description = "Weekly restic integrity check";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "Sun 03:00";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };

  # Create mountpoint for restic restores with correct permissions
  systemd.tmpfiles.rules = [
    "d /mnt/restic 0750 restic restic -"
  ];

  # Make restic and sshpass available in PATH for manual operations
  environment.systemPackages = with pkgs; [ restic sshpass ];
}
