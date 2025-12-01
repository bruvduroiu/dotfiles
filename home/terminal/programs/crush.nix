{ config, pkgs, inputs, ... }:


  # "playwright": {
  #   "type": "stdio",
  #   "command": "${pkgs.playwright-mcp}/bin/mcp-server-playwright",
  #   "args": [
  #     "--executable-path",
  #     "${pkgs.ungoogled-chromium}/bin/chromium"
  #   ],
  #   "env": {}
  # },

let
  uvxPath = "${pkgs.uv}/bin/uvx";
  npxPath = "${pkgs.nodejs_24}/bin/npx";
in 
{
  home.file."${config.home.homeDirectory}/.config/crush/crush.json".text = ''
    {
      "$schema": "https://charm.land/crush.json",
      "data": {
        "directory": ".crush"
      },
      "providers": {
        "openai": {
          "disabled": true
        },
        "anthropic": {
          "disabled": true
        },
        "copilot": {
          "disabled": true
        },
        "groq": {
          "disabled": true
        },
        "openrouter": {
          "disabled": false
        },
        "zai": {
          "disabled": false,
          "api-key": "$ANTHROPIC_AUTH_TOKEN"
        }
      },
      "agents": {
        "coder": {
          "model": "zai/glm-4.6",
          "maxTokens": 5000
        },
        "task": {
          "model": "zai/glm-4.6",
          "maxTokens": 5000
        },
        "title": {
          "model": "zai/glm-4.5-air",
          "maxTokens": 80
        }
      },
      "shell": {
        "path": "${config.programs.fish.package}/bin/fish",
        "args": ["-l"]
      },
      "mcp": {
        "fetch": {
          "type": "stdio",
          "command": "${uvxPath}",
          "args": ["mcp-server-fetch"]
        },
        "deepwiki": {
          "type": "http",
          "url": "https://mcp.deepwiki.com/mcp"
        }
      },
      "lsp": {
        "go": {
          "disabled": false,
          "command": "${pkgs.gopls}/bin/gopls",
          "filetypes": ["go", "gomod", "gowork"],
          "root_markers": ["go.mod", "go.work"]
        },
        "typescript": {
          "disabled": false,
          "command": "${pkgs.typescript-language-server}/bin/typescript-language-server",
          "args": ["--stdio"],
          "filetypes": ["js", "jsx", "ts", "tsx", "mdx"],
          "root_markers": ["package.json", "tsconfig.json", "jsconfig.json"]
        },
        "python": {
          "disabled": false,
          "command": "${pkgs.ruff}/bin/ruff",
          "args": ["server", "-s"],
          "filetypes": ["py"],
          "root_markers": ["pyproject.toml", "setup.py", "setup.cfg", "requirements.txt"]
        },
        "terraform": {
          "disabled": false,
          "command": "${pkgs.terraform-ls}/bin/terraform-ls",
          "args": ["serve"],
          "filetypes": ["terraform", "tf", "hcl"],
          "root_markers": [".terraform", "terraform.tfvars"]
        },
        "nix": {
          "command": "${pkgs.nil}/bin/nil",
          "filetypes": ["nix"],
          "root_markers": ["flake.nix", "flake.lock", "default.nix", "shell.nix"]
        },
        "markdown": {
          "command": "${pkgs.markdown-oxide}/bin/markdown-oxide",
          "filetypes": ["markdown", "md"],
          "root_markers": [".markdownlint.json", ".markdownlintrc"]
        },
        "github-actions": {
          "command": "${pkgs.gh-actions-language-server}/bin/gh-actions-language-server",
          "args": ["--stdio"],
          "filetypes": ["yaml"],
          "root_markers": [".github/workflows"],
          "init_options": {
            "workspace": {
              "didChangeWorkspaceFolders": {
                "dynamicRegistration": true
              }
            }
          }
        }
      },
      "debug": false,
      "debugLSP": true,
      "autoCompact": true
    }
  '';

  home.packages = with pkgs.nur.repos.charmbracelet; [
    crush
  ];
}
