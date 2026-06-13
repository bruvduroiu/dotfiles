{ pkgs, ... }:

{
  # Global SOPS configuration for system-level secrets
  # Decryption via YubiKey age identity (PIN/touch policy: never), so the
  # key must be inserted at boot/rebuild; no software age key on disk
  sops.age.keyFile = "/home/bogdan/.config/sops/age/keys.txt";
  sops.age.plugins = [ pkgs.age-plugin-yubikey ];
}
