{ config, pkgs, ... }: let
  data = config.xdg.dataHome;
  conf = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in {
  imports = [
    ./programs
    ./shell/fish.nix
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    # Use pinentry-qt for age-plugin-yubikey (PIV) PIN prompts
    PINENTRY_PROGRAM = "${pkgs.pinentry-qt}/bin/pinentry-qt";
    # Explicit path to age keys for SOPS (needed for YubiKey plugin discovery)
    SOPS_AGE_KEY_FILE = "${conf}/sops/age/keys.txt";
  };
}
