{ config, pkgs, ... }:

let
  openrouterApiKey = builtins.getEnv "OPENROUTER_API_KEY";
in 
{
  home.file."${config.home.homeDirectory}/.opencode.json".text = ''
    {
      "data": {
        "directory": ".opencode"
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
          "apiKey": "${openrouterApiKey}",
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
      "mcpServers": { },
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
        }
      },
      "debug": false,
      "debugLSP": false,
      "autoCompact": true
    }
  '';

  home.packages = with pkgs; [
    opencode
  ];
}
