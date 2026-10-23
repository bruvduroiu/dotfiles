{ pkgs, ... }:

{
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
  system.activationScripts.setupSecrets.deps = [ "releaseYubikeyForSops" ];
}
