{ pkgs, ... }:

{
  # PC/SC daemon - required for smart card communication (YubiKey PIV/OpenPGP)
  services.pcscd.enable = true;

  # YubiKey udev rules for proper device permissions
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # YubiKey management tools
  environment.systemPackages = with pkgs; [
    yubikey-manager # ykman CLI tool

    # Attach phantom's LUKS volume from THIS running machine. Lives here
    # rather than in system/phantom/ on purpose: it is needed on the host
    # doing the provisioning, not on phantom itself, which unlocks from its
    # own initrd. `cryptsetup open` cannot read the FIDO2 token and degrades
    # silently to a passphrase prompt — see pkgs/phantom-unlock.nix.
    phantom-unlock
  ];
}
