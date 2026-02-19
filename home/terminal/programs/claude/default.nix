{ config, pkgs, inputs, ... }:

{
  programs.claude-code = {
    enable = true;

    # MCP servers configuration — Nix store paths resolved at build time
    mcpServers = {
      playwright = {
        type = "stdio";
        command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
        args = [
          "--executable-path"
          "${pkgs.ungoogled-chromium}/bin/chromium"
        ];
      };
      deepwiki = {
        type = "http";
        url = "https://mcp.deepwiki.com/mcp";
      };
      linear = {
        type = "http";
        url = "https://mcp.linear.app/mcp";
      };
      notion = {
        type = "http";
        url = "https://mcp.notion.com/mcp";
      };
    };

    # Settings
    settings = {
      enabledPlugins = {
        "superpowers@superpowers-marketplace" = true;
        "frontend-design@claude-plugins-official" = true;
        "gopls-lsp@claude-plugins-official" = true;
        "typescript-lsp@claude-plugins-official" = true;
        "pyright-lsp@claude-plugins-official" = true;
      };
      extraKnownMarketplaces = {
        superpowers-marketplace = {
          source = {
            source = "github";
            repo = "obra/superpowers-marketplace";
          };
        };
      };
      permissions = {
        allow = [
          "Bash(git status)"
          "Bash(git diff:*)"
          "Bash(git log:*)"
          "Bash(npm run lint)"
          "Bash(npm run test:*)"
          "Bash(cargo build)"
          "Bash(cargo test)"
          "Bash(nix build:*)"
          "Bash(nix develop:*)"
          "Read(~/.config/fish/**)"
          "Read(~/.config/nvim/**)"
        ];
        ask = [
          "Bash(git push:*)"
          "Bash(git commit:*)"
          "Bash(rm -rf:*)"
          "Bash(cargo publish:*)"
          "Bash(npm publish:*)"
          "WebFetch(domain:*)"
          "Bash(curl:*)"
        ];
        deny = [
          "Read(./.env)"
          "Read(./.env.*)"
          "Read(./secrets/**)"
          "Read(~/.aws/**)"
          "Read(~/.ssh/**)"
          "Bash(wget:*)"
        ];
        defaultMode = "default";
      };
      env = {
        SHELL = "fish";
        API_TIMEOUT_MS = "3000000";
        NIX_ENVIRONMENT = "true";
      };
      includeCoAuthoredBy = true;
      cleanupPeriodDays = 30;
      outputStyle = "Explanatory";
    };
  };
}
