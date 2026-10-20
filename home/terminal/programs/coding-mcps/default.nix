{
  lib,
  pkgs,
  cacheHome,
  homeDirectory,
}:

let
  # Shared server definitions. Credentials remain in each client's own store;
  # authenticate remote servers in Codex with `codex mcp login <name>`.
  servers = {
    playwright = {
      type = "stdio";
      # getExe follows nixpkgs' mainProgram (playwright-mcp).
      command = lib.getExe pkgs.playwright-mcp;
      args = [
        # Downloaded Playwright browsers cannot run directly on NixOS.
        "--executable-path"
        "${pkgs.ungoogled-chromium}/bin/chromium"
        # Keep screenshots and snapshots out of the session's repository.
        "--output-dir"
        "${cacheHome}/playwright-mcp"
      ];
    };
    # 12 Axes political quiz, played by the model. Stdlib-only Python that
    # reads its catalogs from the checkout, so it runs from the working tree
    # rather than the store: it simply fails to start if the repo is absent.
    "12axes" = {
      type = "stdio";
      command = lib.getExe pkgs.python3;
      args = [ "${homeDirectory}/development/12axes/mcp/twelve_axes_server.py" ];
    };
    datadog = {
      type = "http";
      url = "https://mcp.datadoghq.eu/api/unstable/mcp-server/mcp?toolsets=all";
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
    metacog = {
      type = "http";
      url = "http://10.0.20.197:8788/mcp";
    };
  };
in
{
  claudeServers = servers;
  # Codex infers the transport from command/url rather than a type field.
  codexServers = lib.mapAttrs (_: server: builtins.removeAttrs server [ "type" ]) servers;
  # opencode spells the transports local/remote, takes the command and its
  # arguments as one list, and requires `enabled` on every server.
  opencodeServers = lib.mapAttrs (
    _: server:
    if server.type == "stdio" then
      {
        type = "local";
        command = [ server.command ] ++ server.args;
        enabled = true;
      }
    else
      {
        type = "remote";
        inherit (server) url;
        enabled = true;
      }
  ) servers;
}
