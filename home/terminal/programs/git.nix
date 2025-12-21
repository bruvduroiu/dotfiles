{ config, ... }:

{
  programs.git = {
    enable = true;

    ignores = [ ".swp" ];

    # GPG signing with local subkey (! suffix forces this specific key over YubiKey subkey)
    signing = {
      key = "E3D1D113ED046C36!";
      signByDefault = true;
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
