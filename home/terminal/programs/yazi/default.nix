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

      opener = {
        duckdb = [
          {
            run = ''duckdb -cmd "CREATE TABLE tbl AS FROM '$@';"'';
            block = true;
            desc = "Open in DuckDB";
          }
        ];
        duckdb-text = [
          {
            run = ''duckdb -cmd "CREATE TABLE tbl AS FROM read_csv('$@');"'';
            block = true;
            desc = "Open in DuckDB";
          }
        ];
        duckdb-excel = [
          {
            run = ''duckdb -cmd "INSTALL excel; LOAD excel;" -cmd "CREATE TABLE tbl AS FROM read_xlsx('$@');"'';
            block = true;
            desc = "Open in DuckDB";
          }
        ];
        duckdb-db = [
          {
            run = ''duckdb -cmd "INSTALL sqlite; LOAD sqlite;" "$@"'';
            block = true;
            desc = "Open in DuckDB";
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
          { url = "*.xlsx"; use = "duckdb-excel"; }
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
