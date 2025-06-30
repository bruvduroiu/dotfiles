{ pkgs, ... }:

{
  programs = {
    fish = {
      enable = true;
      plugins = [
        { name = "done"; src = pkgs.fishPlugins.done.src; }
        { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
        { name = "forgit"; src = pkgs.fishPlugins.forgit.src; }
        { name = "hydro"; src = pkgs.fishPlugins.hydro.src; }
        { name = "fzf"; src = pkgs.fishPlugins.fzf.src; }
      ];
      interactiveShellInit = ''
        fzf_configure_bindings --directory=\cp --processes=\co
      '';
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
      functions = {
        fish_prompt = ''
          if [ $status = 0 ] 
            set_color green
          else
            set_color red
          end

          echo -n '≫'

          set_color normal
          echo -n ' '
        '';
        gdt = ''
          git diff-tree --no-commit-id --name-only -r $argv
        '';
        gdv = ''
          git diff -w $argv | view -
        '';
        ggl = ''
          git pull origin (__git.current_branch) $argv
        '';
        ggp = ''
          git push origin (__git.current_branch) $argv
        '';
        ggpnp = ''
          set -l current_branch (__git.current_branch)
          and git pull origin $current_branch
          and git push origin $current_branch
        '';
        ggsup = ''
          git branch --set-upstream-to=origin/(__git.current_branch)
        '';
        ggu = ''
          git pull --rebase origin (__git.current_branch)
        '';
        gbage = ''
          git for-each-ref --sort=committerdate refs/heads/ \
            --format="%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))"
        '';
        gbda = ''
          git branch --merged | \
            command grep -vE  '^\*|^\s*(master|main|develop)\s*$' | \
            command xargs -n 1 git branch -d
        '';
      };
    };
  };
}
