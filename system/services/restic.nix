{ config, lib, pkgs, inputs, ... }:

let
  # Storage Box configuration (account identifiers in private flake vars)
  inherit (inputs.secrets.vars.restic) storageBoxUser storageBoxHost;

  # Repository URL format for Hetzner Storage Box
  # Sub-account lands in /home, so we use //home/restic for absolute path
  repository = "sftp:${storageBoxUser}@${storageBoxHost}:23//home/restic";

  # Secrets file location
  secretsFile = "${inputs.secrets}/secrets/framework13/backup.yaml";

  # Wrapper script to use the security wrapper
  resticWrapper = pkgs.writeShellScriptBin "restic" ''
    exec /run/wrappers/bin/restic "$@"
  '';

  # SFTP command with sshpass for password authentication
  sftpCommand = "${pkgs.sshpass}/bin/sshpass -f ${config.sops.secrets.sftp_password.path} ssh ${storageBoxUser}@${storageBoxHost} -p 23 -o StrictHostKeyChecking=accept-new -s sftp";

  # Syncthing folder ids covering the backup paths above (Pictures is not
  # synced). See home/services/syncthing.nix.
  pausedFolders = [ "docs" "passwords" ];

  # This module is only in the `laptop` list (system/default.nix), so Home
  # Manager is always present and its config can be read directly. hister's
  # locations are derived from the module that owns them rather than copied,
  # because the databases have already moved once — a hardcoded duplicate here
  # would have silently dropped them from the backup at that moment.
  hm = config.home-manager.users.bogdan;

  histerPaths = [
    # app.directory: compressed HTML previews and favicons (the bulk), the
    # bleve full-text indexes, rules.json and .secret_key.
    "${hm.xdg.configHome}/hister"
    # server.database plus the vectors.sqlite3 it sits next to.
    "${hm.xdg.stateHome}/hister"
  ];

  # hister keeps sqlite, bolt and bleve segment files open read-write, so a
  # live copy would capture a torn set spread across three storage engines.
  # Upstream's guidance is explicit: "For a complete server backup, stop Hister
  # and back up the entire app.directory" (docs/data-lifecycle).
  histerControl = pkgs.writeShellApplication {
    name = "restic-hister-control";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      action="''${1:-}"
      case "$action" in
        stop | start) ;;
        *)
          echo "usage: restic-hister-control stop|start" >&2
          exit 2
          ;;
      esac

      # $UID is a bash builtin, so this resolves without depending on any
      # binary being on the PATH sudo hands us.
      export XDG_RUNTIME_DIR="/run/user/$UID"

      if ! systemctl --user "$action" hister.service; then
        echo "restic: failed to $action hister.service" >&2
      fi
    '';
  };

  # Syncthing 2.0 removed `cli operations pause|resume`; the equivalent is now
  # the per-folder `paused` config flag. Keeping the call behind one script
  # matters because sudoers matches the command line verbatim — the old rules
  # kept authorising a command that had stopped existing, so the backup failed
  # on a CLI usage error that only ever surfaced in the unit's post-stop log.
  syncthingPause = pkgs.writeShellApplication {
    name = "restic-syncthing-pause";
    runtimeInputs = [ pkgs.syncthing ];
    text = ''
      state="''${1:-}"
      case "$state" in
        true | false) ;;
        *)
          echo "usage: restic-syncthing-pause true|false" >&2
          exit 2
          ;;
      esac

      for folder in ${lib.escapeShellArgs pausedFolders}; do
        if ! syncthing cli config folders "$folder" paused set "$state"; then
          echo "restic: failed to set paused=$state on syncthing folder $folder" >&2
        fi
      done
    '';
  };
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

  # The backup prepare/cleanup hooks run as the restic user but must quiesce
  # bogdan's syncthing and hister; allow exactly those invocations, and only
  # those, without a password. sudoers matches the whole command line, so each
  # argument spelling needs its own entry.
  security.sudo.extraRules = [{
    users = [ "restic" ];
    runAs = "bogdan";
    commands = map (command: { inherit command; options = [ "NOPASSWD" ]; }) [
      "${lib.getExe syncthingPause} true"
      "${lib.getExe syncthingPause} false"
      "${lib.getExe histerControl} stop"
      "${lib.getExe histerControl} start"
    ];
  }];

  # Restic backup configuration
  services.restic.backups.hetzner = {
    # Run as restic user with security wrapper
    user = "restic";
    package = resticWrapper;

    # Repository and credentials
    inherit repository;
    passwordFile = config.sops.secrets.restic_password.path;

    # Initialize repository if it doesn't exist
    initialize = false;

    # Paths to back up
    paths = [
      "/home/bogdan/Documents"
      "/home/bogdan/Pictures"
      "/home/bogdan/Passwords"
      # Add more paths as needed:
      # "/home/bogdan/.local/share/keyrings"
    ] ++ histerPaths;

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

    # Quiesce hooks. Both services run as bogdan under home-manager, so we go
    # through sudo. Every call is `|| true`: a writer that cannot be stilled
    # should degrade the snapshot's consistency, never cancel the backup.
    backupPrepareCommand = ''
      # Pause Syncthing to ensure file consistency
      # Must use the setuid wrapper; the nix store sudo binary cannot elevate.
      # -H sets HOME to bogdan's so the syncthing CLI finds the config holding
      # the GUI address and API key.
      /run/wrappers/bin/sudo -H -u bogdan ${lib.getExe syncthingPause} true || true

      # Stop hister so its sqlite/bolt/bleve files are closed and consistent.
      /run/wrappers/bin/sudo -H -u bogdan ${lib.getExe histerControl} stop || true
    '';

    backupCleanupCommand = ''
      # Restart both after the backup (runs even on failure), hister first so
      # it is collecting again as early as possible.
      /run/wrappers/bin/sudo -H -u bogdan ${lib.getExe histerControl} start || true
      /run/wrappers/bin/sudo -H -u bogdan ${lib.getExe syncthingPause} false || true
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
