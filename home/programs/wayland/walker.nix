{ inputs, ... }:

{
  imports = [
    inputs.walker.homeManagerModules.default
  ];
  programs.walker = {
    enable = true;
    runAsService = true;
    config = {
      # Global UX settings
      force_keyboard_focus = false;
      close_when_open = true;
      click_to_close = true;
      single_click_activation = true;
      selection_wrap = false;
      global_argument_delimiter = "#";
      exact_search_prefix = "'";
      theme = "default";
      disable_mouse = false;
      debug = false;
      page_jump_items = 10;
      hide_quick_activation = false;
      hide_action_hints = false;
      hide_action_hints_dmenu = true;
      hide_return_action = false;
      resume_last_query = false;
      actions_as_menu = false;

      app_launch_prefix = "uwsm app -- ";

      # Shell anchoring for proper positioning
      shell = {
        anchor_top = true;
        anchor_bottom = true;
        anchor_left = true;
        anchor_right = true;
      };

      # Column configuration for grid layouts
      columns = {
        symbols = 3;
      };

      # Placeholders for empty states
      placeholders = {
        default = {
          input = "Search";
          list = "No Results";
        };
      };

      # Keybinds - preserving your vim-style navigation
      keys = {
        close = [ "esc" ];
        next = [ "ctrl j" ];  # vim-style
        prev = [ "ctrl k" ];  # vim-style
        left = [ "Left" ];
        right = [ "Right" ];
        down = [ "ctrl j" ];
        up = [ "ctrl k" ];
        accept_typeahead = [ "tab" ];
        trigger_labels = "lalt";
        toggle_exact_search = [ "ctrl m" ];
        resume_query = [ "ctrl r" ];
        remove_from_history = [ "shift backspace" ];
        quick_activate = [ "F1" "F2" "F3" "F4" ];
        page_down = [ "Page_Down" ];
        page_up = [ "Page_Up" ];
        show_actions = [ "alt j" ];
        activation_modifiers = {
          keep_open = "shift";
          alternate = "alt";
        };
      };

      # Provider configuration
      providers = {
        default = [
          "desktopapplications"
          "calc"
          "websearch"
        ];
        empty = [ "desktopapplications" ];
        ignore_preview = [ ];
        max_results = 50;

        # Prefix-based quick access
        prefixes = [
          { prefix = ";"; provider = "providerlist"; }
          { prefix = ">"; provider = "runner"; }
          { prefix = "/"; provider = "files"; }
          { prefix = "."; provider = "symbols"; }
          { prefix = "!"; provider = "todo"; }
          { prefix = "%"; provider = "bookmarks"; }
          { prefix = "="; provider = "calc"; }
          { prefix = "@"; provider = "websearch"; }
          { prefix = ":"; provider = "clipboard"; }
          { prefix = "$"; provider = "windows"; }
        ];

        # Provider-specific configuration
        clipboard = {
          time_format = "relative";
        };

        # Provider-specific actions
        actions = {
          fallback = [
            { action = "menus:open"; label = "open"; after = "Nothing"; }
            { action = "menus:default"; label = "run"; after = "Close"; }
            { action = "menus:parent"; label = "back"; bind = "Escape"; after = "Nothing"; }
            { action = "erase_history"; label = "clear hist"; bind = "ctrl h"; after = "AsyncReload"; }
          ];

          dmenu = [
            { action = "select"; default = true; bind = "Return"; }
          ];

          providerlist = [
            { action = "activate"; default = true; bind = "Return"; after = "ClearReload"; }
          ];

          calc = [
            { action = "copy"; default = true; bind = "Return"; }
            { action = "delete"; bind = "ctrl d"; after = "AsyncReload"; }
            { action = "delete_all"; bind = "ctrl shift d"; after = "AsyncReload"; }
            { action = "save"; bind = "ctrl s"; after = "AsyncClearReload"; }
          ];

          websearch = [
            { action = "search"; default = true; bind = "Return"; }
            { action = "open_url"; label = "open url"; default = true; bind = "Return"; }
          ];

          desktopapplications = [
            { action = "start"; default = true; bind = "Return"; }
            { action = "start:keep"; label = "open+next"; bind = "shift Return"; after = "KeepOpen"; }
            { action = "new_instance"; label = "new instance"; bind = "ctrl Return"; }
            { action = "new_instance:keep"; label = "new+next"; bind = "ctrl alt Return"; after = "KeepOpen"; }
            { action = "pin"; bind = "ctrl p"; after = "AsyncReload"; }
            { action = "unpin"; bind = "ctrl p"; after = "AsyncReload"; }
            { action = "pinup"; bind = "ctrl n"; after = "AsyncReload"; }
            { action = "pindown"; bind = "ctrl m"; after = "AsyncReload"; }
          ];

          files = [
            { action = "open"; default = true; bind = "Return"; }
            { action = "opendir"; label = "open dir"; bind = "ctrl Return"; }
            { action = "copypath"; label = "copy path"; bind = "ctrl shift c"; }
            { action = "copyfile"; label = "copy file"; bind = "ctrl c"; }
            { action = "localsend"; label = "localsend"; bind = "ctrl l"; }
            { action = "refresh_index"; label = "reload"; bind = "ctrl r"; after = "AsyncReload"; }
          ];

          runner = [
            { action = "run"; default = true; bind = "Return"; }
            { action = "runterminal"; label = "run in terminal"; bind = "shift Return"; }
          ];

          symbols = [
            { action = "run_cmd"; label = "select"; default = true; bind = "Return"; }
          ];

          unicode = [
            { action = "run_cmd"; label = "select"; default = true; bind = "Return"; }
          ];

          clipboard = [
            { action = "copy"; default = true; bind = "Return"; }
            { action = "remove"; bind = "ctrl d"; after = "AsyncClearReload"; }
            { action = "remove_all"; label = "clear"; bind = "ctrl shift d"; after = "AsyncClearReload"; }
            { action = "show_images_only"; label = "only images"; bind = "ctrl i"; after = "AsyncClearReload"; }
            { action = "show_text_only"; label = "only text"; bind = "ctrl i"; after = "AsyncClearReload"; }
            { action = "show_combined"; label = "show all"; bind = "ctrl i"; after = "AsyncClearReload"; }
            { action = "pause"; bind = "ctrl shift p"; }
            { action = "unpause"; bind = "ctrl shift p"; }
            { action = "unpin"; bind = "ctrl p"; after = "AsyncClearReload"; }
            { action = "pin"; bind = "ctrl p"; after = "AsyncClearReload"; }
            { action = "edit"; bind = "ctrl o"; }
            { action = "localsend"; bind = "ctrl l"; }
          ];

          bookmarks = [
            { action = "save"; bind = "Return"; after = "AsyncClearReload"; }
            { action = "open"; default = true; bind = "Return"; }
            { action = "delete"; bind = "ctrl d"; after = "AsyncClearReload"; }
            { action = "change_category"; label = "Change category"; bind = "ctrl y"; after = "Nothing"; }
            { action = "change_browser"; label = "Change browser"; bind = "ctrl b"; after = "Nothing"; }
            { action = "import"; label = "Import"; bind = "ctrl i"; after = "AsyncClearReload"; }
            { action = "create"; bind = "ctrl a"; after = "AsyncClearReload"; }
            { action = "search"; bind = "ctrl a"; after = "AsyncClearReload"; }
          ];

          todo = [
            { action = "save"; default = true; bind = "Return"; after = "AsyncClearReload"; }
            { action = "save_next"; label = "save & new"; bind = "shift Return"; after = "AsyncClearReload"; }
            { action = "delete"; bind = "ctrl d"; after = "AsyncClearReload"; }
            { action = "active"; default = true; bind = "Return"; after = "Nothing"; }
            { action = "inactive"; default = true; bind = "Return"; after = "Nothing"; }
            { action = "done"; bind = "ctrl f"; after = "Nothing"; }
            { action = "change_category"; bind = "ctrl y"; label = "change category"; after = "Nothing"; }
            { action = "clear"; bind = "ctrl x"; after = "AsyncClearReload"; }
            { action = "create"; bind = "ctrl a"; after = "AsyncClearReload"; }
            { action = "search"; bind = "ctrl a"; after = "AsyncClearReload"; }
          ];
        };
      };

      # Builtins configuration
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
        theme = {
          weight = 5;
          icon = "switcher";
          placeholder = "Theme";
          prefix = "theme";
          exec = "hyprland-theme-switcher";
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
