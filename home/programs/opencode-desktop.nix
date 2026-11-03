{ config, lib, pkgs, inputs, ... }:

let
  codingMcps = import ../terminal/programs/coding-mcps { inherit config lib pkgs; };

  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # MCPs only the desktop app gets (the `opencode-desktop` selection in
  # coding-mcps). opencode merges OPENCODE_CONFIG_CONTENT over
  # ~/.config/opencode, so terminal opencode, Claude Code and Codex never see
  # these. The desktop passes its environment through to the engine it starts.
  desktopConfig = builtins.toJSON {
    mcp = codingMcps.opencodeServers "opencode-desktop";
  };

  opencode-desktop = pkgs.symlinkJoin {
    name = "opencode-desktop-${pkgs-unstable.opencode-desktop.version}";
    paths = [ pkgs-unstable.opencode-desktop ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode-desktop \
        --set OPENCODE_CONFIG_CONTENT ${lib.escapeShellArg desktopConfig}
    '';
    inherit (pkgs-unstable.opencode-desktop) meta;
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
