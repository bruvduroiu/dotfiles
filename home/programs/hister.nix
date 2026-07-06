{ config, pkgs, ... }:

let
  conf = config.xdg.configHome;
  home = config.home.homeDirectory;
  yamlFormat = pkgs.formats.yaml { };

  settings = {
    app = {
      directory = "${conf}/hister";
      search_url = "https://google.com/search?q={query}";
      log_level = "info";
      debug_sql = false;
    };
    server = {
      address = "127.0.0.1:4433";
      database = "${home}/Documents/hister.db";
    };
    hotkeys = {
      "alt+k" = "select_previous_result";
      "alt+j" = "select_next_result";
      "/" = "focus_search_input";
      enter = "open_result";
      "alt+enter" = "open_result_in_new_tab";
      "alt+o" = "open_query_in_search_engine";
      "alt+v" = "view_result_popup";
      tab = "autocomplete";
      "?" = "show_hotkeys";
    };
  };
in
{
  home.packages = with pkgs; [
    hister
  ];

  xdg.configFile."hister/config.yml".source = yamlFormat.generate "hister-config.yml" settings;

  systemd.user.services.hister = {
    Unit = {
      Description = "Hister - Web history listener";
      After = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hister}/bin/hister listen";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
