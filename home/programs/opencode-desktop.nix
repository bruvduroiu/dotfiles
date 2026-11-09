{ config, lib, pkgs, ... }:

let
  codingMcps = import ../terminal/programs/coding-mcps { inherit config lib pkgs; };

  # MCPs only the desktop app gets (its entry in coding-agents/roster.nix,
  # served by coding-mcps). opencode merges OPENCODE_CONFIG_CONTENT over
  # ~/.config/opencode, so terminal opencode, Claude Code and Codex never see
  # these. The desktop passes its environment through to the engine it starts.
  desktopConfig = builtins.toJSON {
    mcp = codingMcps.opencodeServers "opencode-desktop";
  };

  # The app's UI settings live in its own state DB under `settings.v3`, not
  # in opencode.json. The patched defaults cover a fresh profile;
  # seedSettings below re-applies them to an existing one at each launch.
  unwrapped = pkgs.opencode-desktop.overrideAttrs (old: {
    postPatch = old.postPatch + ''
      substituteInPlace packages/app/src/settings/model.tsx \
        --replace-fail 'permissions: { autoApprove: false,' 'permissions: { autoApprove: true,' \
        --replace-fail 'tabLayout: "horizontal",' 'tabLayout: "inbox",' \
        --replace-fail 'newIcons: false,' 'newIcons: true,' \
        --replace-fail 'newQuestionUI: false,' 'newQuestionUI: true,'
    '';
  });

  # Runs before the app starts, so the app reads the result instead of
  # overwriting it from memory. Toggling these in the UI lasts one session.
  seedSettings = pkgs.writeShellApplication {
    name = "opencode-desktop-seed-settings";
    runtimeInputs = [ pkgs.sqlite pkgs.coreutils ];
    text = ''
      dir="${config.xdg.configHome}/ai.opencode.desktop"
      db="$dir/drafts.sqlite"
      [ -f "$db" ] || exit 0
      # A second launch only hands off to the running instance.
      if lock=$(readlink "$dir/SingletonLock" 2>/dev/null) && kill -0 "''${lock##*-}" 2>/dev/null; then
        exit 0
      fi
      sqlite3 "$db" <<'SQL'
      UPDATE state SET
        value = json_set(value,
          '$.appearance.tabLayout', 'inbox',
          '$.permissions.autoApprove', json('true'),
          '$.general.newIcons', json('true'),
          '$.general.newQuestionUI', json('true')),
        updated_at = unixepoch('subsec') * 1000
      WHERE key = 'settings.v3';
      SQL
    '';
  };

  opencode-desktop = pkgs.symlinkJoin {
    name = "opencode-desktop-${unwrapped.version}";
    paths = [ unwrapped ];
    # Shell wrapper, not binary: --run needs a shell.
    nativeBuildInputs = [ pkgs.makeWrapper ];
    # A launcher-started app may not inherit the shell's PATH; point the
    # claude-agent provider at Claude Code directly. A failed seed must not
    # keep the app from starting.
    postBuild = ''
      wrapProgram $out/bin/opencode-desktop \
        --run '${lib.getExe seedSettings} || true' \
        --set OPENCODE_CONFIG_CONTENT ${lib.escapeShellArg desktopConfig} \
        --set OPENCODE_CLAUDE_PATH ${config.programs.claude-code.finalPackage}/bin/claude
    '';
    inherit (unwrapped) meta;
  };
in
{
  assertions = [ {
    assertion = config.programs.opencode.enable;
    message = "OpenCode Desktop uses the shared programs.opencode configuration.";
  } ];

  home.packages = [ opencode-desktop ];

  # Let browser authentication return to the desktop app.
  xdg.mimeApps.defaultApplications."x-scheme-handler/opencode" = [ "ai.opencode.desktop.desktop" ];
}
