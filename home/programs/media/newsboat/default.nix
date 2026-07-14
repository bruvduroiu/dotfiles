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

  # bookmark-cmd target: save the full article as a markdown note in the Keep
  # vault. newsboat calls: <cmd> <url> <title> <description> <feed-title>
  newsboat-clip = pkgs.writeShellApplication {
    name = "newsboat-clip";
    runtimeInputs = [ pkgs.python3Packages.trafilatura pkgs.coreutils ];
    text = ''
      url=''${1:-}
      title=''${2:-untitled}
      desc=''${3:-}
      feed=''${4:-}

      dir="$HOME/Documents/Keep/5 - Main Notes"
      mkdir -p "$dir"

      # filename: article title, path-hostile chars -> _, whitespace collapsed
      safe=$(printf '%s' "$title" | tr '/\\:*?"<>|' '_________' | tr -s ' ' | sed 's/^ *//; s/ *$//')
      [ -z "$safe" ] && safe=untitled
      file="$dir/$safe.md"
      n=1
      while [ -e "$file" ]; do
        file="$dir/$safe ($n).md"
        n=$((n + 1))
      done

      # full text via trafilatura; fall back to feed description on failure
      body=$(trafilatura -u "$url" --markdown 2>/dev/null || true)
      [ -z "$body" ] && body="$desc"

      # escape double-quotes for YAML frontmatter values
      esc() { printf '%s' "$1" | sed 's/"/\\"/g'; }
      today=$(date +%Y-%m-%d)

      {
        printf -- '---\n'
        printf 'title: "%s"\n' "$(esc "$title")"
        printf 'source: "%s"\n' "$(esc "$url")"
        printf 'feed: "%s"\n' "$(esc "$feed")"
        printf 'date: %s\n' "$today"
        printf 'topic: ""\n'
        printf 'tags: [clipping]\n'
        printf -- '---\n\n'
        printf '%s\n' "$body"
      } > "$file"
    '';
  };

  # notify-program target: notify-format string arrives as args
  newsboat-notify = pkgs.writeShellApplication {
    name = "newsboat-notify";
    runtimeInputs = [ pkgs.libnotify ];
    text = ''
      notify-send --app-name=newsboat "Newsboat" "$*"
    '';
  };
in
{
  # trafilatura + the two helper wrappers; the newsboat package itself comes
  # from programs.newsboat.package below.
  home.packages = [
    pkgs.python3Packages.trafilatura
    newsboat-clip
    newsboat-notify
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

      # capture → Obsidian (Keep vault, 5 - Main Notes/)
      bookmark-cmd "${newsboat-clip}/bin/newsboat-clip"
      bookmark-autopilot yes

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
      bind-key b bookmark
      bind-key A mark-feed-read
      bind-key C mark-all-feeds-read
      bind-key U show-urls
      bind-key R reload-all
      bind-key s sort
      bind-key S rev-sort

      # open links — quoted browser must live here, not the module's `browser`
      # option (the module renders it unquoted, dropping everything past `uwsm`)
      browser "uwsm app -- xdg-open %u"
      macro o set browser "uwsm app -- firefox --new-tab %u"; open-in-browser ; set browser "uwsm app -- xdg-open %u"
      macro v set browser "uwsm app -- celluloid %u"; open-in-browser ; set browser "uwsm app -- xdg-open %u"
      # full-text on demand — fetch the real article into vim even on truncated feeds
      macro f set browser "trafilatura -u %u --markdown --images 2>/dev/null | nvim -R -c 'set filetype=markdown' -"; open-in-browser ; set browser "uwsm app -- xdg-open %u"

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
