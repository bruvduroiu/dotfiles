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

      cert-digest-algo = "SHA512";

      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";

      charset = "utf-8";

      no-comments = "";
      no-emit-version = "";
      no-greeting = "";

      # Show fingerprints
      keyid-format = "0xlong";
      with-fingerprint = "";

      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";

      # Ensure cross-certification on subkeys
      require-cross-certification = "";

      require-secmem = "";
      no-symkey-cache = "";
      armor = "";

      use-agent = "";

      # Disable recipient key ID in messages (privacy)
      throw-keyids = "";

      # Default signing key (master key - GPG auto-selects signing subkey from inserted YubiKey)
      default-key = "0x785150ECAABF7352";

      # When encrypting, always include yourself as a recipient
      default-recipient-self = "";
    };

    # Smart card daemon settings for YubiKey
    scdaemonSettings = {
      # Disable CCID driver to let PC/SC handle it
      disable-ccid = true;
      # Use PC/SC for card access
      pcsc-driver = "${pkgs.pcsclite.lib}/lib/libpcsclite.so";
      # NOT pcsc-shared: shared mode re-selects the OpenPGP applet before every
      # command, which clears the card's verified-PIN state — so "PIN once"
      # became a PIN prompt per signature and per SSH auth. Exclusive mode
      # keeps the card unlocked for the scdaemon session; sops (PIV via
      # age-plugin-yubikey) gets the card by killing scdaemon first — see
      # home/services/gpg.nix and system/core/sops.nix.
    };
  };
  home.packages = [ pkgs.gnupg ];
}
