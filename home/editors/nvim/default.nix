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

      # image.nvim — inline images in markdown via Ghostty's kitty graphics
      imagemagick

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

    # magick LuaRock — image.nvim's ImageMagick binding, placed on nvim's
    # luajit package.path (avoids lazy.nvim's runtime luarocks bootstrap)
    extraLuaPackages = ps: [ ps.magick ];
  };

  home.file."${config.xdg.configHome}/nvim" = {
    source = ./nvchad;
    recursive = true;
  };
}
