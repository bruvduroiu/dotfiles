{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  lspDeps = import ./lsp-deps.nix { inherit pkgs; };
  secretsFile = "${inputs.secrets}/secrets/common/api-keys.yaml";
in
{
  sops.secrets = {
    figma_oauth_client_id.sopsFile = secretsFile;
    figma_oauth_client_secret.sopsFile = secretsFile;
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    web.enable = true;

    # Bind the web UI to every interface for LAN and WireGuard access.
    # framework13's firewall explicitly opens TCP 4096.
    # No OPENCODE_SERVER_PASSWORD is set, so anything that can route to this
    # host gets an unauthenticated agent with the permissions below.
    web.extraArgs = [
      "--hostname"
      "0.0.0.0"
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
      enabled_providers = [
        "openai"
        "deepseek"
        "openrouter"
        "zai-coding-plan"
        "abliteration"
      ];
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
        abliteration = {
          npm = "@ai-sdk/openai-compatible";
          name = "Abliteration";
          options = {
            baseURL = "https://api.abliteration.ai/v1";
            apiKey = "{file:${config.sops.secrets.abliteration_api_key.path}}";
          };
          models = {
            abliterated-model-large-v2 = {
              name = "Abliterated Large v2";
            };
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
        figma = {
          type = "remote";
          url = "https://mcp.figma.com/mcp";
          enabled = true;
          oauth = {
            clientId = "{file:${config.sops.secrets.figma_oauth_client_id.path}}";
            clientSecret = "{file:${config.sops.secrets.figma_oauth_client_secret.path}}";
          };
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
          "~/development/**" = "allow";
        };
      };
    };
  };

  # FFF refuses to index the home directory used by the web project picker,
  # causing valid paths under ~/development to return no search results.
  systemd.user.services.opencode-web.Service.Environment = [
    "OPENCODE_DISABLE_FFF=1"
  ];

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
