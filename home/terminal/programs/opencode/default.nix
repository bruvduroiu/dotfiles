{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  codingAgents = import ../coding-agents { inherit lib pkgs; };
  codingMcps = import ../coding-mcps { inherit config lib pkgs; };
  lspDeps = import ./lsp-deps.nix { inherit pkgs; };
  scheduler = pkgs.callPackage ../../../../pkgs/opencode-scheduler {
    inherit (config.home) profileDirectory;
  };
  secretsFile = "${inputs.secrets}/secrets/common/api-keys.yaml";

  # One-time pairing links for the web UI. `opencode pair` only targets
  # opencode's own background service, not opencode-web, so ask :4096
  # directly. Opening a link sets a 30-day session cookie signed with the
  # password (rotating the sops value revokes every paired browser).
  webPair = pkgs.writeShellApplication {
    name = "opencode-web-pair";
    runtimeInputs = with pkgs; [ coreutils gnused curl jq iproute2 gawk qrencode ];
    text = ''
      # Read, never source: the value may hold spaces or shell metacharacters.
      pw=$(sed -n 's/^OPENCODE_SERVER_PASSWORD=//p' ${config.sops.templates."opencode-web.env".path})
      # A header on stdin keeps the password out of argv and needs no quoting.
      code=$(printf 'Authorization: Basic %s\n' "$(printf 'opencode:%s' "$pw" | base64 -w0)" \
        | curl -fsS -H @- -X POST http://127.0.0.1:4096/api/pair | jq -r .code)
      echo "Links work once and expire in 5 minutes:"
      first=""
      for ip in $(ip -4 -o addr show scope global | awk '{ split($4, a, "/"); print a[1] }'); do
        echo "  http://$ip:4096/auth/connect/$code"
        first=''${first:-http://$ip:4096/auth/connect/$code}
      done
      if [ -n "$first" ]; then qrencode -t ansiutf8 "$first"; fi
    '';
  };
in
{
  # Figma's OAuth client for opencode (used by the figma entry in ../coding-mcps).
  sops.secrets = {
    figma_oauth_client_id.sopsFile = secretsFile;
    figma_oauth_client_secret.sopsFile = secretsFile;
    # opencode 2.x `serve` always requires basic auth (user `opencode`); without
    # this it mints a random password per start that is never shown.
    opencode_server_password.sopsFile = secretsFile;
  };

  programs.opencode = {
    enable = true;

    web.enable = true;

    # Bind the web UI to every interface for LAN and WireGuard access.
    # framework13's firewall explicitly opens TCP 4096.
    # Basic auth (user `opencode`, password from sops via the unit's
    # EnvironmentFile below) is the only gate in front of an agent with the
    # permissions below.
    web.extraArgs = [
      "--hostname"
      "0.0.0.0"
      "--port"
      "4096"
    ];

    agents = codingAgents.opencodeAgents // {
      plan = ./agents/plan.md;
      code = ./agents/code.md;
    };

    skills = codingAgents.skills;

    # TUI-side switch; the server still prompts only where `permission`
    # below says ask. The desktop app keeps its own toggle, along with its
    # other UI settings (layout, experiments), in its state DB;
    # home/programs/opencode-desktop.nix seeds them.
    tui.session.permissions = "autoaccept";

    settings = {
      # Pin the plugin, not its jobs: chat tools manage mutable job JSON and
      # systemd user timers under ~/.config without Home Manager activation.
      plugin = [ "file://${scheduler}" ];
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
        "mistral-vibe"
        # Claude Code subscription: drives the local `claude` CLI (its own
        # login in ~/.claude), found via OPENCODE_CLAUDE_PATH or $PATH.
        "claude-agent"
      ];
      providers.mistral-vibe = {
        name = "Mistral Vibe";
        env = [ "MISTRAL_API_KEY" ];
        package = "@opencode/ai/providers/openai-compatible/responses";
        # Prefix caching is automatic; do not send OpenAI's cache-key field.
        compatibility.supportsPromptCacheKey = false;
        settings.baseURL = "https://api.mistral.ai/v1";
        body = {
          store = false;
          parallel_tool_calls = true;
          # The Responses runtime defaults to OpenAI encrypted reasoning;
          # Mistral does not need that extension for stateless requests.
          include = [ ];
        };
        models = {
          zai-glm-5-3 = {
            name = "GLM 5.3 (Vibe)";
            capabilities.tools = true;
            limit = {
              context = 1000000;
              output = 32768;
            };
            body.reasoning.effort = "low";
          };
          zai-glm-5-3-flash = {
            name = "GLM 5.3 Flash (Vibe)";
            capabilities.tools = true;
            limit.output = 32768;
            body.reasoning.effort = "low";
          };
          deepseek-v4-1-flash-1017 = {
            name = "DeepSeek V4.1 Flash 1017 (Vibe)";
            capabilities.tools = true;
            limit.output = 32768;
          };
        };
      };
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
      # Selected per agent in ../coding-mcps, translated to opencode's
      # local/remote schema there.
      mcp = codingMcps.opencodeServers "opencode";

      autoshare = false;
      # The package is upgraded through nixpkgs, not by mutating the store.
      autoupdate = false;
      instructions = [ codingAgents.context ];
      # gpt-5.5 rather than the newer gpt-5.6-sol: under OAuth opencode
      # hard-allow-lists gpt-5.5, so it is the one Codex-subscription model
      # guaranteed to survive the provider's model filter. gpt-5.6-sol is
      # admitted by the same filter and has a 1M context, but ships as beta —
      # switch with `/models` in the TUI before committing it here.
      model = "openai/gpt-6-astra";
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
          # "touch *" = "ask";
          # "mkdir *" = "ask";
          # "rm *" = "ask";
          # "cp *" = "ask";
          # "mv *" = "ask";
          # "dd *" = "ask";
          # "sudo *" = "ask";
          # "chmod *" = "ask";
          # "chown *" = "ask";
          # "curl *" = "ask";
          # "wget *" = "ask";
          # "npm install *" = "ask";
          # "pip install *" = "ask";
          # "git push" = "ask";
          # "git reset --hard *" = "ask";
          # "git clean *" = "ask";
          # "reboot" = "ask";
          # "shutdown" = "ask";
          # "kill *" = "ask";
          # "killall *" = "ask";
          # "docker *" = "ask";
          # "mkfs *" = "ask";
          # "fdisk *" = "ask";
          # "parted *" = "ask";
          # "format *" = "ask";
          # "git branch -d *" = "ask";
          # "git branch -D *" = "ask";
          # "git rebase *" = "ask";
          # "npm run publish" = "ask";
          # "ssh *" = "ask";
          # "scp *" = "ask";
          # "nix *" = "ask";
          # "nixos-rebuild *" = "ask";
        };
        # "doom_loop" = "ask";
        "external_directory" = {
          "/tmp/**" = "allow";
          "~/development/**" = "allow";
        };
      };
    };
  };

  # Generated timers use the stable profile path, so Nix GC and package
  # upgrades do not strand jobs with references to old Perl store paths.
  home.packages = [
    pkgs.perl
    webPair
  ];

  # FFF refuses to index the home directory used by the web project picker,
  # causing valid paths under ~/development to return no search results.
  systemd.user.services.opencode-web.Service.Environment = [
    "OPENCODE_DISABLE_FFF=1"
    "OPENCODE_CLAUDE_PATH=${config.programs.claude-code.finalPackage}/bin/claude"
  ];

  # Rendered outside the store; the unit waits for sops to decrypt it.
  sops.templates."opencode-web.env" = {
    mode = "0400";
    content = "OPENCODE_SERVER_PASSWORD=${config.sops.placeholder.opencode_server_password}\n";
  };
  systemd.user.services.opencode-web = {
    Unit = {
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
    Service.EnvironmentFile = config.sops.templates."opencode-web.env".path;
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
