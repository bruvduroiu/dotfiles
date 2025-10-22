{ config, pkgs, inputs, ... }:

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
        }
      },
      "agents": {
        "coder": {
          "model": "anthropic/claude-sonnet-4",
          "maxTokens": 5000
        },
        "task": {
          "model": "anthropic/claude-sonnet-4",
          "maxTokens": 5000
        },
        "title": {
          "model": "anthropic/claude-3.5-haiku",
          "maxTokens": 80
        }
      },
      "shell": {
        "path": "${config.programs.fish.package}/bin/fish",
        "args": ["-l"]
      },
      "mcp": {
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
        }
      },
      "lsp": {
        "go": {
          "disabled": false,
          "command": "${pkgs.gopls}/bin/gopls"
        },
        "typescript": {
          "disabled": false,
          "command": "${pkgs.typescript-language-server}/bin/typescript-language-server --stdio"
        },
        "python": {
          "disabled": false,
          "command": "${pkgs.pyright}/bin/pyright"
        },
        "terraform": {
          "disabled": false,
          "command": "${pkgs.terraform-lsp}/bin/terraform-lsp"
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
