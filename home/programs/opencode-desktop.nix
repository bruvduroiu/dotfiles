{ config, lib, pkgs, ... }:

let
  codingMcps = import ../terminal/programs/coding-mcps { inherit config lib pkgs; };

  # MCPs only the desktop app gets (the `opencode-desktop` selection in
  # coding-mcps). opencode merges OPENCODE_CONFIG_CONTENT over
  # ~/.config/opencode, so terminal opencode, Claude Code and Codex never see
  # these. The desktop passes its environment through to the engine it starts.
  desktopConfig = builtins.toJSON {
    mcp = codingMcps.opencodeServers "opencode-desktop";
  };

  # Auto-accept is a UI setting persisted in the app's own state DB, not in
  # opencode.json; this only flips the default a fresh profile starts with.
  # A profile that already saved a choice keeps it (toggle: Mod+Shift+A).
  unwrapped = pkgs.opencode-desktop.overrideAttrs (old: {
    postPatch = old.postPatch + ''
      substituteInPlace packages/app/src/settings/model.tsx \
        --replace-fail 'permissions: { autoApprove: false,' 'permissions: { autoApprove: true,'
    '';
  });

  opencode-desktop = pkgs.symlinkJoin {
    name = "opencode-desktop-${unwrapped.version}";
    paths = [ unwrapped ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    # A launcher-started app may not inherit the shell's PATH; point the
    # claude-agent provider at Claude Code directly.
    postBuild = ''
      wrapProgram $out/bin/opencode-desktop \
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
