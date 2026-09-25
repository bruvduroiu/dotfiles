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

  # SFTP command with sshpass for password authentication.
  #
  # ServerAlive* is load-bearing, not tuning. On 2026-09-05 the Storage Box
  # dropped a six-minute-old check connection ("closed by remote host"); every
  # later operation returned `ssh command exited: exit status 255`, including
  # the one that would have removed the check's own lock. Keepalives every 30s,
  # giving up after three minutes of silence, turn a dead transport into a
  # prompt clean failure rather than a long stretch of doomed retries.
  sftpCommand = "${pkgs.sshpass}/bin/sshpass -f ${config.sops.secrets.sftp_password.path} ssh ${storageBoxUser}@${storageBoxHost} -p 23 -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -s sftp";

  # Clearing a leaked lock before doing anything else.
  #
  # The NixOS module already emits `restic unlock` — but as the *second* of
  # three ExecStart= lines (backup, unlock, forget --prune), and systemd
  # abandons the rest of the list at the first non-zero exit. A stale lock
  # fails `backup` with exit 11, so the unlock that would clear it never runs.
  # The repo stays wedged until a human notices, which is exactly what happened
  # on 2026-07-15 (49 days) and again on 2026-09-05.
  #
  # Running it in the prepare step puts it ahead of the thing it unblocks.
  # `unlock` without --remove-all only removes locks whose owning process is
  # gone, so a genuinely concurrent run is left alone — that case is handled by
  # --retry-lock below instead.
  resticUnlock = pkgs.writeShellApplication {
    name = "restic-unlock-stale";
    text = ''
      # RESTIC_REPOSITORY and RESTIC_PASSWORD_FILE come from the unit's
      # Environment=, which systemd applies to ExecStartPre as well.
      /run/wrappers/bin/restic unlock -o sftp.command='${sftpCommand}'
    '';
  };

  # Waiting for the Storage Box to resolve before touching the network.
  #
  # The laptop sleeps through 02:00, so Persistent= fires the missed run at
  # the very second of resume — before Wi-Fi has re-associated (~4s later on
  # 2026-09-29). `after = network-online.target` cannot help: that target is
  # reached once at boot and stays active across suspend, so it gates nothing
  # on wake. Every catch-up run between 09-24 and 09-29 died on "Could not
  # resolve hostname" for exactly this reason.
  #
  # Resolving the actual host is the most direct readiness signal there is.
  # On timeout it exits non-zero on purpose, so the failure notification
  # names the network rather than a restic stack of sftp errors.
  waitOnline = pkgs.writeShellApplication {
    name = "restic-wait-online";
    runtimeInputs = [ pkgs.getent pkgs.coreutils ];
    text = ''
      timeout=180
      until getent hosts ${storageBoxHost} >/dev/null; do
        if (( SECONDS >= timeout )); then
          echo "restic: ${storageBoxHost} still unresolvable after ''${timeout}s, network not up" >&2
          exit 1
        fi
        sleep 5
      done
      if (( SECONDS > 0 )); then
        echo "restic: network up after ''${SECONDS}s"
      fi
    '';
  };

  # Syncthing folder ids covering the backup paths above (Pictures is not
  # synced). See home/services/syncthing.nix.
  pausedFolders = [ "docs" "passwords" ];

  # A stale exclusive lock left behind on 2026-07-15 blocked every backup and
  # every integrity check until 2026-09-02 — 49 days — and nothing said so:
  # the units failed into the journal and the only visible symptom was hister
  # being stopped by the prepare hook. Any unattended job needs a way to reach
  # the human, so both restic units hang OnFailure off this template.
  #
  # It runs as bogdan to inherit the session notification bus. Notifications
  # survive in the shell's notification history, so an 02:00 failure is still readable at
  # breakfast. Everything degrades to `true`: a failure handler that itself
  # fails must never mask the failure it was reporting.
  notifyFailure = pkgs.writeShellApplication {
    name = "systemd-notify-failure";
    runtimeInputs = [ pkgs.libnotify pkgs.systemd ];
    text = ''
      unit="''${1:?usage: systemd-notify-failure <unit>}"

      # Last few lines of the failed unit, so the notification carries the
      # actual error rather than just the unit name.
      detail="$(journalctl -u "$unit" -n 4 --no-pager -o cat 2>/dev/null \
        | grep -viE '^(sudo|pam_unix)' | tail -2 || true)"

      export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
      notify-send -u critical -a restic -t 0 \
        "Backup job failed: $unit" "''${detail:-see journalctl -u $unit}" || true
    '';
  };

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

    # Retention policy: 7 daily, 4 weekly, 6 monthly, 1 yearly.
    #
    # `--group-by host` is load-bearing, not cosmetic. restic defaults to
    # `host,paths`, so every edit to `paths` above opens a *new* retention
    # bucket and strands the old one: as of 2026-09-02 this repo held five
    # buckets (Documents+Pictures; +password.kdbx; +Passwords; Passwords
    # without kdbx; +hister), each independently under its keep counts, so
    # nothing had aged out since 2025-12 and the policy below was inert.
    #
    # Grouping by host alone makes retention mean what it reads as. It also
    # means the first run after this lands will delete the historical
    # snapshots the old grouping preserved — see docs before switching.
    pruneOpts = [
      "--group-by host"
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
      "--keep-yearly 1"
    ];

    # Extra arguments for restic backup
    extraBackupArgs = [
      "--verbose"
      # restic's default is no retries at all — the journal's "repo already
      # locked, waiting up to 0s for the lock" is that default talking. The
      # prepare step above handles *stale* locks; this handles a live one,
      # i.e. the weekly check still running when the daily backup fires. Their
      # timers (02:00 ±1h and Sun 03:00 ±1h) overlap by construction.
      "--retry-lock 10m"
    ];

    # Extra options (SFTP connection with password via sshpass)
    extraOptions = [
      "sftp.command='${sftpCommand}'"
    ];

    # Quiesce hooks. Both services run as bogdan under home-manager, so we go
    # through sudo. Every call is `|| true`: a writer that cannot be stilled
    # should degrade the snapshot's consistency, never cancel the backup.
    backupPrepareCommand = ''
      # Resume-from-suspend catch-up runs start before Wi-Fi is back. Not
      # `|| true`: with no network there is nothing useful left to do, and
      # failing here happens before hister and syncthing are disturbed.
      ${lib.getExe waitOnline}

      # Clear any lock left behind by a run that lost its transport. First,
      # before the quiesce, so a hanging unlock does not hold hister down with
      # it. `|| true` because a network failure here fails the backup a moment
      # later anyway, with a better message than this step could give.
      ${lib.getExe resticUnlock} || true

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

  # Desktop notification for a failed unit. Instantiated as
  # notify-failure@<unit>.service — %n expands to the failing unit's full name,
  # so one template covers both restic jobs and anything added later.
  systemd.services."notify-failure@" = {
    description = "Desktop notification that %i failed";
    serviceConfig = {
      Type = "oneshot";
      User = "bogdan";
      # journal read access for the excerpt the notification carries
      SupplementaryGroups = [ "systemd-journal" ];
      ExecStart = "${lib.getExe notifyFailure} %i";
    };
  };

  # Ensure restic service waits for sops secrets
  systemd.services.restic-backups-hetzner = {
    after = [ "sops-nix.service" "network-online.target" ];
    wants = [ "sops-nix.service" "network-online.target" ];
    onFailure = [ "notify-failure@%n.service" ];

    # Allow the restic user to access bogdan's home directory
    serviceConfig = {
      SupplementaryGroups = [ "users" ];
    };
  };

  # Weekly integrity check service
  systemd.services.restic-check-hetzner = {
    description = "Restic backup integrity check";
    # Ordered after the backup so that when both land in one transaction the
    # backup — the job that actually protects data — gets the lock first. This
    # only orders a shared transaction; the overlapping-timer case is covered
    # by --retry-lock on both units.
    after = [ "sops-nix.service" "network-online.target" "restic-backups-hetzner.service" ];
    wants = [ "network-online.target" ];
    onFailure = [ "notify-failure@%n.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = "restic";
      Group = "restic";
      SupplementaryGroups = [ "users" ];
    };

    script = ''
      export RESTIC_REPOSITORY="${repository}"
      export RESTIC_PASSWORD_FILE="${config.sops.secrets.restic_password.path}"

      # Same resume race as the backup; hit on 2026-09-28.
      ${lib.getExe waitOnline}

      # This unit is the one that leaked the lock on 2026-09-05, and nothing
      # downstream of a failed check ever cleans up after it. Same reasoning as
      # the backup's prepare step.
      ${lib.getExe resticUnlock} || true

      # Run integrity check with 1% data sampling.
      #
      # --retry-lock waits out a live lock (a long backup) instead of failing
      # instantly, which is restic's default.
      #
      # A caveat for whoever reads a future failure: when the transport dies
      # mid-check, the truncated `List(data)` makes restic report nearly every
      # pack as "does not exist" and conclude "The repository is damaged and
      # must be repaired". On 2026-09-05 that was 8771 of ~9282 packs, all of
      # them accompanied by `ssh command exited: exit status 255`. Confirm with
      # a clean-network re-run before believing it.
      /run/wrappers/bin/restic check \
        --read-data-subset=1% \
        --retry-lock 10m \
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
