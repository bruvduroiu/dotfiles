{ config, lib, pkgs, ... }:

let
  # The late decrypt below only exists where the card is reachable after boot
  # and there is something to decrypt: with no system secrets (phantom)
  # sops-nix defines no setupSecrets to re-run.
  lateDecrypt = config.services.pcscd.enable && config.sops.secrets != { };
  consumers = config.yubikeySops.consumers;
in {
  options.yubikeySops.consumers = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    example = { "wg-quick-wg0" = "/run/secrets/wg-private-key"; };
    description = ''
      Services that read a secret once, at start, mapped to the file they
      need. Each is ordered after sops-install-secrets-yubikey, skipped
      (ConditionPathExists) while the file is missing, and started once a late
      decrypt succeeds. Timer-driven units belong in plain after/wants
      instead: a late start would fire them off-schedule.
    '';
  };

  config = {
    # Global SOPS configuration for system-level secrets
    # Decryption via YubiKey age identity (PIN/touch policy: never), so the
    # key must be inserted at boot/rebuild; no software age key on disk
    sops.age.keyFile = "/home/bogdan/.config/sops/age/keys.txt";
    sops.age.plugins = [ pkgs.age-plugin-yubikey ];

    # A user's scdaemon holds the YubiKey exclusively (no pcsc-shared, so the
    # OpenPGP PIN stays verified), which would lock age-plugin-yubikey out of
    # PIV. Kill it before decrypting; gpg-agent respawns it on demand.
    system.activationScripts.releaseYubikeyForSops = ''
      ${pkgs.procps}/bin/pkill -x scdaemon || true
    '';
    # Gated: a bare `.deps` on a host with no system secrets (phantom) creates
    # a setupSecrets entry with no text, which fails evaluation.
    system.activationScripts.setupSecrets = lib.mkIf (config.sops.secrets != { }) {
      deps = [ "releaseYubikeyForSops" ];
    };

    systemd.services = lib.mkIf lateDecrypt (
      # The boot-time setupSecrets runs in the initrd, where there is no
      # pcscd, so age-plugin-yubikey never sees the card and it ALWAYS fails
      # ("0 successful groups required, got 0"): /run/secrets stays empty
      # until the next switch. Re-run the identical install once pcscd is
      # reachable, retrying until the key is inserted.
      {
        sops-install-secrets-yubikey = {
          description = "Decrypt sops secrets once the YubiKey is reachable";
          wantedBy = [ "multi-user.target" ];
          wants = [ "pcscd.socket" ];
          after = [ "pcscd.socket" ];
          # Retry forever: a key inserted an hour after boot should still work.
          unitConfig.StartLimitIntervalSec = 0;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "10s";
            TimeoutStartSec = "60s";
          } // lib.optionalAttrs (consumers != { }) {
            # On the normal path these start jobs merge with the boot
            # transaction's; after a late success they bring up consumers
            # whose condition failed at boot.
            ExecStartPost = "${config.systemd.package}/bin/systemctl --no-block start "
              + lib.concatMapStringsSep " " (n: "${n}.service") (lib.attrNames consumers);
          };
          script = ''
            ${pkgs.procps}/bin/pkill -x scdaemon || true
            ${config.system.activationScripts.setupSecrets.text}
          '';
        };
      }
      # Without the condition a consumer starting keyless reports active
      # while broken (wg-quick: routes up, no identity, every packet dropped).
      // lib.mapAttrs (_: path: {
        wants = [ "sops-install-secrets-yubikey.service" ];
        after = [ "sops-install-secrets-yubikey.service" ];
        unitConfig.ConditionPathExists = path;
      }) consumers
    );
  };
}
