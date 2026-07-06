return {
  defaults = { lazy = true },
  install = { colorscheme = { "nvchad" } },

  -- Read the lockfile nix4nvchad places in the config dir (= stdpath("config")),
  -- so the Nix-pinned commits are what lazy.nvim restores. The old stdpath("data")
  -- path was a workaround for the readonly /nix/store symlink era; under nvchad the
  -- config dir is a writable copy, so point back here.
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",

  -- NixOS can't run lazy's hererocks/luarocks installer (sandboxed store);
  -- no plugins here need it, so disable to silence the healthcheck error.
  rocks = { enabled = false },

  ui = {
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      not_loaded = "",
    },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin",
        "tohtml",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "matchit",
        "tar",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "syntax",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },
}
