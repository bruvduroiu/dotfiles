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
  codexConfigDir = "${config.home.homeDirectory}/.codex";
  codexSettings = {
    forced_login_method = "chatgpt";

    model_reasoning_effort = "medium";
    model_reasoning_summary = "auto";
    model_verbosity = "medium";
    personality = "pragmatic";

    approval_policy = "on-request";
    sandbox_mode = "workspace-write";
    sandbox_workspace_write = {
      network_access = true;
      writable_roots = [
        "${config.home.homeDirectory}/.cache/nix"
        "${config.home.homeDirectory}/.local/state/nix"
      ];
    };

    web_search = "live";
    check_for_update_on_startup = false;
    shell_environment_policy.ignore_default_excludes = false;

    mcp_servers = codingMcps.codexServers;

    agents = {
      enabled = true;
    }
    // codingAgents.codexAgents;

    tui = {
      notifications = true;
      notification_method = "auto";
      notification_condition = "unfocused";
    }
    // lib.optionalAttrs ((config.programs.noctalia.settings.theme.templates.user or { }) ? codex) {
      theme = "noctalia";
    };

    file_opener = "none";
  };
  codexConfig = (pkgs.formats.toml { }).generate "codex-config.toml" codexSettings;
  codexConfigBacking = "${codexConfigDir}/config.toml.mutable";
  codexConfigMerger = pkgs.writeText "merge-codex-config.py" ''
    import sys
    import tomllib

    import tomli_w

    runtime_path, managed_path, output_path = sys.argv[1:]
    with open(runtime_path, "rb") as runtime_file:
        runtime = tomllib.load(runtime_file)
    with open(managed_path, "rb") as managed_file:
        merged = tomllib.load(managed_file)
    for runtime_key in ("projects", "notice"):
        if runtime_key in runtime and runtime_key not in merged:
            merged[runtime_key] = runtime[runtime_key]
    with open(output_path, "wb") as output_file:
        tomli_w.dump(merged, output_file)
  '';
  codexConfigPython = pkgs.python3.withPackages (ps: [ ps.tomli-w ]);
in
{
  # OpenAI Codex CLI, driven by the ChatGPT Plus/Pro subscription rather than a
  # platform API key. This is the same subscription opencode's `openai` provider
  # uses (see ./opencode/default.nix), but the two keep separate credentials —
  # codex under $CODEX_HOME, opencode under ~/.local/share/opencode.
  #
  # CODEX_HOME stays at its default, ~/.codex, because this configuration does
  # not enable home.preferXdgDirectories. Settings are checked against Codex
  # 0.151.0 and its published JSON schema.
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
    # Kept empty because Home Manager otherwise creates an immutable symlink.
    # Codex writes project trust decisions to config.toml at runtime; the
    # activation below materialises codexSettings as a normal writable file.
    settings = { };

    # The model remains unset so Codex can use the account's current default.
    # Override a session with `codex -m <model>` when needed.
    # $CODEX_HOME/AGENTS.md — codex's equivalent of ~/.claude/CLAUDE.md, loaded
    # into every session. Pointed at the same file claude-code uses rather than
    # a copy: the NixOS operating manual (no FHS, no system python/node, reach
    # for `nix run`/`direnv exec`) is the one piece of context an agent on this
    # host cannot work without, and two drifting copies of it would be worse
    # than one shared one.
    context = codingAgents.context;
    skills = codingAgents.skills;
  };

  # Home Manager owns the stable link while Codex writes through it to the
  # mutable backing file. This remains rollback-safe because config.toml itself
  # is still a Home Manager-managed symlink.
  home.file.".codex/config.toml".source = config.lib.file.mkOutOfStoreSymlink codexConfigBacking;

  # On declarative changes, retain runtime-only top-level tables such as
  # [projects] and [notice], then replace managed keys with the new values.
  home.activation.codexWritableConfig = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    run mkdir -p "${codexConfigDir}"
    managedSource="${codexConfigDir}/.config.toml.hm-source"
    previousSource=""
    if [ -f "$managedSource" ]; then
      previousSource="$(cat "$managedSource")"
    fi
    if [ ! -e "${codexConfigBacking}" ] || [ "$previousSource" != "${codexConfig}" ]; then
      runtimeConfig="${codexConfigBacking}"
      if [ ! -f "$runtimeConfig" ] && [ -f "${codexConfigDir}/config.toml" ]; then
        runtimeConfig="${codexConfigDir}/config.toml"
      fi
      if [ -f "$runtimeConfig" ]; then
        run ${codexConfigPython}/bin/python ${codexConfigMerger} "$runtimeConfig" "${codexConfig}" "${codexConfigBacking}.new"
      else
        run install -m 0600 "${codexConfig}" "${codexConfigBacking}.new"
      fi
      run install -m 0600 "${codexConfigBacking}.new" "${codexConfigBacking}"
      run rm -f "${codexConfigBacking}.new"
      run sh -c 'printf "%s\n" "$1" > "$2"' -- "${codexConfig}" "$managedSource"
    fi
  '';
}
