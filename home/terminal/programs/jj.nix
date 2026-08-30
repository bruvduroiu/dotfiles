{ config, pkgs, inputs, ... }:

{
  # Interactive TUI (log browsing, describe, squash, rebase) — the
  # diffview/fugitive stand-in until Helix grows a plugin system; the Helix
  # Space-j menu covers only the non-interactive jj commands.
  home.packages = [ pkgs.jjui ];

  programs.jujutsu = {
    enable = true;
    package = pkgs.jujutsu;

    settings = {
      user = {
        name = "Bogdan Buduroiu";
        email = inputs.secrets.vars.identity.email;
      };

      # GPG signing with YubiKey (same key as git - auto-selects signing subkey)
      signing = {
        behavior = "own";
        backend = "gpg";
        key = "0x785150ECAABF7352";
      };

      ui = {
        # Use delta for diffs (consistent with git delta integration)
        diff-formatter = [ "delta" "--color-only" ];
        pager = "delta";
        default-command = "log";
      };

      # Git backend settings
      git = {
        # Colocate clones (.git next to .jj): Helix's diff gutter and
        # version-control statusline read plain git, so non-colocated repos
        # would show no VCS state in the editor.
        colocate = true;
      };

      # Replaces the deprecated git.auto-local-bookmark (jj 0.41 warns on
      # every invocation otherwise).
      remotes.origin.auto-track-bookmarks = "*";

      revset-aliases = {
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
      };

      aliases = {
        # Drag the nearest bookmark up to the parent of @ — the standard
        # "point my branch at what I just finished" move before jj git push.
        tug = [ "bookmark" "move" "--from" "closest_bookmark(@-)" "--to" "@-" ];
      };
    };
  };
}
