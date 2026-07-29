# Nix-native Claude Code hooks.
#
# Two halves have to line up for a hook to do anything:
#   1. an executable that reads the event JSON on stdin  (built here)
#   2. a registration in settings.json under `hooks`      (exported here)
#
# `programs.claude-code.hooksDir` only does (1), and only as 0444 files with no
# exec bit — so scripts placed there are inert. Building each script with
# writeShellApplication instead gives an executable store path with its runtime
# deps pinned onto PATH, and shellchecks the body at build time: a typo in a
# hook fails `nixos-rebuild`, rather than silently disabling the hook.
{ pkgs }:

let
  # ./config/hooks/<name>.sh -> executable at ${drv}/bin/<name>
  # The scripts omit their own shebang and `set` line; writeShellApplication
  # prepends both (errexit/nounset/pipefail).
  mkHook =
    name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile (./config/hooks + "/${name}.sh");
    };

  blockNoVerify = mkHook "block-no-verify" [ pkgs.jq ];
  secretScan = mkHook "secret-scan" [ pkgs.jq ];
  shellcheckLint = mkHook "shellcheck-lint" [
    pkgs.jq
    pkgs.shellcheck
  ];
  nixParseCheck = mkHook "nix-parse-check" [
    pkgs.jq
    pkgs.nix
  ];
in
{
  # Individually addressable so a hook can be run by hand:
  #   nix build .#... / or just: <store-path>/bin/secret-scan < event.json
  packages = {
    inherit
      blockNoVerify
      secretScan
      shellcheckLint
      nixParseCheck
      ;
  };

  # Drop straight into programs.claude-code.settings.hooks
  settings = {
    PreToolUse = [
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "${blockNoVerify}/bin/block-no-verify";
            timeout = 10;
            statusMessage = "Checking for hook bypass...";
          }
        ];
      }
      {
        matcher = "Edit|Write|MultiEdit";
        hooks = [
          {
            type = "command";
            command = "${secretScan}/bin/secret-scan";
            timeout = 10;
            statusMessage = "Scanning for key material...";
          }
        ];
      }
    ];

    PostToolUse = [
      {
        matcher = "Edit|Write";
        hooks = [
          {
            type = "command";
            command = "${shellcheckLint}/bin/shellcheck-lint";
            timeout = 30;
            statusMessage = "shellcheck...";
          }
          {
            type = "command";
            command = "${nixParseCheck}/bin/nix-parse-check";
            timeout = 30;
            statusMessage = "Parsing nix...";
          }
        ];
      }
    ];
  };
}
