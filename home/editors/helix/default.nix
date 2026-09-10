{ pkgs, lib, ... }:

{
  # Helix resolves tree-sitter queries by language *name* (not grammar), so the
  # custom github-actions language below needs query stubs that delegate to the
  # bundled yaml ones. ~/.config/helix/runtime is searched before the bundled
  # runtime, per file.
  xdg.configFile =
    lib.genAttrs
      (map (q: "helix/runtime/queries/github-actions/${q}.scm") [
        "highlights"
        "injections"
        "indents"
        "textobjects"
      ])
      (_: {
        text = "; inherits: yaml\n";
      });

  programs.helix = {
    enable = true;

    # Sets EDITOR and VISUAL to `hx` via home.sessionVariables. Nothing else may
    # define those (home/terminal/default.nix used to set EDITOR = "nvim") — the
    # option is a plain definition, so a second one is an eval conflict.
    defaultEditor = true;

    # Noctalia declares and reloads the theme through ./noctalia.nix.
    settings = {
      editor = {
        line-number = "relative";
        cursorline = true;
        color-modes = true;
        true-color = true;
        undercurl = true;
        bufferline = "multiple";
        popup-border = "all";
        indent-guides.render = true;

        statusline = {
          left = [
            "mode"
            "spinner"
            "version-control"
            "file-name"
            "file-modification-indicator"
          ];
          right = [
            "diagnostics"
            "selections"
            "position"
            "file-encoding"
            "file-type"
          ];
        };

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        lsp.display-messages = true;
        end-of-line-diagnostics = "hint";
        inline-diagnostics.cursor-line = "warning";
      };

      keys = {
        insert.j.k = "normal_mode";

        normal = {
          # Telescope muscle memory: <C-p> files, <C-f> grep.
          C-p = "file_picker";
          C-f = "global_search";

          # NvChad muscle memory: direct window nav without the C-w prefix.
          # Pickers/completion menus are NOT remappable (hardcoded), but C-n/C-p
          # already navigate those — arrows are never required.
          C-h = "jump_view_left";
          C-j = "jump_view_down";
          C-k = "jump_view_up";
          C-l = "jump_view_right";

          # NvChad <leader>x: close current buffer. (Tab/S-Tab buffer cycling
          # is NOT ported — Tab aliases C-i, the tier-2 jumplist-forward key,
          # in terminals without the kitty keyboard protocol; use gn/gp.)
          space.x = ":buffer-close";

          # Jujutsu menu, mirroring the nvim <leader>j group. On Space-v (vcs),
          # NOT Space-j — that's the built-in jumplist picker, tier 2 of the
          # vim-be-fast navigation hierarchy. :sh output lands in a
          # (plain-text) popup; anything interactive — describe, split,
          # squash -i — is jjui's job in another pane.
          # Popups are for orientation only; reading a diff properly is the
          # changed-file picker (Space-g) + ]g/[g hunk hops, or jjui.
          space.v = {
            j = ":sh jj st";
            l = ":sh jj log -n 15";
            d = ":sh jj diff";
            s = ":sh jj diff --stat";
            D = ":sh jj diff -r @-";
            n = [
              ":sh jj new"
              ":reload-all"
            ];
            p = ":sh jj git push";
            r = ":reload-all";
          };
        };
      };
    };

    languages = {
      language-server = {
        gopls.config = {
          gofumpt = true;
          staticcheck = true;
          analyses.unusedparams = true;
        };

        pyright = {
          command = "pyright-langserver";
          args = [ "--stdio" ];
          config.python.analysis = {
            autoSearchPaths = true;
            typeCheckingMode = "basic";
          };
        };

        # ruff's LSP also provides formatting, so python auto-format goes
        # through it (pyright advertises no formatter capability).
        ruff = {
          command = "ruff";
          args = [ "server" ];
        };

        nil.config.nil.formatting.command = [ "nixfmt" ];

        gh-actions-ls = {
          command = "gh-actions-language-server";
          args = [ "--stdio" ];
        };
      };

      language = [
        {
          name = "go";
          auto-format = true;
          # Just gopls — drop helix's default golangci-lint-lsp, which isn't
          # part of the nvim roster and would health-warn as missing.
          language-servers = [ "gopls" ];
        }
        {
          name = "python";
          language-servers = [
            "pyright"
            "ruff"
          ];
          auto-format = true;
        }
        {
          name = "nix";
          auto-format = true;
        }
        {
          name = "lua";
          auto-format = true;
          formatter = {
            command = "stylua";
            args = [ "-" ];
          };
        }
        {
          name = "typescript";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "typescript"
            ];
          };
        }
        {
          name = "tsx";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "typescript"
            ];
          };
        }
        {
          name = "javascript";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "babel"
            ];
          };
        }
        {
          name = "css";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "css"
            ];
          };
        }
        {
          name = "html";
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "html"
            ];
          };
        }
        {
          name = "json";
          auto-format = true;
          formatter = {
            command = "jq";
          };
        }
        {
          name = "markdown";
          soft-wrap.enable = true;
        }
        {
          name = "hcl";
          auto-format = true;
        }
        {
          name = "tfvars";
          auto-format = true;
        }
        {
          name = "zig";
          auto-format = true;
        }
        {
          name = "templ";
          auto-format = true;
        }

        # Workflow files get the actions server on top of plain yaml-ls,
        # matching the gh_actions_ls setup in nvim's lspconfig.
        {
          name = "github-actions";
          scope = "source.yaml";
          grammar = "yaml";
          comment-token = "#";
          file-types = [
            { glob = ".github/workflows/*.yml"; }
            { glob = ".github/workflows/*.yaml"; }
          ];
          language-servers = [
            "yaml-language-server"
            "gh-actions-ls"
          ];
        }
      ];
    };

    # On hx's wrapper PATH only, not the global profile — same roster as
    # nvim's extraPackages.
    extraPackages = with pkgs; [
      # go
      go
      gopls

      # python
      pyright
      ruff

      # nix
      nil
      nixfmt

      # lua
      lua-language-server
      stylua

      # web
      typescript-language-server
      vscode-langservers-extracted
      prettier

      # markdown
      marksman

      # yaml + github actions
      yaml-language-server
      gh-actions-language-server

      # terraform
      terraform-ls

      # zig
      zls

      # templ
      templ

      # toml
      taplo

      # json formatter
      jq
    ];
  };
}
