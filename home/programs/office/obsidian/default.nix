{
  config,
  lib,
  pkgs,
  ...
}:

let
  # md2pdf integration is opt-in per host (see programs.md2pdf.obsidian.enable).
  # The command + hotkey below are only added when enabled, so hosts without it
  # (and its chromium closure) stay lean.
  mdCfg = config.programs.md2pdf;

  # Shared app.json defaults. The obsidian module merges `settings` per
  # top-level key (app/appearance/...), NOT deeply — a vault that sets
  # `settings.app` replaces this whole block, so reuse it explicitly.
  appDefaults = {
    defaultViewMode = "preview";
    tabSize = 2;
    vimMode = false;
    focusNewTab = true;
    propertiesInDocument = "visible";
    foldHeading = true;
    foldIndent = true;
    rightToLeft = false;
    spellcheck = true;
    autoPairBrackets = true;
    autoPairMarkdown = true;
    smartIndentList = true;
    useTab = true;
    autoConvertHtml = true;
    promptDelete = false;
    trashOption = "local";
    alwaysUpdateLinks = false;
    newFileLocation = "current";
    newLinkFormat = "shortest";
    useMarkdownLinks = false;
    showUnsupportedFiles = true;
  };

  # One Shell-commands `data.json` command entry. Mirrors the plugin's
  # newShellCommandConfiguration() exactly — the module writes data.json as a
  # read-only store symlink, and Shell commands uses the loaded file as-is (it only
  # merges defaults to backfill `debug`/`settings_version`), so every field a current
  # install expects must be present or command registration can throw.
  mkShellCommand = id: alias: command: {
    inherit id alias;
    platform_specific_commands.default = command;
    shells = { };
    icon = null;
    confirm_execution = false;
    ignore_error_codes = [ ];
    input_contents.stdin = null;
    output_handlers = {
      stdout = {
        handler = "ignore";
        convert_ansi_code = true;
      };
      stderr = {
        handler = "notification";
        convert_ansi_code = true;
      };
    };
    output_wrappers = {
      stdout = null;
      stderr = null;
    };
    output_channel_order = "stdout-first";
    output_handling_mode = "buffered";
    execution_notification_mode = null;
    events = { };
    debounce = null;
    command_palette_availability = "enabled";
    preactions = [ ];
    variable_default_values = { };
  };

  # Shell commands' built-in shells hardcode /bin/bash, /bin/dash, /bin/zsh in
  # getBinaryPath() and spawn THAT (the configured shell string only drives matching) —
  # none of those exist on NixOS, which provides only /bin/sh. So a built-in shell is
  # unusable here by construction (an unset shell falls back to $SHELL=fish, which the
  # plugin also doesn't support). Define a custom shell pinned to /bin/sh instead.
  # Mirrors CustomShellModel.getDefaultConfiguration(); our command is an absolute-path
  # binary, so a POSIX sh is all that is needed.
  nixShellId = "nixos-binsh";
  nixShell = {
    id = nixShellId;
    name = "NixOS /bin/sh";
    description = "POSIX sh via /bin/sh — built-in shells hardcode nonexistent /bin/bash and /bin/dash on NixOS.";
    binary_path = "/bin/sh";
    shell_arguments = [
      "-c"
      "{{shell_command_content}}"
    ];
    host_platform = "linux";
    host_platform_configurations = { };
    shell_platform = null;
    escaper = "UnixShell";
    path_translator = null;
    shell_command_wrapper = null;
    shell_command_test = null;
  };

  # Full SC_MainSettings default object (settings_version pinned to the packaged
  # plugin version, so no migration runs against the read-only file) + our command.
  shellcommandsSettings = {
    settings_version = "0.23.0";
    debug = false;
    obsidian_command_palette_prefix = "Execute: ";
    preview_variables_in_command_palette = true;
    show_autocomplete_menu = true;
    working_directory = "";
    default_shells = {
      linux = nixShellId;
    };
    environment_variable_path_augmentations = { };
    show_installation_warnings = true;
    error_message_duration = 20;
    notification_message_duration = 10;
    execution_notification_mode = "disabled";
    output_channel_clipboard_also_outputs_to_notification = true;
    output_channel_notification_decorates_output = true;
    enable_events = true;
    approve_modals_by_pressing_enter_key = true;
    command_palette.re_execute_last_shell_command = {
      enabled = true;
      prefix = "Re-execute: ";
    };
    max_visible_lines_in_shell_command_fields = false;
    shell_commands = lib.optionals mdCfg.obsidian.enable [
      # {{file_path:absolute}} → the active note; md2pdf writes <note>.pdf beside it.
      (mkShellCommand "md2pdf-export" "Export: note -> PDF (md2pdf)"
        "${mdCfg.package}/bin/md2pdf --theme ${mdCfg.defaultTheme} {{file_path:absolute}}"
      )
    ];
    prompts = [ ];
    builtin_variables = { };
    custom_variables = [ ];
    custom_variables_notify_changes_via = {
      obsidian_uri = true;
      output_assignment = true;
    };
    custom_shells = [ nixShell ];
    output_wrappers = [ ];
  };
