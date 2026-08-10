{ config, pkgs, ... }:

{
  # OpenAI Codex CLI, driven by the ChatGPT Plus/Pro subscription rather than a
  # platform API key. This is the same subscription opencode's `openai` provider
  # uses (see ./opencode/default.nix), but the two keep separate credentials —
  # codex under $CODEX_HOME, opencode under ~/.local/share/opencode.
  #
  # `programs.codex` writes ~/.codex/config.toml. It would move to
  # ~/.config/codex only if `home.preferXdgDirectories` were enabled, which this
  # config does not set — so CODEX_HOME stays at its default and no session
  # variable is exported.
  #
  # Every key below was checked against codex 0.146.0 by feeding it a bogus
  # value and reading the rejected-variant list back out of the binary; the
  # enum comments are those lists verbatim. This matters because codex parses
  # config.toml with untagged enums that silently swallow unknown *table*
  # fields — `tools.web_search = { mode = "nonsense" }` loads without complaint
  # and does nothing. Only scalar forms are validated, so scalars are what this
  # file uses.
  programs.codex = {
    enable = true;

    # Overlaid to nixpkgs-unstable in system/nix/nixpkgs.nix — 26.05 pins 0.133,
    # which predates most of the schema below.
    package = pkgs.codex;

    # Auth is a one-time interactive step that cannot be declared in Nix (it
    # mints a refresh token into $CODEX_HOME/auth.json):
    #   codex login          # browser OAuth against the ChatGPT account
    #   codex login status   # verify
    # `forced_login_method` is the guard rail that keeps it that way: with it
    # set to "chatgpt", an OPENAI_API_KEY sitting in the environment cannot
    # quietly redirect this CLI onto metered platform billing.
    # Variants: chatgpt | api
    settings = {
      forced_login_method = "chatgpt";

      # `model` is deliberately unset. codex 0.146 resolves the default from a
      # server-side models manager tied to the account, so hardcoding a slug
      # here only risks pinning to something the subscription tier has moved
      # past. Override per-session with `codex -m <model>`; the slugs this
      # build knows are gpt-5.6-sol / -terra / -luna, gpt-5.5, gpt-5.4(-mini),
      # gpt-5.2.

      # Free-form string, not an enum — codex forwards it and lets the model
      # reject what it does not support. Practical range across the gpt-5.x
      # family: none | minimal | low | medium | high | xhigh.
      model_reasoning_effort = "medium";
      # Variants: auto | concise | detailed | none
      model_reasoning_summary = "auto";
      # Variants: low | medium | high
      model_verbosity = "medium";

      # Variants: untrusted | on-failure | on-request | granular | never
      # "on-request" lets the model work uninterrupted inside the sandbox and
      # ask only when it needs to step outside it — the closest match to the
      # opencode permission set next door, which allows by default and puts
      # `ask` on the destructive and network-touching commands.
      approval_policy = "on-request";

      # Variants: read-only | workspace-write | danger-full-access
      sandbox_mode = "workspace-write";

      sandbox_workspace_write = {
        # Required on NixOS more than most places: nearly every useful command
        # here is `nix run nixpkgs#x`, `nix build`, or `nix develop`, and all of
        # them fetch from cache.nixos.org on first use.
        network_access = true;

        # The nix client writes eval and fetcher caches outside the workspace;
        # without these roots `nix build` fails on a cache write rather than on
        # anything to do with the build itself. The store itself is absent by
        # design — nix-daemon does that writing from outside the sandbox.
        writable_roots = [
          "${config.home.homeDirectory}/.cache/nix"
          "${config.home.homeDirectory}/.local/state/nix"
        ];
      };

      # Boolean form on purpose. The table form (`{ mode = "indexed" }`) parses
      # but is not validated — see the header note.
      tools.web_search = true;

      tui = {
        notifications = true;
        # Variants: auto | osc9 | bel
        notification_method = "auto";
        # Variants: unfocused | always
        notification_condition = "unfocused";
      };

      # Variants: vscode | vscode-insiders | windsurf | cursor | none
      # None of the supported openers is nvim, and a wrong one spawns an editor
      # that is not installed, so file references stay plain paths.
      file_opener = "none";
    };

    # $CODEX_HOME/AGENTS.md — codex's equivalent of ~/.claude/CLAUDE.md, loaded
    # into every session. Pointed at the same file claude-code uses rather than
    # a copy: the NixOS operating manual (no FHS, no system python/node, reach
    # for `nix run`/`direnv exec`) is the one piece of context an agent on this
    # host cannot work without, and two drifting copies of it would be worse
    # than one shared one.
    context = ./claude/CLAUDE.md;

    # No MCP servers. claude-code and opencode both carry the datadog/deepwiki/
    # linear/notion set; codex stays a fast local coding agent, which also
    # avoids four `codex mcp login` OAuth dances. Add them under
    # `settings.mcp_servers.<name>.url` if that changes — 0.146 speaks
    # streamable HTTP natively, no rmcp feature flag needed.
  };
}
