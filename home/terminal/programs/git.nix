{ config, ... }: let
  cfg = config.programs.git;
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJSSumawcqD5McYyYcwPKuhKouMnR0Fy4B+lDhMAfuH bogdan@nixos";
in {
  programs.git = {
    enable = true;

    delta = {
      enable = true;
      options.dark = true;
    };

    extraConfig = {
      diff.colorMoved = "default";
      merge.conflictStyle = "diff3";

      gpg.ssh.allowedSignersFile = config.home.homeDirectory + "/" + config.xdg.configFile."git/allowed_signers".target;
      pull.rebase = true;
    };

    aliases = let
      log = "log";
    in {
      a = "add --patch";
    };

    ignores = [ ".swp" ];

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519";
      signByDefault = true;
      format = "ssh";
    };

    userName = "Bogdan Buduroiu";
    userEmail = "bogdan@buduroiu.com";
  };

  xdg.configFile."git/allowed_signers".text = ''
    ${cfg.userEmail} namespaces="git" ${key}
  '';
}
