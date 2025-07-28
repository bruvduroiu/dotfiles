return {
  { "hrsh7th/nvim-cmp", enabled = false },
	{
		"stevearc/conform.nvim",
		event = "BufWritePre", -- uncomment for format on save
		opts = require("configs.conform"),
	},
  {
    "nvim-telescope/telescope.nvim",
    opts = require("configs.telescope"),
  },

	-- These are some examples, uncomment them if you want to see them work!
	{
		"neovim/nvim-lspconfig",
		config = function()
			require("configs.lspconfig")
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"vim",
				"lua",
				"vimdoc",
				"html",
				"css",
				"python",
				"typescript",
				"go",
				"terraform",
			},
		},
	},
	{
		"tpope/vim-fugitive",
		cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gwrite", "Gread", "Ggrep", "GMove", "GDelete", "GBrowse" },
		keys = {
			{ "<leader>gs", "<cmd>vertical Git<cr>" },
			{ "<leader>gb", "<cmd>Git blame<cr>" },
			desc = "Open Fugitive",
		},
		opts = {
			enabled = true,
		},
		dependencies = {
			"tpope/vim-rhubarb",
		},
	},
	{ "tpope/vim-rhubarb", opts = { enabled = true } },
	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
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
						size = 0.30, -- 30% of the window
					},
				},
				lsp_document_symbols = { -- Configure symbols mode
					win = {
						type = "split", -- split window
						relative = "win", -- relative to current window
						position = "right", -- right side
						size = 0.30, -- 30% of the window
					},
				},
				diagnostics = {
					win = {
						type = "split",
						relative = "win",
						position = "bottom",
						size = 0.30,
					},
				},
				lsp = { -- Configure LSP references mode
					win = {
						type = "split", -- split window
						relative = "win", -- relative to current window
						position = "bottom", -- appear below
						size = 0.20, -- 25% of the window height
					},
          filter = {
            any = {
              -- all symbol kinds for help / markdown files
              ft = { "help", "markdown" },
              -- default set of symbol kinds
              kind = {
                "Class",
                "Constructor",
                "Enum",
                "Field",
                "Function",
                "Interface",
                "Method",
                "Module",
                "Namespace",
                "Package",
                "Property",
                "Struct",
                "Trait",
              },
            },
          },
				},
				preview = {
					mode = "diagnostics",
					preview = {
						type = "split",
						relative = "win",
						position = "right",
						size = 0.3,
					},
				},
				preview_float = {
					mode = "diagnostics",
					preview = {
						type = "float",
						relative = "editor",
						border = "rounded",
						title = "Preview",
						title_pos = "center",
						position = { 0, -2 },
						size = { width = 0.3, height = 0.5 },
						zindex = 200,
					},
				},
				lsp_references = {
					mode = "lsp_references",
					win = {
						type = "split",
						relative = "win",
						position = "bottom",
					},
				},
			},
		}, -- for default options, refer to the configuration section for custom setup.
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble preview toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble lsp_document_symbols toggle focus=false pinned=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false pinned=false<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>cr",
				"<cmd>Trouble lsp_references toggle focus=false<cr>",
				desc = "LSP references / ... (Trouble)",
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
		"gfontenot/vim-xcode",
		enabled = true,
	},

	{
		"m4xshen/hardtime.nvim",
		lazy = false,
		dependencies = { "MunifTanjim/nui.nvim" },
		opts = {},
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {
			file_types = { "markdown" },
		},
		ft = { "markdown" },
	},

	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		enabled = false,
		opts = require("configs.edgy"),
	},
  {
    "supermaven-inc/supermaven-nvim",
    event = "VeryLazy",
    enabled = false,
    opts = require("configs.supermaven"),
  },

  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    event = "VeryLazy",
    version = "*",

    opts = require("configs.blink"),
  }
}
