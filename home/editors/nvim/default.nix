{ config, pkgs, ... }:

{
  # vimAlias replacement: nix4nvchad only installs `nvim`, so map `vim` → nvim.
  home.shellAliases.vim = "nvim";

  programs.nvchad = {
    enable = true;

    # Pin plugin commits reproducibly. Without this, nix4nvchad installs an
    # EMPTY lazy-lock.json into the store config, which nvchad.sh's cleanup_lock
    # then deletes at launch — so lazy.nvim resolves plugin HEADs freshly on
    # every machine. Feeding the committed lockfile here lands it in
    # ~/.config/nvim/lazy-lock.json so `:Lazy restore` pins to known-good commits.
    # Refresh it with: cp ~/.local/share/nvim/lazy-lock.json ./nvchad/lazy-lock.json
    lazy-lock = builtins.readFile ./nvchad/lazy-lock.json;

    # image.nvim uses processor = "magick_rock", which require()s the `magick`
    # LuaRock. nix4nvchad has no --cmd/initLua hook, but image.nvim is
    # ft = { "markdown" } (lazy), so injecting package.path here in extraConfig
    # (appended to init.lua at startup) runs before any markdown buffer opens.
    # The hard-coded store path makes this independent of neovim's LUA_PATH
    # wrapper, which was unreliable on 0.12.
    extraConfig = ''
      package.path = package.path
        .. ";${pkgs.luajitPackages.magick}/share/lua/5.1/?.lua"
        .. ";${pkgs.luajitPackages.magick}/share/lua/5.1/?/init.lua"
    '';

    extraPackages = with pkgs; [
      clang

      # formatters
      gofumpt
      goimports-reviser
      golines

      # gopls
      gopls

      # tools
      gh # GitHub CLI — octo.nvim's API backend (token → OS keyring)
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
  };
}
