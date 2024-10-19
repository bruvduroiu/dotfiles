return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
  	"nvim-treesitter/nvim-treesitter",
  	opts = {
  		ensure_installed = {
  			"vim", "lua", "vimdoc",
       "html", "css", "python",
        "typescript", "go"
  		},
  	},
  },
  {
    "tpope/vim-fugitive",
    cmd={"Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gwrite", "Gread", "Ggrep", "GMove", "GDelete", "GBrowse"},
    keys={
      {"<leader>gs", "<cmd>vertical Git<cr>" },
      desc = "Open Fugitive"
    },
    opts = {
      enabled = true
    }
  },
  { "tpope/vim-rhubarb", opts = { enabled = true, lazy = false } },
  {
    "folke/zen-mode.nvim",
    cmd="ZenMode",
    opts = {
      plugins = {
        kitty = {
          enabled = true,
          font = "+4",
        },
      },
    },
  },
  {
    "folke/trouble.nvim",
    opts = {
      auto_close = true,
      auto_open = false,
      warn_no_results = false,
      modes = {
        symbols = { -- Configure symbols mode
          win = {
            type = "split", -- split window
            relative = "win", -- relative to current window
            position = "right", -- right side
            size = 0.15, -- 30% of the window
          },
        },
      },
    }, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
      },
    },
  },
  {
    "knubie/vim-kitty-navigator",
    enabled = true,
    lazy = false,
    build = {
      "cp ./*.py ~/.config/kitty/"
    }
  },
}
