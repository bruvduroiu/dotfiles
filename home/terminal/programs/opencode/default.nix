{ config, pkgs, ... }:

let
  uvxPath = "${pkgs.uv}/bin/uvx";
in
{
  home.file."${config.home.homeDirectory}/.config/opencode/opencode.json".text = ''
    {
      "$schema": "https://opencode.ai/config.json",
      "model": "z.ai/glm-4.6",
      "autoshare": false,
      "mcp": {
        "fetch": {
          "type": "local",
          "command": ["${uvxPath}", "mcp-server-fetch"],
          "enabled": true
        },
        "terraform": {
          "type": "local",
          "command": ["${pkgs.terraform-mcp-server}/bin/terraform-mcp-server"],
          "enabled": true
        },
        "playwright": {
          "type": "local",
          "command": ["${pkgs.playwright-mcp}/bin/mcp-server-playwright", "--executable-path", "chromium"],
          "enabled": true
        },
        "sequential-thinking": {
          "type": "local",
          "command": ["${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking"],
          "enabled": true
        },
        "deepwiki": {
          "type": "remote",
          "url": "https://mcp.deepwiki.com/mcp",
          "enabled": true
        },
        "nixos": {
          "type": "local",
          "command": ["${pkgs.nix}/bin/nix", "run", "github:utensils/mcp-nixos", "--"],
          "enabled": true
        }
      },
      "lsp": {
        "go": {
          "command": ["${pkgs.gopls}/bin/gopls"],
          "extensions": [".go"]
        },
        "typescript": {
          "command": ["${pkgs.typescript-language-server}/bin/typescript-language-server", "--stdio"],
          "extensions": [".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts"]
        },
        "python": {
          "command": ["${pkgs.ruff}/bin/ruff", "server", "-s"],
          "extensions": [".py", ".pyi"]
        },
        "terraform": {
          "command": ["${pkgs.terraform-ls}/bin/terraform-ls", "serve"],
          "extensions": [".tf", ".tfvars"]
        },
        "nix": {
          "command": ["${pkgs.nil}/bin/nil"],
          "extensions": [".nix"]
        },
        "markdown": {
          "command": ["${pkgs.markdown-oxide}/bin/markdown-oxide"],
          "extensions": [".md", ".markdown"]
        }
      }
    }
  '';

  home.packages = with pkgs.nur.repos.falconprogrammer; [
    opencode-sst
  ];
}
