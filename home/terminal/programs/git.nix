{ config, ... }: let
  cfg = config.programs.git;
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJSSumawcqD5McYyYcwPKuhKouMnR0Fy4B+lDhMAfuH bogdan@nixos";
in {
  programs.git = {
    enable = true;

    ignores = [ ".swp" ];

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519";
      signByDefault = true;
      format = "ssh";
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

      gpg.ssh.allowedSignersFile = config.home.homeDirectory + "/" + config.xdg.configFile."git/allowed_signers".target;
      pull.rebase = true;
    };
  };

  xdg.configFile."git/allowed_signers".text = ''
    ${cfg.settings.user.email} namespaces="git" ${key}
  '';
}
