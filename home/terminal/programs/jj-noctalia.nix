{ config, lib, ... }:

{
  # jjui resolves its palette as: embedded default -> `ui.theme` file ->
  # jj's own VCS colors -> inline `ui.colors`. Stylix wrote a frozen base16
  # palette into that last, highest-priority layer, so jjui's live
  # light/dark reload had nothing left to change. Noctalia owns the theme
  # file instead; see noctalia-stylix.nix for the matching target disable.
  programs.jjui.settings.ui = {
    theme = "noctalia";
    colors = lib.mkForce { };
  };

  # `themes/` is deliberately not Home-Manager-owned: Noctalia must be able to
  # write a regular file there on every theme change.
  programs.noctalia.settings.theme.templates.user.jjui = {
    input_path = "${./jjui-noctalia.toml}";
    output_path = "${config.xdg.configHome}/jjui/themes/noctalia.toml";
  };
}
