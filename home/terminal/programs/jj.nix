{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  jjuiDeltaPreview = command: [
    "util"
    "exec"
    "--"
    (lib.getExe pkgs.bash)
    "-o"
    "pipefail"
    "-c"
    ''
      ${lib.getExe pkgs.jujutsu} "$1" --git --color never --no-pager -r "$2" "''${@:3}" |
        ${lib.getExe config.programs.delta.finalPackage} --paging=never
    ''
    "jjui-delta-preview"
    command
  ];
in
{
  # Interactive TUI (log browsing, describe, squash, rebase) — the
  # diffview/fugitive stand-in until Helix grows a plugin system; the Helix
  # Space-j menu covers only the non-interactive jj commands.
  home.packages = with pkgs; [ lazyjj ];

  programs = {
    jujutsu = {
      enable = true;
      package = pkgs.jujutsu;

      settings = {
        user = {
          name = "Bogdan Buduroiu";
          email = inputs.secrets.vars.identity.email;
        };

        # GPG signing with YubiKey (same key as git - auto-selects signing subkey).
        # behavior "drop" = never sign locally (and shed stale signatures on
        # rewrite); pairs with git.sign-on-push below, which batch-signs at push.
        # "own" is wrong for a touch-required key: it signs every rewrite of @,
        # and jj snapshots @ on every command — one touch per rewritten commit.
        signing = {
          behavior = "drop";
          backend = "gpg";
          key = "0x785150ECAABF7352";
        };

        ui = {
          default-command = "log";
        };

        # Git backend settings
        git = {
          # Colocate clones (.git next to .jj): Helix's diff gutter and
          # version-control statusline read plain git, so non-colocated repos
          # would show no VCS state in the editor.
          colocate = true;

          # Sign mutable unsigned commits at `jj git push` — the only signing
          # step, per signing.behavior = "drop" above. Local commits stay
          # unsigned until they reach a remote.
          sign-on-push = true;
        };

        # Replaces the deprecated git.auto-local-bookmark (jj 0.41 warns on
        # every invocation otherwise).
        remotes.origin.auto-track-bookmarks = "*";

        revset-aliases = {
          "closest_bookmark(to)" = "heads(::to & bookmarks())";
        };

        # Structural diff for the skim pass: difftastic compares syntax trees,
        # so refactor-shaped noise (reindents, moved functions, reordered args)
        # collapses to nothing. delta stays the default formatter; `jj dt` is
        # the first read of a large agent-generated diff, delta the close read.
        merge-tools.difft = {
          program = lib.getExe pkgs.difftastic;
          diff-args = [
            "--color=always"
            "$left"
            "$right"
          ];
        };

        aliases = {
          # Drag the nearest bookmark up to the parent of @ — the standard
          # "point my branch at what I just finished" move before jj git push.
          dt = [
            "diff"
            "--tool"
            "difft"
          ];
        };
      };
    };
    jjui = {
      enable = true;
      settings = {
        preview = {
          positions = "auto";
          file_command = jjuiDeltaPreview "diff" ++ [
            "$change_id"
            "--"
            "$file"
          ];
          revision_command = jjuiDeltaPreview "show" ++ [ "$change_id" ];
          show_at_start = true;
        };
        keys.preview = {
          half_page_down = [ "ctrl+d" ];
          half_page_up = [ "ctrl+u" ];
        };
      };
    };
  };
}
