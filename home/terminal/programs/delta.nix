{ config, ... }:

let
  colors = config.lib.stylix.colors.withHashtag;
  isDark = config.stylix.polarity == "dark";
in
{
  programs.delta = {
    enable = true;
    enableJujutsuIntegration = true;
    options = {
      dark = isDark;
      light = !isDark;
      syntax-theme = config.programs.bat.config.theme;

      features = "decorations";
      decorations = {
        commit-decoration-style = "bold ${colors.base0A} box ul";
        file-decoration-style = "none";
        file-style = "bold ${colors.base0D} ul";
        hunk-header-decoration-style = "${colors.base03} box";
        hunk-header-file-style = "bold ${colors.base0D}";
        hunk-header-line-number-style = "bold ${colors.base0E}";
        hunk-header-style = "file line-number syntax";
      };

      minus-style = "${colors.base08} ${colors.base01}";
      minus-emph-style = "bold ${colors.base08} ${colors.base02}";
      minus-empty-line-marker-style = "${colors.base08} ${colors.base01}";
      plus-style = "${colors.base0B} ${colors.base01}";
      plus-emph-style = "bold ${colors.base0B} ${colors.base02}";
      plus-empty-line-marker-style = "${colors.base0B} ${colors.base01}";
      grep-file-style = colors.base0D;
      grep-line-number-style = colors.base0B;
      blame-palette = "${colors.base01} ${colors.base02} ${colors.base03}";
      whitespace-error-style = "${colors.base08} reverse";
    };
  };
}
