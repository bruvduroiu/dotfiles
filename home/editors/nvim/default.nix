{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;

    withNodeJs = true;
    withPython3 = true;

    extraPackages = with pkgs; [
      clang
    ];
  };

  home.file."${config.xdg.configHome}/nvim" = {
    source = ./nvchad;
    recursive = true;
  };
}
