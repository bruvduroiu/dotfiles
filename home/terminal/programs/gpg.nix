{ pkgs, ... }:

{
  programs.gpg = {
    enable = true;
    # Use standard GPG settings
    settings = {
      # Use AES256 for symmetric encryption
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";

      # Show fingerprints
      keyid-format = "0xlong";
      with-fingerprint = true;

      # Ensure cross-certification on subkeys
      require-cross-certification = true;

      # Disable recipient key ID in messages (privacy)
      throw-keyids = true;
    };

    # Smart card daemon settings for YubiKey
    scdaemonSettings = {
      # Disable CCID driver to let PC/SC handle it
      disable-ccid = true;
      # Use PC/SC for card access
      pcsc-driver = "${pkgs.pcsclite.lib}/lib/libpcsclite.so";
    };
  };

  services.gpg-agent = {
    enable = true;
    # Cache passphrases for 1 hour
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
    # Use Qt pinentry for GUI prompts (works with vim-fugitive on Hyprland)
    pinentryPackage = pkgs.pinentry-qt;
    # Enable SSH support via GPG agent (uses YubiKey for SSH auth)
    enableSshSupport = true;
    # Cache SSH keys for 1 hour
    defaultCacheTtlSsh = 3600;
    # YubiKey authentication subkey keygrips for SSH
    sshKeys = [
      "3748A17C69FBACA0259B66B6795BA123A88EEED5" # YubiKey 2 (5C NFC) auth key
      "21A566C9A90665240DDDEDC731690605AC8794C6" # YubiKey 1 (NEO) auth key
    ];
  };
}
