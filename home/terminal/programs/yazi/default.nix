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
  ];

  programs.yazi = {
    enable = true;

    package = inputs.yazi.packages.${pkgs.system}.default;

    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    shellWrapperName = "y";

    plugins = with pkgs.yaziPlugins; {
      duckdb = duckdb;
      mediainfo = mediainfo;
    };

    settings = {
      mgr = {
        layout = [1 4 3];
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
          }) ["csv" "tsv" "json" "parquet" "txt" "xlsx" "db" "duckdb"];
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
          }) ["csv" "tsv" "json" "parquet" "txt" "xlsx"];
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
    };

    keymap.manager.prepend_keymap = [
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
        on = ["g" "o"];
        run = "plugin duckdb -open";
        desc = "Open with duckdb";
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
