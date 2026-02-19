{ lib
, pkgs
, ... 
}:

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
          appearance = {
            baseFontSize = lib.mkForce 16;
          };
          communityPlugins = [
            {
              pkg = pkgs.callPackage ./plugins/templater { };
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
              pkg = pkgs.callPackage ./plugins/dataview { };
              settings = {
                enableDataviewJs = true;
                enableInlineDataviewJs = true;
                taskCompletionUseEmojiShorthand = true;
                taskCompletionTracking = true;
                defaultDateFormat = "dd/MM/yyyy";
                defaultDateTimeFormat = "HH:mm - dd/MM/yyyy";
              };
            }
          ];
        };
      };
    };

    defaultSettings = {
      app = {
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
        attachmentFolderPath = "9 - Attachments";
      };

      corePlugins = [
        "backlink"
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
    };
  };
}
