{ lib
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
in
{
  # Scripts, templates, and bases are stored here as version-controlled backup.
  # They live in the vault directly (synced via Syncthing).

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
              settings = { };
            }
          ];
        };
      };
      Blog = {
        enable = true;
        target = "development/bruvduroiu/website/content";
        settings = { 
          corePlugins = [
            "backlink"
            "bookmarks"
            "command-palette"
            "editor-status"
            "file-explorer"
            "global-search"
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
