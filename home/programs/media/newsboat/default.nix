{ pkgs, lib, ... }:

# newsboat — terminal RSS, vim-keyed. Feeds migrated from Read You
# (Read-You OPML export; tags = old reader categories). The filelist.io feed
# was deliberately left out: its URL embeds a private passkey — secret, not
# for git. Re-add via sops if needed.
#
# Uses the programs.newsboat HM module for the numeric/bool knobs + package,
# but urls stays a plain readable file (urls = [] keeps the module from
# writing it, so ./urls wins with no collision — feeds are one-line-per-feed,
# not 84 Nix attrsets) and the rich config lives in extraConfig. The browser
# command must be quoted, so it goes in extraConfig, NOT the browser option
# (the module writes `browser` unquoted and would keep only the first token).
let
  # category tags in navigation priority order. KEEP IN SYNC with the tags
  # actually used in ./urls: `grep -oE '^\S+ +[a-z0-9]+' urls | awk '{print $2}' | sort -u`
  feedTags = [
    "dev"
    "ai"
    "theory"
    "society"
    "taiwan"
    "easteur"
    "eupol"
    "finance"
    "energy"
    "science"
    "maker"
    "food"
    "personal"
  ];

  # one virtual query feed per tag: unread articles carrying that tag. Turns the
  # flat 138-feed unread wall into counted, per-topic buckets at the top of the
  # feedlist. Enter a bucket, then walk it with next-unread (n / N).
  mkBucket = tag: ''"query:${tag} ∙ unread:tags # \"${tag}\" and unread = \"yes\""'';
  bucketQueries = lib.concatMapStringsSep "\n" mkBucket feedTags;

  # notify-program target: notify-format string arrives as args
  newsboat-notify = pkgs.writeShellApplication {
    name = "newsboat-notify";
    runtimeInputs = [ pkgs.libnotify ];
    text = ''
      notify-send --app-name=newsboat "Newsboat" "$*"
    '';
  };

  # full-text view: many feeds ship a teaser-only <description>, so this fetches
  # the article's real page and renders it readability-style in a pager. Used as
  # a throwaway `browser` by the `f` binding below — newsboat single-quotes %u
  # before handing the command to the shell, so the URL arrives as one argv
  # element and needs no quoting from us. open-in-browser runs it in the
  # foreground, which is what lets less take over the terminal.
  newsboat-reader = pkgs.writeShellApplication {
    name = "newsboat-reader";
    runtimeInputs = [
      pkgs.reader
      pkgs.less
      pkgs.ncurses # tput
      pkgs.coreutils
    ];
    text = ''
      url="''${1:-}"
      if [ -z "$url" ]; then
        echo "usage: newsboat-reader <url>" >&2
        exit 2
      fi

      # reader's auto width detection measures its stdout, which is a file here,
      # so pass the width explicitly. Cap at 100 to match newsboat's text-width.
      cols=$(tput cols 2>/dev/null || echo 100)
      if [ "$cols" -gt 100 ]; then
        cols=100
      fi

      out=$(mktemp)
      err=$(mktemp)
      trap 'rm -f "$out" "$err"' EXIT

      # buffered rather than piped straight into less: a fetch failure should
      # land in the pager as a readable message, not as a half-empty page
      printf 'reader: fetching %s …\n' "$url"
      if ! reader --image-mode ansi --terminal-width "$cols" -- "$url" \
        >"$out" 2>"$err"; then
        {
          printf '\nreader failed on %s\n\n' "$url"
          cat "$err"
        } >>"$out"
      fi

      less -R -- "$out"
    '';
  };
