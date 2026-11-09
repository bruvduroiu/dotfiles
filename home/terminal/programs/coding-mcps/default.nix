{
  config,
  lib,
  pkgs,
}:

let
  # Every MCP server, declared once. A server can carry per-agent extras under
  # a `claude`, `codex` or `opencode` key; they are merged in only for that
  # agent's schema. Credentials stay in each client's own store (now the
  # KeePassXC keyring for Codex); remote servers are signed into per client,
  # e.g. `claude-work` → /mcp, `codex mcp login <name>`.
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
        "${config.xdg.cacheHome}/playwright-mcp"
      ];
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
    figma = {
      type = "http";
      url = "https://mcp.figma.com/mcp";
      # opencode needs its own OAuth client, from sops (declared in
      # ../opencode). Claude Code gets Figma from its official plugin instead.
      opencode.oauth = {
        clientId = "{file:${config.sops.secrets.figma_oauth_client_id.path}}";
        clientSecret = "{file:${config.sops.secrets.figma_oauth_client_secret.path}}";
      };
    };
    # Kratos' read-only operator MCP: SQL over the production control plane,
    # all organizations. A static personal bearer token (kratos docs/mcp.md),
    # from sops, declared in each consuming module (../claude, ../opencode).
    # Claude Code reads it through a headers helper, so it is never in an
    # environment or a config file.
    kratos = {
      type = "http";
      url = "https://kratos.oolongtechnologies.io/mcp";
      claude.headersHelper = "${pkgs.writeShellScript "kratos-mcp-headers" ''
        ${lib.getExe pkgs.jq} -cn --rawfile t ${config.sops.secrets.kratos_mcp_token.path} \
          '{Authorization: ("Bearer " + ($t | rtrimstr("\n")))}'
      ''}";
      opencode.headers.Authorization = "Bearer {file:${config.sops.secrets.kratos_mcp_token.path}}";
    };
    hey = {
      type = "stdio";
      # Saves drafts, never sends: a draft goes out from HEY or `hey draft send`.
      command = lib.getExe pkgs.hey-cli;
      args = [ "mcp" ];
    };
  };

  # The servers each side may offer its agents. Which agent is on which side,
  # and what it picks from its pool, is ../coding-agents/roster.nix.
  pools = {
    personal = [
      "playwright"
      "deepwiki"
      "linear"
      "figma"
      "kratos"
      "hey"
    ];
    work = [
      "playwright"
      "deepwiki"
      "linear"
      "kratos"
      "datadog"
      "notion"
    ];
  };
  roster = import ../coding-agents/roster.nix { inherit lib; };

  agentKeys = [
    "claude"
    "codex"
    "opencode"
  ];

  # The servers one agent picked, with its family's extras applied.
  resolve =
    family: agent:
    let
      entry = roster.${agent} or (throw "coding-mcps: `${agent}` is not in the roster");
      side = if entry.work then "work" else "personal";
    in
    lib.genAttrs entry.mcps (
      name:
      let
        server = servers.${name} or (throw "coding-mcps: ${agent} picks unknown server `${name}`");
      in
      if lib.elem name pools.${side} then
        lib.recursiveUpdate (removeAttrs server agentKeys) (server.${family} or { })
      else
        throw "coding-mcps: ${agent} picks `${name}`, which is not in the ${side} pool"
    );
in
{
  inherit servers pools;

  claudeServers = agent: resolve "claude" agent;

  # Codex infers the transport from command/url rather than a type field.
  codexServers =
    agent: lib.mapAttrs (_: server: removeAttrs server [ "type" ]) (resolve "codex" agent);

  # opencode spells the transports local/remote, takes the command and its
  # arguments as one list, and requires `enabled` on every server.
  opencodeServers =
    agent:
    lib.mapAttrs (
      _: server:
      let
        rest = removeAttrs server [
          "type"
          "command"
          "args"
        ];
      in
      if server.type == "stdio" then
        rest
        // {
          type = "local";
          command = [ server.command ] ++ server.args or [ ];
          enabled = true;
        }
      else
        rest
        // {
          type = "remote";
          enabled = true;
        }
    ) (resolve "opencode" agent);
}
