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
          communityPlugins = [];
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

      communityPlugins = [
        "obsidian-templater-obsidian"
        "obsidian-periodic-notes"
        "obsidian-dataview"
      ];
    };
  };
}
