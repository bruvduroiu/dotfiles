{ pkgs, ... }:

{
  # PC/SC daemon - required for smart card communication (YubiKey PIV/OpenPGP)
  services.pcscd.enable = true;

  # YubiKey udev rules for proper device permissions
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # YubiKey management tools
  environment.systemPackages = with pkgs; [
    yubikey-manager # ykman CLI tool
  ];
}
