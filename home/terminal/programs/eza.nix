{ pkgs, ... }:

{
  programs.eza = {
    enable = true;

    enableFishIntegration = true;

    extraOptions = [
      "--all"
      "--classify"
      "--icons=always"
      "--group-directories-first"
      "--hyperlink"
      "--color=always"
      "--color-scale"
      "--color-scale-mode=gradient"
    ];
  };

  home.shellAliases = let
    ov = "${pkgs.ov}/bin/ov -H1";
    eza = "${pkgs.eza}/bin/eza";
  in {
    ll = "${eza} -albhHigUuS -m@ | ${ov}";
    lt = "${eza} --tree --level=2 | ${ov}";
  };
}
