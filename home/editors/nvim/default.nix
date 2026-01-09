{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;

    withNodeJs = true;
    withPython3 = true;

    extraPackages = with pkgs; [
      clang

      # formatters
      gofumpt
      goimports-reviser
      golines

      # gopls
      gopls

      # tools
      go

      # nix
      nixfmt-rfc-style
      nil

      # ts
      prettierd

      # html template formatters
      djlint
    ];
  };

  home.file."${config.xdg.configHome}/nvim" = {
    source = ./nvchad;
    recursive = true;
  };
}
