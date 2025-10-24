{ config, pkgs, inputs, ... }:

{
  # Install Claude Code
  home.packages = with pkgs; [
    claude-code
  ];

  # Deploy user settings to ~/.claude/settings.json
  xdg.configFile."claude/settings.json".source = ./settings.json;

  # Deploy MCP configuration to ~/.claude/mcp.json
  xdg.configFile."claude/mcp.json" = {
    text = builtins.readFile ./mcp.json;
    # Substitute Nix store paths for MCP servers
    onChange = ''
      ${pkgs.gnused}/bin/sed -i \
        -e 's|"mcp-server-playwright"|"${pkgs.playwright-mcp}/bin/mcp-server-playwright"|g' \
        -e 's|"mcp-server-sequential-thinking"|"${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking"|g' \
        ${config.xdg.configHome}/claude/mcp.json
    '';
  };

  # Deploy CLAUDE.md with systematic thinking framework
  xdg.configFile."claude/CLAUDE.md".source = ./CLAUDE.md;

  # Ensure MCP server packages are available
  home.packages = with pkgs; [
    playwright-mcp
    mcp-server-sequential-thinking
    ungoogled-chromium  # For playwright
  ];
}
