{ config, inputs, ... }:

{
  programs.git = {
    enable = true;

    ignores = [ ".swp" ];

    # GPG signing with YubiKey (master key - auto-selects signing subkey from inserted YubiKey)
    signing = {
      key = "0x785150ECAABF7352";
      signByDefault = true;
    };

    settings = {
      user = {
        name = "Bogdan Buduroiu";
        email = inputs.secrets.vars.identity.email;
      };

      aliases = let
        log = "log";
      in {
        a = "add --patch";
      };

      diff.colorMoved = "default";
      merge.conflictStyle = "diff3";

      pull.rebase = true;

      url."https://github.com/anthropics/".insteadOf = "ssh://git@github.com/anthropics/";
    };
  };
}
