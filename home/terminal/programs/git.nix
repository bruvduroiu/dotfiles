{ config, ... }:

{
  programs.git = {
    enable = true;

    ignores = [ ".swp" ];

    # GPG signing with master key (uses local key or YubiKey subkey automatically)
    signing = {
      key = "5CB2BEDC031471D8";
      signByDefault = true;
      # format defaults to "openpgp" so we don't need to specify it
    };

    settings = {
      user = {
        name = "Bogdan Buduroiu";
        email = "bogdan@buduroiu.com";
      };

      aliases = let
        log = "log";
      in {
        a = "add --patch";
      };

      diff.colorMoved = "default";
      merge.conflictStyle = "diff3";

      pull.rebase = true;
    };
  };
}
