{
  config,
  lib,
  pkgs,
  ...
}:

let
  codingAgents = import ../coding-agents { inherit lib pkgs; };
  codingMcps = import ../coding-mcps {
    inherit lib pkgs;
    cacheHome = config.xdg.cacheHome;
  };

  # Hook scripts live in ./config/hooks/*.sh; hooks.nix wraps each one in a
  # writeShellApplication (deps pinned, shellchecked at build time) and exports
  # the settings.json registration graph that actually makes them fire.
  claudeHooks = import ./hooks.nix { inherit pkgs; };

  # Helper scripts that live inside a skill dir (so the skill can be handed
  # to a colleague as-is) and are also built into PATH binaries here.
  claudeScripts = import ./scripts.nix { inherit pkgs lib; };

  # Second Claude account on this machine. ~/.claude stays the personal
  # profile; work gets its own config dir, selected via CLAUDE_CONFIG_DIR.
  #
  # On Linux that env var is complete isolation — credentials live at
  # <config-dir>/.credentials.json (0600), alongside sessions/, projects/,
  # history.jsonl and .claude.json. (On macOS it is not: OAuth tokens go to
  # the Keychain, so only settings and history separate.)
  workConfigDir = ".claude-work";

  # `claude-work`: the same binary and the same config, a different account.
  #
  # Execs finalPackage, NOT pkgs.claude-code. finalPackage is the module's
  # wrapper, which passes `--plugin-dir <generated>` — and that generated
  # plugin dir is where `mcpServers` below actually lives. Bypassing the
  # wrapper silently drops every MCP server.
  claude-work = pkgs.writeShellScriptBin "claude-work" ''
    set -eu
    export CLAUDE_CONFIG_DIR="$HOME/${workConfigDir}"
    exec ${config.programs.claude-code.finalPackage}/bin/claude "$@"
  '';
