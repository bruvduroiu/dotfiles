{ config, pkgs, inputs, ... }:

let
  # Only available on hosts that declare the secret (e.g. framework13);
  # `or null` keeps eval safe on phantom/iso where it isn't set.
  deepseekKeyPath = config.sops.secrets.deepseek_api_key.path or null;

  # `deepseek-code`: launch the same (LSP-wrapped) claude binary but pointed at
  # DeepSeek's Anthropic-compatible endpoint, with the API key read from sops
  # into ANTHROPIC_AUTH_TOKEN at runtime (never baked into the Nix store).
  deepseek-code = pkgs.writeShellScriptBin "deepseek-code" (''
    set -eu
  '' + (if deepseekKeyPath == null then ''
    echo "deepseek-code: deepseek_api_key sops secret is not configured on this host" >&2
    exit 1
  '' else ''
    if [ ! -r "${deepseekKeyPath}" ]; then
      echo "deepseek-code: cannot read DeepSeek API key at ${deepseekKeyPath}" >&2
      exit 1
    fi
    ANTHROPIC_AUTH_TOKEN="$(${pkgs.coreutils}/bin/cat ${deepseekKeyPath})"
    export ANTHROPIC_AUTH_TOKEN

    export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
    export ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
    export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
    export CLAUDE_CODE_EFFORT_LEVEL="max"

    exec ${pkgs.claude-code}/bin/claude "$@"
  ''));
in
{
  home.packages = [ deepseek-code ];

  # Workaround: rulesDir not yet available in locked home-manager release-25.11
  home.file.".claude/rules" = {
    source = ./config/rules;
    recursive = true;
  };

  programs.claude-code = {
    enable = true;

    package = pkgs.claude-code;

    agentsDir = ./config/agents;
    skillsDir = ./config/skills;
    hooksDir = ./config/hooks;

    # MCP servers configuration — Nix store paths resolved at build time
    mcpServers = {
      # playwright = {
      #   type = "stdio";
      #   command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
      #   args = [
      #     "--executable-path"
      #     "${pkgs.ungoogled-chromium}/bin/chromium"
      #   ];
      # };
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
    };

    # Settings
    settings = {
      enabledPlugins = {
        "caveman@caveman" = true;
        "superpowers@superpowers-marketplace" = true;
        "frontend-design@claude-plugins-official" = true;
        "gopls-lsp@claude-plugins-official" = true;
        "typescript-lsp@claude-plugins-official" = true;
        "pyright-lsp@claude-plugins-official" = true;
      };
      extraKnownMarketplaces = {
        claude-plugins-official = {
          source = {
            source = "git";
            url = "https://github.com/anthropics/claude-plugins-official.git";
          };
        };
        superpowers-marketplace = {
          source = {
            source = "github";
            repo = "obra/superpowers-marketplace";
          };
        };
        caveman = {
          source = {
            source = "github";
            repo = "JuliusBrussee/caveman";
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
        # ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic";
        # ANTHROPIC_MODEL = "deepseek-v4-pro[1m]";
        # ANTHROPIC_DEFAULT_OPUS_MODEL = "deepseek-v4-pro[1m]";
        # ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-v4-pro[1m]";
        # ANTHROPIC_DEFAULT_HAIKU_MODEL = "deepseek-v4-flash";
        # CLAUDE_CODE_SUBAGENT_MODEL = "deepseek-v4-flash";
        # CLAUDE_CODE_EFFORT_LEVEL = "max";
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
