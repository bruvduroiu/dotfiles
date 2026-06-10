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

      # test runner
      python3Packages.pytest

      # nix
      nixfmt-rfc-style
      nil

      # lua (lua_ls is enabled by NvChad defaults)
      lua-language-server
      stylua

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
