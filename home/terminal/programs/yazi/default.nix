{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {

  home.packages = with pkgs; [
    glow
    exiftool
    duckdb
    mediainfo
  ];

  programs.yazi = {
    enable = true;

    package = inputs.yazi.packages.${pkgs.stdenv.hostPlatform.system}.default;

    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    shellWrapperName = "y";

    plugins = with pkgs.yaziPlugins; {
      duckdb = duckdb;
      mediainfo = mediainfo;
    };

    settings = {
      mgr = {
        layout = [1 3 4];
        sort_by = "alphabetical";
        sort_sensitive = true;
        sort_reverse = false;
        sort_dir_first = true;
        linemode = "mtime";
        show_hidden = false;
        show_symlink = true;
      };

      preview = {
        tab_size = 2;
        max_width = 600;
        max_height = 900;
        cache_dir = "${config.xdg.cacheHome}/yazi";
      };

      plugin = {
        prepend_previewers = let
          duckdb = map (type: {
            run = "duckdb";
            url = "*.${type}";
          }) ["csv" "tsv" "parquet" "xlsx" "duckdb"];
        in [
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
          {
            mime = "application/subrip";
            run = "mediainfo";
          }
        ] ++ duckdb;

        prepend_preloaders = let
          duckdb = map (type: {
            run = "duckdb";
            url = "*.${type}";
            multi = false;
          }) ["csv" "tsv" "parquet" "xlsx"];
        in [
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
          {
            mime = "application/subrip";
            run = "mediainfo";
          }
        ] ++ duckdb;
      };

      # Openers use yazi's `%s` placeholder (shell-escaped selection), not the
      # old `$@` — current yazi passes no positional args, so `$@` expanded to
      # nothing and every duckdb query ran against an empty path.
      # `set -- %s` re-anchors it as `$1` so paths with spaces survive the
      # trip into the SQL string literal.
      opener = {
        # Inside a zellij session (the Alt+y overlay), zj-edit sends
        # `:open <file>` to the Helix pane instead of starting a second hx;
        # outside one it is plain hx. See ../zellij/zj-edit.sh.
        edit = [
          {
            run = ''zj-edit %s'';
            block = true;
            desc = "Open in Helix";
          }
        ];
        duckdb = [
          {
            run = ''set -- %s; duckdb -cmd "CREATE TABLE tbl AS FROM '$1';"'';
            block = true;
            desc = "Open in DuckDB";
          }
        ];
        duckdb-text = [
          {
            run = ''set -- %s; duckdb -cmd "CREATE TABLE tbl AS FROM read_csv('$1');"'';
            block = true;
            desc = "Open in DuckDB";
          }
        ];
        duckdb-excel = [
          {
            # header = true: sheets whose header row mixes text and numeric
            # labels (e.g. year columns) defeat duckdb's sniffer, which then
            # names columns A1, B1, ... and treats the header as data.
            run = ''set -- %s; duckdb -cmd "INSTALL excel; LOAD excel;" -cmd "CREATE TABLE tbl AS FROM read_xlsx('$1', header = true);"'';
            block = true;
            desc = "Open in DuckDB";
          }
        ];
        duckdb-db = [
          {
            run = ''duckdb -cmd "INSTALL sqlite; LOAD sqlite;" %s'';
            block = true;
            desc = "Open in DuckDB";
          }
        ];
        libreoffice = [
          {
            run = ''libreoffice %s'';
            orphan = true;
            desc = "Open in LibreOffice";
          }
        ];
      };

      open = {
        prepend_rules = [
          { url = "*.html"; use = [ "open" "edit"]; }
          { url = "*.parquet"; use = "duckdb"; }
          { url = "*.json"; use = "duckdb"; }
          { url = "*.csv"; use = "duckdb-text"; }
          { url = "*.tsv"; use = "duckdb-text"; }
          # Enter -> duckdb; `O` (open interactively) offers LibreOffice too.
          { url = "*.xlsx"; use = ["duckdb-excel" "libreoffice"]; }
          { url = "*.db"; use = "duckdb-db"; }
          { url = "*.duckdb"; use = "duckdb-db"; }
          { url = "*.sqlite"; use = "duckdb-db"; }
          { url = "*.sqlite3"; use = "duckdb-db"; }
        ];
      };
    };

    keymap.mgr.prepend_keymap = [
      {
        on = ["<C-n>"];
        run = ''shell '${lib.getExe pkgs.ripdrag} "$@" -x 2>/dev/null &' --confirm'';
      }
      # Workbench for the hovered directory (or the hovered file's directory)
      # in a new ghostty window: attach if a session exists, else create one.
      {
        on = "W";
        run = ''shell 'ghostty +new-window -e zj "$0"' --orphan'';
        desc = "Open zellij workbench here";
      }
      # duckdb
      {
        on = "<C-h>";
        run = "plugin duckdb -1";
        desc = "Scroll one column to the left";
      }
      {
        on = "<C-l>";
        run = "plugin duckdb +1";
        desc = "Scroll one column to the right";
      }
      {
        on = ["g" "u"];
        run = "plugin duckdb -ui";
        desc = "Open with duckdb ui";
      }
    ];

    initLua = ''
      require("duckdb"):setup()
    '';
  };
}
