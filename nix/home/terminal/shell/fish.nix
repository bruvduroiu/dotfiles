{ pkgs, ... }:

{
  programs = {
    fish = {
      enable = true;
      shellAliases = {
        l = "ls -lah";
        vim = "nvim";
        vimdiff = "nvim -d";
        gs = "git status --short";
        gll = "git log --graph --oneline --all";
        k = "kubectl";
        tf = "terraform";
        tfi = "terraform init";
        tfp = "terraform plan";
        tfa = "terraform apply";
      };

      shellInit = ''
        # Keyboard repeat (equivalent to macOS defaults write)
        # This would need to be handled differently on Linux

        # Environment variables
        set -x PATH /home/bogdan/development/tools/tools/bin $PATH
        set -x KUBE_CONFIG_PATH ~/.kube/config
      '';

      interactiveShellInit = ''
        if status is-interactive
            # Commands to run in interactive sessions can go here
        end
      '';
    };
  };
}
