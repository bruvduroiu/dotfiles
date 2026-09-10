{ config, inputs, lib, pkgs, ... }:

let
  # Noctalia 5.0.1's bundled template has an invalid `none` color and uses
  # dark-mode constants/container backgrounds as text. Keep upstream's scopes
  # while fixing those colors; render from the same palette as the terminal.
  # Omit the editor background so Ghostty supplies its transparent default.
  template = pkgs.writeText "noctalia-helix-template.toml" (lib.replaceStrings
    [
      ''"ui.background" = "none"''
      ''"ui.selection" = { bg = "primaryContainer", fg = "onPrimaryContainer" }''
      ''"ui.highlight" = { bg = "primaryContainer", modifiers = ["bold"] }''
      ''"constant.character" = "secondaryContainer"''
      ''"constant.character.escape" = "tertiaryContainer"''
      ''"string.regexp" = { fg = "tertiaryContainer" }''
      ''warning = "#f9e2af"''
      ''info = "#89dceb"''
      ''hint = "#94e2d5"''
      ''plus = "#a6e3a1"''
      ''delta = "#89b4fa"''
      ''background = "{{colors.background.default.hex}}"''
      ''onBackground = "{{colors.on_background.default.hex}}"''
    ]
    [
      ''"ui.background" = { fg = "onBackground" }''
      ''"ui.selection" = { bg = "surfaceContainerHigh", fg = "onSurface" }''
      ''"ui.highlight" = { bg = "surfaceContainerHigh", modifiers = ["bold"] }''
      ''"constant.character" = "secondary"''
      ''"constant.character.escape" = "primary"''
      ''"string.regexp" = { fg = "tertiary" }''
      ''warning = "{{colors.terminal_normal_yellow.default.hex}}"''
      ''info = "{{colors.terminal_normal_blue.default.hex}}"''
      ''hint = "{{colors.terminal_normal_cyan.default.hex}}"''
      ''plus = "{{colors.terminal_normal_green.default.hex}}"''
      ''delta = "{{colors.terminal_normal_magenta.default.hex}}"''
      ''background = "{{colors.terminal_background.default.hex}}"''
      ''onBackground = "{{colors.terminal_foreground.default.hex}}"''
    ]
    (builtins.readFile "${inputs.noctalia}/assets/templates/helix/helix.toml"));
  reload = pkgs.writeShellApplication {
    name = "noctalia-helix-reload";
    runtimeInputs = [ pkgs.procps pkgs.coreutils ];
    text = ''
      # HM wraps hx; only signal this user's editors. No matches is normal.
      status=0
      pkill -USR1 -u "$(id -u)" -x 'hx|\.hx-wrapped' || status=$?
      if [ "$status" -gt 1 ]; then
        exit "$status"
      fi
    '';
  };
in
{
  programs.noctalia.settings.theme.templates.user.helix = {
    input_path = "${template}";
    # Separate from the old built-in output so its undo hook cannot remove it.
    output_path = "${config.xdg.configHome}/helix/themes/noctalia-helix.toml";
    post_hook = lib.getExe reload;
    hook_async = false;
  };
  programs.helix.settings.theme = "noctalia-helix";
}
