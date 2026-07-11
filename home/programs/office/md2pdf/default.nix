{ config, lib, pkgs, ... }:

let
  cfg = config.programs.md2pdf;
in
{
  # Options only — the actual Obsidian Shell-commands entry + hotkey are wired in
  # ../obsidian/default.nix (that's where the vault's shell-command settings object
  # is built; it reads these options). This module just declares the interface and
  # installs the CLI when enabled.
  options.programs.md2pdf = {
    enable = lib.mkEnableOption "md2pdf Markdown-to-PDF pipeline (pandoc + headless chromium)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.md2pdf;
      defaultText = lib.literalExpression "pkgs.md2pdf";
      description = "The md2pdf package to install and invoke.";
    };

    defaultTheme = lib.mkOption {
      type = lib.types.str;
      default = "report";
      example = "letter";
      description = "Theme passed to md2pdf when none is given on the CLI; matches a bundled themes/<name>.css (report, letter).";
    };

    obsidian = {
      enable = lib.mkEnableOption "an Obsidian Shell-commands entry and hotkey that export the active note to PDF";

      hotkey = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { modifiers = [ "Mod" "Shift" ]; key = "E"; };
        description = "Obsidian hotkey bound to the md2pdf export command.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Also on PATH for use outside Obsidian.
    home.packages = [ cfg.package ];
  };
}