in
{
  # helper wrapper; the newsboat package itself comes
  # from programs.newsboat.package below.
  home.packages = [
    newsboat-notify
    newsboat-reader
  ];

  programs.newsboat = {
    enable = true;

    # urls managed imperatively-as-file: leaving this empty stops the module
    # writing xdg.configFile."newsboat/urls" so ./urls below is the sole source.
    urls = [ ];

    # numeric/bool knobs the module renders for us (no quoting hazards)
    autoReload = true;
    reloadTime = 30;
    reloadThreads = 8;

    extraConfig = ''
      # behaviour
      show-read-feeds no
      cleanup-on-quit yes
      datetime-format "%Y-%m-%d"
      text-width 100

      # killfile — hide obvious junk; extend as needed
      ignore-mode "display"
      ignore-article "*" "title =~ \"[Ss]ponsored|[Aa]dvertisement\""

      # triage
      # newsboat 2.41 inverts the date direction: date-asc = NEWEST first
      # (verified empirically; the man page says the opposite and is wrong here)
      article-sort-order date-asc
      articlelist-format "%4i %f %D  %?T?|%-17T|  ?%t"
      feedlist-format    "%4i %n %11u  %t"
      highlight article "[Tt]aiwan|[Kk]ubernetes|[Nn]ix([Oo][Ss])?|[Bb]ogdan|[Bb]uduroiu" yellow default bold

      # notifications (global — fires for any new articles)
      notify-program "${newsboat-notify}/bin/newsboat-notify"
      notify-format "newsboat: %d new (%n unread)"
      notify-always no

      # vim-style navigation
      bind-key j down
      bind-key k up
      bind-key J next-feed articlelist
      bind-key K prev-feed articlelist
      bind-key h quit articlelist
      bind-key l open feedlist
      # narrow the 138-feed feedlist to one category tag; ^T clears the filter
      bind-key t  set-tag   feedlist
      bind-key ^T clear-tag feedlist

      # vim chords & operators — `bind` (2.38+) takes a key sequence, a dialog
      # context, and a macro-style op-list, unlike single-key bind-key
      bind gg everywhere home
      bind G everywhere end
      bind N everywhere prev-unread -- "previous unread (n = next, built-in)"
      bind dd articlelist toggle-article-read ; down -- "mark read + advance"
      bind yy everywhere set browser "echo %u | wl-copy" ; open-in-browser ; set browser "uwsm app -- xdg-open %u" -- "yank article url"
      bind ^D article halfpagedown
      bind ^U article halfpageup
      bind ^E article down
      bind ^Y article up
      # half-page paging in the lists too (feedlist has 138 feeds + buckets)
      bind ^D feedlist     halfpagedown
      bind ^U feedlist     halfpageup
      bind ^D articlelist  halfpagedown
      bind ^U articlelist  halfpageup
      bind-key F edit-flags
      bind-key A mark-feed-read
      bind-key C mark-all-feeds-read
      bind-key U show-urls
      bind-key R reload-all
      bind-key s sort
      bind-key S rev-sort

      # open links — quoted browser must live here, not the module's `browser`
      # option (the module renders it unquoted, dropping everything past `uwsm`)
      browser "uwsm app -- xdg-open %u"
      # f — full text: Enter still shows the feed's own (often truncated) body,
      # this fetches the linked page and renders it via reader in less. Same
      # swap-browser-then-restore trick as the macros below; `bind` is used
      # instead of `macro` so it stays a single keypress in the reading dialogs.
      bind f article,articlelist,urlview set browser "${newsboat-reader}/bin/newsboat-reader %u" ; open-in-browser ; set browser "uwsm app -- xdg-open %u" -- "full text (reader)"
      macro o set browser "uwsm app -- firefox --new-tab %u"; open-in-browser ; set browser "uwsm app -- xdg-open %u"
      macro v set browser "uwsm app -- celluloid %u"; open-in-browser ; set browser "uwsm app -- xdg-open %u"

      # colors — palette slots inherit the stylix-themed terminal
      color background        default default
      color listnormal        default default
      color listnormal_unread default default bold
      color listfocus         color0  color4
      color listfocus_unread  color0  color4  bold
      color info              color4  default bold
      color article           default default
    '';
  };

  # plain file instead of programs.newsboat.urls so the urls list stays a
  # readable one-line-per-feed file rather than 84 Nix attrsets. The per-tag
  # unread buckets are generated from feedTags and prepended, so they sit at
  # the top of the feedlist above the hand-curated special queries + feeds.
  xdg.configFile."newsboat/urls".text = ''
    # ── category unread buckets (generated in Nix from feedTags) ──────────
    ${bucketQueries}

  ''
  + builtins.readFile ./urls;
}
