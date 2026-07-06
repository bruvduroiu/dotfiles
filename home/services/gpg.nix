{ pkgs, ... }:

{
  services.gpg-agent = {
    enable = true;
    # Cache passphrases for 1 hour
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
    # Use Qt pinentry for GUI prompts (works with vim-fugitive on Hyprland)
    pinentry.package = pkgs.pinentry-qt;
    # Enable SSH support via GPG agent (uses YubiKey for SSH auth)
    enableSshSupport = true;
    # Cache SSH keys for 1 hour
    defaultCacheTtlSsh = 3600;
    # YubiKey authentication subkey keygrips for SSH
    sshKeys = [
      "139C66F1D36546BFD8FBBE5570384F1130CDFE6E" # YubiKey 2 (5C NFC) auth key - 0x05AB33B50A345D4D
      "F25F34CF85F685E5C1B0DE428B8A7228EBDB03E5" # YubiKey 1 (NEO) auth key - 0x6D916A825C88D51F
    ];
  };
}