in
{
  home.packages = [ claude-work ] ++ builtins.attrValues claudeScripts.packages;

  # `programs.claude-code` materialises exactly one configDir, so a session
  # launched under a different CLAUDE_CONFIG_DIR would start with *nothing*
  # from this repo — no secret-read-guard hook, no deny list, no NixOS
  # CLAUDE.md. Mirror the same store paths into the work profile; only the
  # per-account state (credentials, sessions, projects, MCP OAuth tokens)
  # differs, which is the entire point of the split.
  #
  # settings.json is taken from the module's own generated output rather than
  # rebuilt here, so hooks/permissions/plugins cannot drift between accounts.
  home.file = {
    "${workConfigDir}/settings.json".source =
      config.home.file."${config.programs.claude-code.configDir}/settings.json".source;
    "${workConfigDir}/CLAUDE.md".source = codingAgents.context;
    # recursive: recreate the directory and symlink each file individually,
    # so the directory itself stays writable — `/agents` can still add one at
    # runtime. A bare `source = ./dir` would symlink the whole read-only dir.
    "${workConfigDir}/agents" = {
      source = codingAgents.claudeAgents;
      recursive = true;
    };
    "${workConfigDir}/rules" = {
      source = ./config/rules;
      recursive = true;
    };
    "${workConfigDir}/skills" = {
      source = codingAgents.skills;
      recursive = true;
    };
  };

  programs.claude-code = {
    enable = true;

    package = pkgs.claude-code;

    # ~/.claude/CLAUDE.md — global context loaded into every session. Holds the
    # NixOS operating manual (how to reach python/node/etc. without a system
    # install). Was previously an orphan file in this directory that nothing
    # referenced, so none of it ever reached Claude.
    #
    # `memory.source`/`memory.text` were collapsed into a single `context`
    # option (either lines or a path); a path still lands as a symlink, a
    # string would be written inline.
    context = codingAgents.context;

    # agentsDir/rulesDir are dir-path options in 26.05 (no warning).
    agentsDir = codingAgents.claudeAgents;
    rulesDir = ./config/rules; # replaces the old home.file.".claude/rules" workaround
    # No hooksDir: it only symlinks the scripts into ~/.claude/hooks as 0444
    # (not executable, and not registered anywhere). settings.hooks below points
    # at the built store paths instead — see hooks.nix.
    # skillsDir was renamed to `skills` in 26.05 (accepts a dir path or attrset).
    skills = codingAgents.skills;

    # Shared with Codex; Nix store paths are resolved at build time.
    mcpServers = codingMcps.claudeServers;

    # Settings
    settings = {
      # Event -> matcher -> command graph. Commands are /nix/store paths, so
      # they are executable and carry their own jq/shellcheck/nix on PATH.
      hooks = claudeHooks.settings;

      enabledPlugins = {
        "frontend-design@claude-plugins-official" = true;
        "gopls-lsp@claude-plugins-official" = true;
        "typescript-lsp@claude-plugins-official" = true;
        "pyright-lsp@claude-plugins-official" = true;
        "figma@claude-plugins-official" = true;
      };
      extraKnownMarketplaces = {
        claude-plugins-official = {
          source = {
            source = "git";
            url = "https://github.com/anthropics/claude-plugins-official.git";
          };
        };
      };
      permissions = {
        allow = [
          "Bash(git status)"
          "Bash(git diff:*)"
          "Bash(git log:*)"
          "Bash(jj new:*)"
          "Bash(jj describe:*)"
          "Bash(jj workspace add:*)"
          "Bash(jj workspace update-stale)"
          # jj orientation commands — read-only, so sessions in colocated
          # repos can answer "what did I change" without prompting.
          "Bash(jj st)"
          "Bash(jj status)"
          "Bash(jj diff:*)"
          "Bash(jj log:*)"
          "Bash(jj show:*)"
          # Parallel-agent orientation: who else is working, where, and what
          # happened — all read-only.
          "Bash(jj workspace list)"
          "Bash(jj workspace root)"
          "Bash(jj op log:*)"
          "Bash(jj op show:*)"
          "Bash(jj resolve --list)"
          # Stack review reads (jj-stack* skills): what changed since a
          # reviewer last looked, where bookmarks point, which forge.
          "Bash(jj interdiff:*)"
          "Bash(jj evolog:*)"
          "Bash(jj bookmark list:*)"
          "Bash(jj git remote list)"
          "Bash(jj-stack-check:*)"
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
          # "Bash(git push:*)"
          # "Bash(git commit:*)"
          # "Bash(git rm:*)"
          # "Bash(jj split:*)"
          # "Bash(jj restore:*)"
          # "Bash(jj rebase:*)"
          # "Bash(jj absorb:*)"
          # "Bash(jj squash:*)"
          # "Bash(jj bookmark set:*)"
          # "Bash(jj bookmark delete:*)"
          # "Bash(jj git fetch:*)"
          # "Bash(jj git push:*)"
          # "Bash(gh pr:*)"
          # "Bash(glab mr:*)"
          # "Bash(fj pr:*)"
          # "Bash(rm -rf:*)"
          # "Bash(cargo publish:*)"
          # "Bash(npm publish:*)"
          # "WebFetch(domain:*)"
          # "Bash(curl:*)"
        ];
        # Read(...) rules cover the Read tool only — `cat`/`echo $TOKEN` slip
        # past them entirely. The secret-read-guard hook (hooks.nix) is what
        # covers Bash; these stay as the cheap first line of defence.
        deny = [
          "Read(./.env)"
          "Read(./.env.*)"
          "Read(./secrets/**)"
          "Read(/run/secrets/**)"
          "Read(/run/secrets.d/**)"
          "Read(~/development/secrets/**)"
          "Read(~/.aws/**)"
          "Read(~/.ssh/**)"
          "Read(~/.gnupg/**)"
          "Read(~/.config/sops/**)"
          "Read(~/.netrc)"
          "Read(~/.npmrc)"
          "Read(~/.docker/config.json)"
        ];
        defaultMode = "auto";
      };
      env = {
        SHELL = "fish";
        API_TIMEOUT_MS = "3000000";
        NIX_ENVIRONMENT = "true";
      };
      includeCoAuthoredBy = true;
      cleanupPeriodDays = 30;
      outputStyle = "Explanatory";

      # terminal BEL when a session needs attention → ghostty bell-features
      # "attention" → hyprland urgent → urgent workspace indicator
      # (SUPER+D jumps to it). Default "auto" would send desktop notifications
      # in ghostty instead; the bell/urgency path is quieter and survives DND.
      preferredNotifChannel = "terminal_bell";
    };
  };
}
