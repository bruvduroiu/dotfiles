{
  programs.fzf = {
    enable = true;
    # ANSI-16 indexes and -1 (terminal default) instead of hex: fzf renders
    # with whatever palette the terminal currently shows, so it is always in
    # the right polarity — including inside shells that were already running
    # when the desktop theme changed (their exported FZF_DEFAULT_OPTS is frozen,
    # which is why stylix's hex target is disabled in theme/stylix.nix).
    # Same role mapping stylix used: iris for matches, gold for prompt/info,
    # foam for pointers.
    colors = {
      "fg" = "-1";
      "bg" = "-1";
      "fg+" = "-1";
      "bg+" = "0";
      "hl" = "5";
      "hl+" = "5";
      "header" = "5";
      "info" = "3";
      "prompt" = "3";
      "pointer" = "6";
      "marker" = "6";
      "spinner" = "6";
    };
  };
}
