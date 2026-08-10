{ config
, lib
, pkgs
, ...
}:

let
  lspDeps = import ./lsp-deps.nix { inherit pkgs; };
in
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    web.enable = true;

    # Bind the web UI to framework13's wg0 overlay address only, so it is
    # reachable on port 4096 from the WireGuard overlay but not on LAN or
    # public interfaces. Binding a specific address (vs. 0.0.0.0 + firewall)
    # is what makes this tunnel-only. NOTE: this IP is framework13-specific;
    # importing this module on another host would fail to bind.
    #
    # Was the Tailscale IP until the WireGuard migration retired the tailnet:
    # the address stopped existing on any interface, so every start failed with
    # EADDRNOTAVAIL and Restart=always looped it ~1800 times per boot. wg0 is
    # brought up by wg-quick-wg0.service and holds its address whether or not
    # the tunnel has a live handshake, so the bind does not depend on peer
    # reachability — but it does depend on wg-quick having run.
    #
    # Written literally rather than via inputs.secrets.vars: the bind address
    # is the one thing about this unit worth reading at a glance, and a wrong
    # value is a boot-long crash loop rather than a build error.
    #
    # No OPENCODE_SERVER_PASSWORD is set, so anything that can route to this
    # address gets an unauthenticated agent with the permissions below. That
    # is deliberate — reachability is the overlay's job — but it means the
    # blast radius of a new wg0 peer includes this port.
    web.extraArgs = [
      "--hostname"
      "10.99.0.2"
      "--port"
      "4096"
    ];

    agents = {
      plan = ./agents/plan.md;
      code = ./agents/code.md;
      code-review = ./agents/code-review.md;
    };

    skills = { };

    settings = {
      # `openai` here is the ChatGPT Plus/Pro (Codex) subscription, not an API
      # key. opencode 1.18 has that OAuth flow built in — it talks to
      # https://chatgpt.com/backend-api/codex/responses and reports the models
      # at zero cost, because the subscription has already paid. Note the
      # absence of a `provider.openai` block below: defining one with an
      # `options.apiKey` is what flips this back to metered platform billing.
      #
      # Auth is a one-time interactive step that cannot be declared in Nix (it
      # mints a refresh token):
      #   opencode auth login  ->  openai  ->  ChatGPT Pro/Plus (browser)
      # The token lands in ~/.local/share/opencode/auth.json, outside the store.
      # Pick `ChatGPT Pro/Plus (headless)` instead when logging in over SSH.
      enabled_providers = [ "openai" "deepseek" "openrouter" "zai-coding-plan" ];
      provider = {
        deepseek = {
          options = {
            apiKey = "{file:${config.sops.secrets.deepseek_api_key.path}}";
          };
        };
        openrouter = {
          options = {
            apiKey = "{file:${config.sops.secrets.openrouter_api_key.path}}";
          };
        };
        # Z.AI Coding Plan (subscription endpoint, GLM models). Provider id
        # from models.dev; hits https://api.z.ai/api/coding/paas/v4.
        zai-coding-plan = {
          options = {
            apiKey = "{file:${config.sops.secrets.zai_api_key.path}}";
          };
        };
      };
      # Remote MCP servers — mirrored from the claude-code config so opencode
      # sees the same tools. opencode's schema is `type = "remote"` + `url`
      # (vs. claude's `type = "http"`); `enabled` is required per server.
      mcp = {
        datadog = {
          type = "remote";
          url = "https://mcp.datadoghq.eu/api/unstable/mcp-server/mcp?toolsets=all";
          enabled = true;
        };
        deepwiki = {
          type = "remote";
          url = "https://mcp.deepwiki.com/mcp";
          enabled = true;
        };
        linear = {
          type = "remote";
          url = "https://mcp.linear.app/mcp";
          enabled = true;
        };
        notion = {
          type = "remote";
          url = "https://mcp.notion.com/mcp";
          enabled = true;
        };
      };

      autoshare = false;
      autoupdate = true;
      # gpt-5.5 rather than the newer gpt-5.6-sol: under OAuth opencode
      # hard-allow-lists gpt-5.5, so it is the one Codex-subscription model
      # guaranteed to survive the provider's model filter. gpt-5.6-sol is
      # admitted by the same filter and has a 1M context, but ships as beta —
      # switch with `/models` in the TUI before committing it here.
      model = "openai/gpt-5.5";
      permission = {
        "*" = "allow";
        # Private flake (inputs.secrets): sops files AND vars — keeps
        # network topology/identifiers out of AI conversation context.
        # Last matching rule wins; nix serializes attrs alphabetically,
        # so "*" (0x2A) lands before "~" (0x7E) and the deny prevails.
        "read" = {
          "*" = "allow";
          "~/development/secrets/**" = "deny";
        };
        "skill" = {
          "*" = "allow";
        };
        "bash" = {
          "*" = "allow";
          "touch *" = "ask";
          "mkdir *" = "ask";
          "rm *" = "ask";
          "cp *" = "ask";
          "mv *" = "ask";
          "dd *" = "ask";
          "sudo *" = "ask";
          "chmod *" = "ask";
          "chown *" = "ask";
          "curl *" = "ask";
          "wget *" = "ask";
          "npm install *" = "ask";
          "pip install *" = "ask";
          "git push" = "ask";
          "git reset --hard *" = "ask";
          "git clean *" = "ask";
          "reboot" = "ask";
          "shutdown" = "ask";
          "kill *" = "ask";
          "killall *" = "ask";
          "docker *" = "ask";
          "mkfs *" = "ask";
          "fdisk *" = "ask";
          "parted *" = "ask";
          "format *" = "ask";
          "git branch -d *" = "ask";
          "git branch -D *" = "ask";
          "git rebase *" = "ask";
          "npm run publish" = "ask";
          "ssh *" = "ask";
          "scp *" = "ask";
          "nix *" = "ask";
          "nixos-rebuild *" = "ask";
        };
        "doom_loop" = "ask";
        "external_directory" = {
          "/tmp/**" = "allow";
        };
      };
    };
  };

  # Tools must be real files, not symlinks into /nix/store: opencode's
  # embedded Bun resolves `@opencode-ai/plugin` from the importer's
  # realpath, and the store has no node_modules ancestor. Copying keeps
  # resolution anchored at ~/.config/opencode, where opencode auto-installs
  # the plugin package.
  home.activation.opencodeToolsCopy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.xdg.configHome}/opencode/tools"
    run install -m 0644 ${./tools}/*.ts "${config.xdg.configHome}/opencode/tools/"
  '';

  # Symlink nix-built node_modules into the repo checkout so the editor LSP
  # resolves @opencode-ai/plugin in tools/*.ts without any npm install.
  # Guarded: only hosts that have the dotfiles checkout get the link.
  home.activation.opencodeLspDeps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    opencodeRepoDir="$HOME/development/dotfiles/home/terminal/programs/opencode"
    if [ -d "$opencodeRepoDir" ]; then
      run ln -sfnT ${lspDeps} "$opencodeRepoDir/node_modules"
    fi
  '';
}
