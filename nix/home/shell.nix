{ config, pkgs, ... }:

{
  programs.fish = {
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
      li = "linode-cli";
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

  # Copy your fish config files
  home.file.".config/fish/config.fish".source = ../../config/fish/config.fish;
  
  # Copy fish functions and completions
  home.file.".config/fish/functions" = {
    source = ../../config/fish/functions;
    recursive = true;
  };
  
  home.file.".config/fish/completions" = {
    source = ../../config/fish/completions;
    recursive = true;
  };
}
