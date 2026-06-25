{ config
, lib
, pkgs
, ...
}:

let
  # Shared app.json defaults. The obsidian module merges `settings` per
  # top-level key (app/appearance/...), NOT deeply — a vault that sets
  # `settings.app` replaces this whole block, so reuse it explicitly.
  appDefaults = {
    defaultViewMode = "preview";
    tabSize = 2;
    vimMode = true;
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

  website = "${config.home.homeDirectory}/development/bruvduroiu/website";
  blogsFolder = "${config.home.homeDirectory}/Documents/Keep/4 - Blogs";

  # Single action: mirror the vault's `4 - Blogs` folder into the Hugo repo's content/.
  # Everything else (build, commit, push, local preview) is handled manually outside
  # Obsidian. rsync --delete gives true mirror semantics (deletions propagate); cp -a
  # would leave ghosts of deleted posts behind.
  blog-sync = pkgs.writeShellApplication {
    name = "blog-sync";
    runtimeInputs = with pkgs; [ rsync ];
    text = ''
      vault="${blogsFolder}"
      repo="${website}"

      # Safety: refuse to mirror an unseeded vault — rsync --delete would otherwise
      # wipe every post in the repo.
      if [ ! -d "$vault/blog" ] || [ ! -f "$vault/_index.md" ]; then
        echo "blog-sync: '4 - Blogs' looks unseeded (missing blog/ or _index.md); aborting." >&2
        exit 1
      fi

      rsync -a --delete --exclude='.obsidian' "$vault/" "$repo/content/"
      echo "blog-sync: mirrored 4 - Blogs -> $repo/content"
    '';
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
      stdout = { handler = "ignore"; convert_ansi_code = true; };
      stderr = { handler = "notification"; convert_ansi_code = true; };
    };
    output_wrappers = { stdout = null; stderr = null; };
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
    shell_arguments = [ "-c" "{{shell_command_content}}" ];
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
    default_shells = { linux = nixShellId; };
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
    shell_commands = [
      (mkShellCommand "blog-sync" "Blog: sync vault -> repo content" "${blog-sync}/bin/blog-sync")
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
  # Scripts, templates, and bases are stored here as version-controlled backup.
  # They live in the vault directly (synced via Syncthing).

  # blog-sync is also exposed on PATH for use outside Obsidian.
  home.packages = [ blog-sync ];

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
            # All new notes land in 5 - Main Notes. Blogs start there too but the Blog Post
            # template immediately tp.file.move()s them into 4 - Blogs/blog/<slug>/.
            newFileLocation = "folder";
            newFileFolderPath = "5 - Main Notes";
          };
          # Declarative custom hotkeys (.obsidian/hotkeys.json). Shell-commands command
          # ids are `obsidian-shellcommands:shell-command-<id>`; Templater registers each
          # enabled template-hotkey as `templater-obsidian:<vault-relative path>`.
          hotkeys = {
            "obsidian-shellcommands:shell-command-blog-sync" = [
              { modifiers = [ "Mod" "Shift" ]; key = "P"; }
            ];
            "templater-obsidian:9 - Templates/Blog Post.md" = [
              { modifiers = [ "Mod" "Shift" ]; key = "B"; }
            ];
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
                # Register the Blog Post template as a hotkeyable command.
                enabled_templates_hotkeys = [ "9 - Templates/Blog Post.md" ];
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
                    darkTiles  = "https://tiles.openfreemap.org/styles/dark";
                  }
                ];
              };
            }
            {
              # Single rsync command (see blog-sync above).
              pkg = pkgs.callPackage ./plugins/shellcommands.nix { };
              settings = shellcommandsSettings;
            }
          ];
        };
      };
    };

    defaultSettings = {
      appearance = {
        baseFontSize = lib.mkForce 16;
      };

      app = appDefaults;
    };
  };
}
