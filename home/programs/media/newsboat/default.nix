{ pkgs, ... }:

# newsboat — terminal RSS, vim-keyed. Feeds migrated from rssguard
# (see ./urls; tags = old rssguard categories). The filelist.io feed was
# deliberately left out: its URL embeds a private passkey — secret, not
# for git. Re-add via sops if needed.
{
  home.packages = [ pkgs.newsboat ];

  # plain files instead of programs.newsboat so the urls list stays a
  # readable one-line-per-feed file rather than 84 Nix attrsets
  xdg.configFile."newsboat/urls".source = ./urls;

  xdg.configFile."newsboat/config".text = ''
    # behaviour
    auto-reload yes
    reload-time 30
    reload-threads 8
    show-read-feeds no
    cleanup-on-quit yes
    datetime-format "%Y-%m-%d"
    text-width 100

    # vim-style navigation
    bind-key j down
    bind-key k up
    bind-key J next-feed articlelist
    bind-key K prev-feed articlelist
    bind-key g home
    bind-key G end
    bind-key h quit articlelist
    bind-key l open feedlist

    # open links
    browser "xdg-open %u"
    macro o set browser "firefox --new-tab %u"; open-in-browser ; set browser "xdg-open %u"
    macro v set browser "uwsm app -- celluloid %u"; open-in-browser ; set browser "xdg-open %u"
    macro y set browser "echo %u | wl-copy"; open-in-browser ; set browser "xdg-open %u"
  '';
}
