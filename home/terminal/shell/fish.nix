{
  config,
  lib,
  pkgs,
  ...
}:
let
  eza_opts = lib.strings.concatStringsSep " " config.programs.eza.extraOptions;
  fd_opts = lib.strings.concatStringsSep " " [ "--hidden" ];
  delta_opts = lib.strings.concatStringsSep " " [ "--paging=never" ];

  # Helix-style modal editing for the fish command line. Not in nixpkgs, and it
  # needs no build step — home-manager's `plugins` option only ever prepends
  # $src/functions to $fish_function_path, and this repo ships nothing else.
  # main targets fish >= 4 (there are 3.4/3.6 branches if we ever downgrade).
  # Runtime deps are perl + coreutils/gnused, both guaranteed by NixOS'
  # environment.defaultPackages / system path.
  fish-helix = pkgs.fetchFromGitHub {
    owner = "sshilovsky";
    repo = "fish-helix";
    rev = "c9487ea37dafee157cefb8a89c145bc98d21fd6b";
    hash = "sha256-JqN4IbLpJFBJKNE6haZH2iFSMrLFdVh+Hbl840+xbfU=";
  };
in

{
  programs = {
    fish = {
      enable = true;
      plugins = [
        {
          name = "done";
          src = pkgs.fishPlugins.done.src;
        }
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
        {
          name = "forgit";
          src = pkgs.fishPlugins.forgit.src;
        }
        {
          name = "hydro";
          src = pkgs.fishPlugins.hydro.src;
        }
        {
          name = "fzf";
          src = pkgs.fishPlugins.fzf.src;
        }
        {
          name = "fish-helix";
          src = fish-helix;
        }
      ];
      shellInit = ''
        if test -f ${config.sops.secrets.openrouter_api_key.path}
          set -gx OPENROUTER_API_KEY (cat ${config.sops.secrets.openrouter_api_key.path})
        end
        if test -f ${config.sops.secrets.deepseek_api_key.path}
          set -gx DEEPSEEK_API_KEY (cat ${config.sops.secrets.deepseek_api_key.path})
        end
        if test -f ${config.sops.secrets.alphavantage_api_key.path}
          set -gx ALPHAVANTAGE_API_KEY (cat ${config.sops.secrets.alphavantage_api_key.path})
        end
        if test -f ${config.sops.secrets.abliteration_api_key.path}
          set -gx ABLITERATION_API_KEY (cat ${config.sops.secrets.abliteration_api_key.path})
        end
      '';
      interactiveShellInit = ''
        set -gx fzf_fd_opts "${fd_opts}"
        set -gx fzf_preview_dir_cmd "${pkgs.eza}/bin/eza ${eza_opts}"
        set -gx fzf_diff_highlighter "${pkgs.delta}/bin/delta ${delta_opts}"

        # GPG needs to know the TTY for pinentry
        set -gx GPG_TTY (tty)

        # Helix modal editing on the command line. Only sets the variable —
        # fish installs the bindings itself (and then calls
        # fish_user_key_bindings) from __fish_config_interactive, which is
        # deferred to the first prompt, i.e. after this file has been read.
        set -g fish_key_bindings fish_helix_key_bindings
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
      # jj-first daily drivers. Abbreviations, not aliases: they expand
      # in-place, so history records the real command. The git aliases above
      # stay for non-jj repos but are legacy.
      shellAbbrs = {
        js = "jj st";
        jl = "jj log";
        jd = "jj diff";
        jdt = "jj dt"; # difftastic skim pass (see jj.nix merge-tools.difft)
        jsp = "jj split";
        jn = "jj new";
      };
      functions = {
        # Re-applied by fish every time $fish_key_bindings changes, right after
        # the bindings function has run. fish_helix_key_bindings erases the
        # preset bindings, so layering ours on from here (rather than from
        # interactiveShellInit) keeps them in place across a mode switch.
        fish_user_key_bindings = ''
          fzf_configure_bindings --directory=\cp --processes=\co

          # Alt+O to open last command output in $EDITOR
          bind -M insert \eo edit-output
          bind -M default \eo edit-output

          # Alt+V drops the command line into real Helix. fish-helix implements
          # motions and select->act, but has no match/surround support at all
          # (no `mi(`, `ma(`, `mr'"`, `ms`) and no multiple cursors, so anything
          # structural on a long command is done here instead.
          # edit_command_buffer is fish's builtin and honours VISUAL, so this
          # needs no wrapper function of its own. Since VISUAL is now hx too
          # (programs.helix.defaultEditor), Alt+E lands in the same editor; the
          # explicit binding stays so it holds if the default ever changes.
          for mode in insert default visual
            bind -M $mode \ev "VISUAL=${config.programs.helix.package}/bin/hx edit_command_buffer"
          end
        '';
        fish_prompt = ''
          if [ $status = 0 ] 
            set_color green
          else
            set_color red
          end

          set -l nix_shell_info (
            if test -n "$IN_NIX_SHELL"
              echo -n "<nix-shell> "
            end
          )

          echo -n -s "$nix_shell_info ≫"

          set_color normal
          echo -n ' '
        '';
        jss = ''
          jj log -r 'trunk()..@' --no-graph \
            -T 'commit_id.short() ++ " " ++ description.first_line() ++ "\n"' $argv
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
        edit-output = ''
          set -l last_cmd (history --max=1)
          set -l tmpfile (mktemp)
          eval $last_cmd > $tmpfile 2>&1
          eval $EDITOR $tmpfile
          rm $tmpfile
        '';
      };
    };
  };
}
