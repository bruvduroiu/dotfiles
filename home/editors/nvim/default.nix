{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;

    withNodeJs = true;
    withPython3 = true;
    withRuby = true; # keep legacy default (26.05 flipped it to false); silences the warning

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
      nixfmt # was nixfmt-rfc-style; aliased to pkgs.nixfmt in 26.05
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

    # neovim 0.12's wrapper isn't reliably injecting extraLuaPackages onto
    # LUA_PATH, so also put the magick FFI rock on package.path explicitly
    # (runs via --cmd before NvChad's init, so image.nvim can require it).
    initLua = ''
      package.path = package.path
        .. ";${pkgs.luajitPackages.magick}/share/lua/5.1/?.lua"
        .. ";${pkgs.luajitPackages.magick}/share/lua/5.1/?/init.lua"
    '';
  };

  home.file."${config.xdg.configHome}/nvim" = {
    source = ./nvchad;
    recursive = true;
  };
}
