{ pkgs, lib, ... }:

{
  # PC/SC daemon - required for smart card communication (YubiKey PIV/OpenPGP)
  services.pcscd.enable = true;

  # YubiKey udev rules for proper device permissions
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # YubiKey management tools
  environment.systemPackages = with pkgs; [
    yubikey-manager # ykman CLI tool
  ];

  # SOPS age configuration for YubiKey-based decryption
  sops.age.keyFile = "/home/bogdan/.config/sops/age/keys.txt";

  # Activation script to prepare YubiKey environment for sops-nix
  # See: https://github.com/Mic92/sops-nix/issues/377
  system.activationScripts.setupYubikeyForSopsNix.text = ''
    PATH=$PATH:${lib.makeBinPath [ pkgs.age-plugin-yubikey ]}

    # Setup PCSC drivers symlink
    ${pkgs.runtimeShell} -c "mkdir -p /var/lib/pcsc && ln -sfn ${pkgs.ccid}/pcsc/drivers /var/lib/pcsc/drivers"

    # Only start pcscd if not already running (preserves GPG scdaemon connections)
    if ! ${pkgs.toybox}/bin/pgrep -x pcscd > /dev/null; then
      ${pkgs.pcsclite}/bin/pcscd
    fi
  '';

  # Ensure setupSecrets runs after YubiKey environment is ready
  system.activationScripts.setupSecrets.deps = [ "setupYubikeyForSopsNix" ];
}