in
{
  # scripts/ holds version-controlled backups of files that live in the Keep
  # vault directly (synced via Syncthing) — `extraFiles` can only target
  # .obsidian/, not vault content. The Blog vault has no such backups: its
  # template lives in the website repo itself (content/templates/).

  programs.obsidian = {
    enable = true;
    package = pkgs.obsidian;
    vaults = {
      Keep = {
        enable = true;
        target = "Documents/Keep";
        settings = {
          app = appDefaults // {
            attachmentFolderPath = "9 - Attachments";
            # All new notes land in 5 - Main Notes.
            newFileLocation = "folder";
            newFileFolderPath = "5 - Main Notes";
          };
          # Declarative custom hotkeys (.obsidian/hotkeys.json). Shell-commands command
          # ids are `obsidian-shellcommands:shell-command-<id>`; Templater registers each
          # enabled template-hotkey as `templater-obsidian:<vault-relative path>`.
          hotkeys = lib.optionalAttrs mdCfg.obsidian.enable {
            "obsidian-shellcommands:shell-command-md2pdf-export" = [ mdCfg.obsidian.hotkey ];
          };
          corePlugins = [
            "backlink"
            "bases"
            "bookmarks"
            "canvas"
            "command-palette"
            "editor-status"
            "file-explorer"
            "file-recovery"
            "global-search"
            "graph"
            "note-composer"
            "outgoing-link"
            "outline"
            "page-preview"
            "slash-command"
            "switcher"
            "tag-pane"
            "templates"
            "word-count"
          ];
          communityPlugins = [
            {
              pkg = pkgs.callPackage ./plugins/templater.nix { };
              settings = {
                trigger_on_file_creation = true;
                auto_jump_to_cursor = true;
                enable_system_commands = true;
                syntax_highlighting = true;
                shell_path = "fish";
                command_palette = true;
                templates_folder = "9 - Templates";
                user_scripts_folder = "9 - Scripts";
              };
            }
            {
              pkg = pkgs.callPackage ./plugins/dataview.nix { };
              settings = {
                enableDataviewJs = true;
                enableInlineDataviewJs = true;
                taskCompletionUseEmojiShorthand = true;
                taskCompletionTracking = true;
                defaultDateFormat = "dd/MM/yyyy";
                defaultDateTimeFormat = "HH:mm - dd/MM/yyyy";
              };
            }
            {
              pkg = pkgs.callPackage ./plugins/maps.nix { };
              settings = {
                tileSets = [
                  {
                    id = "protomaps";
                    name = "Protomaps";
                    lightTiles = "https://tiles.openfreemap.org/styles/liberty";
                    darkTiles = "https://tiles.openfreemap.org/styles/dark";
                  }
                ];
              };
            }
            {
              # Helix keybindings in the editor (codemirror-helix), so the vault
              # matches hx and the fish-helix command line. Deliberately no
              # `settings` — the module only writes data.json when settings are
              # given, and the plugin's defaults are what we want.
              #
              # Requires `app.vimMode = false` (appDefaults above): Obsidian's
              # built-in vim mode is a separate CodeMirror keymap and the two
              # fight over the same keys.
              pkg = pkgs.callPackage ./plugins/helix.nix { };
            }
          ]
          ++ lib.optionals mdCfg.obsidian.enable [
            {
              # Shell commands exists solely to run md2pdf on the active note.
              pkg = pkgs.callPackage ./plugins/shellcommands.nix { };
              settings = shellcommandsSettings;
            }
          ];
        };
      };

      # The blog is edited in place: the vault IS the Hugo repo's content/ tree.
      # No sync step — Hugo/CI reads the same files Obsidian writes. .obsidian/ is
      # gitignored in the website repo and Hugo skips dotfiles, and the Blog Post
      # template lives in content/templates/ (version-controlled there, excluded
      # from the site via `ignoreFiles` in hugo.yaml).
      Blog = {
        enable = true;
        target = "development/bruvduroiu/website/content";
        settings = {
          app = appDefaults // {
            # Posts are Hugo page bundles (blog/<slug>/index.md); pasted images
            # must land beside the note, not in a vault-wide attachments folder.
            attachmentFolderPath = "./";
          };
          hotkeys = {
            "templater-obsidian:templates/Blog Post.md" = [
              {
                modifiers = [
                  "Mod"
                  "Shift"
                ];
                key = "B";
              }
            ];
          };
          corePlugins = [
            "backlink"
            "command-palette"
            "editor-status"
            "file-explorer"
            "file-recovery"
            "global-search"
            "outgoing-link"
            "outline"
            "page-preview"
            "slash-command"
            "switcher"
            "word-count"
          ];
          communityPlugins = [
            {
              pkg = pkgs.callPackage ./plugins/templater.nix { };
              settings = {
                auto_jump_to_cursor = true;
                syntax_highlighting = true;
                command_palette = true;
                templates_folder = "templates";
                # Register the Blog Post template as a hotkeyable command.
                enabled_templates_hotkeys = [ "templates/Blog Post.md" ];
              };
            }
            {
              # Same editor keybindings as the Keep vault (needs vimMode = false,
              # which appDefaults provides).
              pkg = pkgs.callPackage ./plugins/helix.nix { };
            }
          ];
        };
      };
    };

    defaultSettings = {
      appearance = {
        baseFontSize = lib.mkForce 16;
        # "Adapt to system": Electron tracks the portal colour-scheme
        # (org.freedesktop.appearance) live, so the desktop theme flips
        # Obsidian's base theme with no restart — the stylix
        # specialisation already toggles the dconf key it reads.
        theme = "system";
      };

      app = appDefaults;
    };
  };
}
