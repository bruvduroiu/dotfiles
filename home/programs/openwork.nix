{ config, lib, pkgs, ... }:

let
  # OpenWork sanitizes the managed engine's environment and replaces its config
  # directory. Restore the declarative configuration at the executable boundary.
  opencodeV2 = pkgs.writeShellScript "openwork-opencode-v2" ''
    export OPENCODE_CONFIG=${lib.escapeShellArg "${config.xdg.configHome}/opencode/opencode.json"}
    export OPENCODE_CONFIG_DIR=${lib.escapeShellArg "${config.xdg.configHome}/opencode"}
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
