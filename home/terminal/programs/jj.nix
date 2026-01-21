{ config, pkgs, ... }:

{
  programs.jujutsu = {
    enable = true;
    package = pkgs.jujutsu;

    settings = {
      user = {
        name = "Bogdan Buduroiu";
        email = "bogdan@buduroiu.com";
      };

      # GPG signing with YubiKey (same key as git - auto-selects signing subkey)
      signing = {
        behavior = "own";
        backend = "gpg";
        key = "0x785150ECAABF7352";
      };

      ui = {
        # Use delta for diffs (consistent with git delta integration)
        diff-formatter = [ "delta" "--color-only" ];
        pager = "delta";
      };

      # Git backend settings
      git = {
        auto-local-bookmark = true;
      };
    };
  };
}
