{ lib, pkgs, ... }:

let
  skepsisAgent = pkgs.writeShellApplication {
    name = "skepsis-agent";
    text = ''
      export SKEPSIS_BIN=${lib.getExe pkgs.skepsis}
      export SKEPSIS_CODEX=${lib.getExe pkgs.codex}
      exec ${pkgs.python3}/bin/python3 ${./coding-agents/skepsis-agent.py} "$@"
    '';
  };
in
{
  home.packages = [
    pkgs.skepsis
    skepsisAgent
  ];
  home.shellAliases.sk = "skepsis";

  # jj review: branch vs trunk; jj review -r @: just the working revision.
  # Each invocation serves a local browser UI until stopped with Ctrl-C.
  programs.jujutsu.settings.aliases.review = [
    "util"
    "exec"
    "--"
    (lib.getExe pkgs.skepsis)
  ];
}
