{ pkgs, ... }:

{
  programs.obsidian = {
    enable = true;
    package = pkgs.obsidian;
    vaults = {
      Keep = {
        enable = true;
        target = "Documents/Keep";
        settings = {
          communityPlugins = [
            { 
              pkg = pkgs.callPackage ./plugins/templater { };
              settings = {
                trigger_on_file_creation = true;
                auto_jump_to_cursor = true;
                enable_system_commands = true;
                shell_path = "zsh";
                command_palette = true;
              };
            }
            { 
              pkg = pkgs.callPackage ./plugins/periodic-notes { };
              settings = {
                showNotification = false;
                weekly = {
                  template = "Templates/Weekly Note.md";
                  format = "gggg-[W]ww";
                };
                daily = {
                  template = "Templates/Daily Note.md";
                  format = "yyyy-MM-dd";
                };
              };
            }
            { 
              pkg = pkgs.callPackage ./plugins/dataview { };
              settings = {
                enableDataviewJs = true;
                enableInlineDataviewJs = true;
                warnOnEmptyResult = false;
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
        readableLineLength = true;
        showLineNumber = true;
        tabSize = 2;
        vimMode = true;
        focusNewTab = true;
        livePreview = false;
        strictLineBreaks = false;
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
