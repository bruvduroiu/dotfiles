{ config, lib, pkgs, ... }:

let
  codingMcps = import ../terminal/programs/coding-mcps { inherit config lib pkgs; };

  # MCPs only OpenWork gets (the `openwork` selection in coding-mcps). opencode
  # merges OPENCODE_CONFIG_CONTENT over OPENCODE_CONFIG, so terminal opencode,
  # Claude Code and Codex never see these.
  openworkConfig = lib.escapeShellArg (builtins.toJSON {
    mcp = codingMcps.opencodeServers "openwork";
  });

  # OpenWork sanitizes the managed engine's environment and replaces its config
  # directory. Restore the declarative configuration at the executable boundary.
  opencodeV2 = pkgs.writeShellScript "openwork-opencode-v2" ''
    export OPENCODE_CONFIG=${lib.escapeShellArg "${config.xdg.configHome}/opencode/opencode.json"}
    export OPENCODE_CONFIG_DIR=${lib.escapeShellArg "${config.xdg.configHome}/opencode"}
    export OPENCODE_CONFIG_CONTENT=${openworkConfig}
    # hey mcp reads its login from KeePassXC over the session bus; keep the
    # bus reachable if the sanitized environment dropped its address.
    export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(${pkgs.coreutils}/bin/id -u)/bus}"
    # Use the same model catalog as terminal OpenCode.
    unset OPENCODE_MODELS_URL
    # v2 stores credentials in its database. Use its normal database so token
    # refreshes and account selection stay shared with terminal OpenCode.
    unset OPENCODE_DB
    exec ${lib.getExe config.programs.opencode.package} "$@"
  '';
  openwork = pkgs.callPackage ../../pkgs/openwork.nix {
    inherit opencodeV2;
    runtimeProfile = ''
      # Use Home Manager's live OpenCode configuration, including its agents,
      # skills, custom tools, MCPs, permissions and sops file references.
      export OPENCODE_CONFIG=${lib.escapeShellArg "${config.xdg.configHome}/opencode/opencode.json"}
      export OPENCODE_CONFIG_DIR=${lib.escapeShellArg "${config.xdg.configHome}/opencode"}
      export OPENCODE_CONFIG_CONTENT=${openworkConfig}

      # Route chats through the same v2 package used by the terminal and jobs.
      export OPENWORK_ENGINE_V2_PREVIEW=chat
      export OPENWORK_OPENCODE2_BIN=${opencodeV2}
      export OPENWORK_ENGINE_AUTO_UPGRADE=0

      # The legacy engine may still start for history migration. Keep its v1
      # database separate; the v2 wrapper uses the normal shared database.
      export OPENCODE_DB=${lib.escapeShellArg "${config.xdg.dataHome}/openwork/opencode.db"}
      mkdir -p "$(dirname "$OPENCODE_DB")"
    '';
  };
in
{
  assertions = [ {
    assertion = config.programs.opencode.enable;
    message = "OpenWork uses the shared programs.opencode configuration.";
  } ];

  home.packages = [ openwork ];

  # Let browser authentication return to the desktop app.
  xdg.mimeApps.defaultApplications."x-scheme-handler/openwork" = [ "openwork.desktop" ];
}
