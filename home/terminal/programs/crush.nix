{ config, pkgs, inputs, ... }:

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
        "terraform": {
          "type": "stdio",
          "command": "${pkgs.terraform-mcp-server}/bin/terraform-mcp-server",
          "args": []
        },
        "playwright": {
          "type": "stdio",
          "command": "${pkgs.playwright-mcp}/bin/mcp-server-playwright",
          "args": [
            "--executable-path",
            "${pkgs.ungoogled-chromium}/bin/chromium"
          ],
          "env": {}
        },
        "sequential-thinking": {
          "type": "stdio",
          "command": "${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking",
          "args": [],
          "env": {}
        },
        "deepwiki": {
          "type": "http",
          "url": "https://mcp.deepwiki.com/mcp"
        },
        "nixos": {
          "type": "stdio",
          "command": "${pkgs.nix}/bin/nix",
          "args": ["run", "github:utensils/mcp-nixos", "--"]
        }
      },
      "lsp": {
        "go": {
          "disabled": false,
          "command": "${pkgs.gopls}/bin/gopls"
        },
        "typescript": {
          "disabled": false,
          "command": "${pkgs.typescript-language-server}/bin/typescript-language-server",
          "args": ["--stdio"]
        },
        "python": {
          "disabled": false,
          "command": "${pkgs.pyright}/bin/pyright-langserver"
        },
        "terraform": {
          "disabled": false,
          "command": "${pkgs.terraform-ls}/bin/terraform-ls",
          "args": ["serve"]
        },
        "nix": {
          "command": "${pkgs.nil}/bin/nil"
        },
        "markdown": {
          "command": "${pkgs.markdown-oxide}/bin/markdown-oxide"
        },
        "yaml": {
          "command": "${pkgs.yaml-language-server}/bin/yaml-language-server",
          "arg": ["--stdio"]
        }
      },
      "debug": false,
      "debugLSP": false,
      "autoCompact": true
    }
  '';

  home.packages = with pkgs.nur.repos.charmbracelet; [
    crush
  ];
}
