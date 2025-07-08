{ inputs, ... }:

{
  imports = [
    inputs.walker.homeManagerModules.default
  ];
  programs.walker = {
    enable = true;
    runAsService = true;
    config = {
      app_launch_prefix = "uwsm app -- ";
      keys = {
        accept_typeahead = [ "tab" ];
        trigger_labels = "lalt";
        next = [ "ctrl j" ];
        prev = [ "ctrl k" ];
        close = [ "esc" ];
        remove_from_history = [ "shift backspace" ];
        resume_query = [ "ctrl r" ];
        toggle_exact_search = [ "ctrl m" ];
        activation_modifiers = {
          keep_open = "shift";
          alternate = "alt";
        };
      };
      builtins = {
        bookmarks = {
          weight = 5;
          placeholder = "Bookmarks";
          name = "bookmarks";
          icon = "bookmark";
          switcher_only = true;
          entries = [
            {
              label = "Walker";
              url = "https://github.com/abenz1267/walker";
              keywords = [ "walker" "github" ];
            }
            {
              label = "Aurelio - Saturn";
              url = "https://github.com/aurelio-labs/saturn";
              keywords = [ "aurelio" "saturn" "github" ];
            }
            {
              label = "Alai - Spark";
              url = "https://github.com/alai-studios/spark";
              keywords = [ "alai" "spark" "github" ];
            }
          ];
        };
        clipboard = {
          exec = "wl-copy";
          height = 5;
          name = "clipboard";
          avoid_line_breaks = true;
          placeholder = "Clipboard";
          image_height = 300;
          max_entries = 10;
          switcher_only = true;
        };
        commands = {
          weight = 5;
          icon = "utilities-terminal";
          switcher_only = true;
          name = "commands";
          placeholder = "Commands";
        };
        switcher = {
          weight = 5;
          icon = "switcher";
          placeholder = "Switcher";
          prefix = "/";
        };
        translation = {
          provider = "googlefree";
        };
        websearch = {
          keep_selection = true;
          weight = 5;
          icon = "applications-internet";
          name = "websearch";
          placeholder = "Websearch";
          entries = [
            {
              name = "Google";
              url = "https://www.google.com/search?q=%TERM%";
            }
            {
              name = "DuckDuckGo";
              url = "https://duckduckgo.com/?q=%TERM%";
              switcher_only = true;
            }
          ];
        };
      };
    };
  };
}
