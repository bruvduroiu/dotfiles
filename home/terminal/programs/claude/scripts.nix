# Scripts that ship inside a skill directory *and* as binaries on PATH.
#
# A skill's SKILL.md may reference a helper script. Kept next to the skill
# (config/skills/<name>/scripts/*.sh) it travels with the skill when the
# directory is copied to a colleague and runs with plain `bash`. Built here
# with writeShellApplication it also becomes an executable store path with
# pinned deps and a build-time shellcheck — the same pattern as hooks.nix,
# from the same single source file.
{ pkgs, lib }:

let
  # Unlike the hook scripts, these carry their own shebang so they stay
  # runnable as files. writeShellApplication prepends its own; shellcheck
  # then flags the second one (SC1128, shebang not on line 1) and fails the
  # build, so strip it before wrapping. The duplicated `set -euo pipefail`
  # is harmless.
  mkScript =
    name: file: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = lib.removePrefix "#!/usr/bin/env bash\n" (builtins.readFile file);
    };

  jjStackCheck = mkScript "jj-stack-check" ./config/skills/jj-stack/scripts/stack-check.sh [
    pkgs.jujutsu
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
  ];
in
{
  packages = {
    inherit jjStackCheck;
  };
}
