return {
  { "hrsh7th/nvim-cmp", enabled = false },
	{
		"stevearc/conform.nvim",
		event = "BufWritePre", -- uncomment for format on save
		opts = require("configs.conform"),
	},
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "debugloop/telescope-undo.nvim",
    },
    config = function()
      dofile(vim.g.base46_cache .. "telescope")
      require("configs.telescope")
    end,
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
				"markdown",
				"markdown_inline",
				"regex",
				"bash",
				"json",
				"yaml",
			},
		},
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		lazy = false,
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("configs.treesitter-textobjects")
		end,
	},
	{
		"tpope/vim-fugitive",
		cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gwrite", "Gread", "Ggrep", "GMove", "GDelete", "GBrowse", "Gstatus", "Gedit", "Glog" },
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
		"nicolasgb/jj.nvim",
		version = "*",
		cmd = { "J" },
		keys = {
			{ "<leader>jj", "<cmd>J status<cr>", desc = "Jujutsu status" },
			{ "<leader>jl", "<cmd>J log<cr>", desc = "Jujutsu log" },
			{ "<leader>jd", "<cmd>J describe<cr>", desc = "Jujutsu describe" },
			{ "<leader>jn", "<cmd>J new<cr>", desc = "Jujutsu new change" },
			{ "<leader>je", "<cmd>J edit<cr>", desc = "Jujutsu edit" },
			{ "<leader>jp", "<cmd>J git push<cr>", desc = "Jujutsu push" },
		},
		config = function()
			require("jj").setup({})
		end,
	},
	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		keys = {
			{ "<leader>z", "<cmd>ZenMode<cr>", desc = "Toggle ZenMode" },
		},
		opts = {
			plugins = {
        twilight = { enabled = false },
			},
		},
	},
  {
    "folke/twilight.nvim",
    keys = {
      { "<leader>tz", "<cmd>Twilight<cr>", desc = "Toggle Twilight" },
    },
    opts = { }
  },
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("harpoon"):setup()
		end,
		keys = {
			{ "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon add" },
			{ "<leader>h", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon menu" },
			{ "<leader>H", function() require("harpoon"):list():clear() end, desc = "Harpoon clear all" },
			{ "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
			{ "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
			{ "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
			{ "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
		},
	},
	{
		"folke/trouble.nvim",
		opts = {
			auto_close = true,
			auto_open = false,
			warn_no_results = false,
			modes = {
				lsp_document_symbols = {
					win = { type = "split", relative = "win", position = "right", size = 0.30 },
				},
				diagnostics = {
					win = { type = "split", relative = "win", position = "bottom", size = 0.30 },
				},
				lsp = {
					win = { type = "split", relative = "win", position = "bottom", size = 0.20 },
					filter = {
						any = {
							ft = { "help", "markdown" },
							kind = {
								"Class", "Constructor", "Enum", "Field", "Function",
								"Interface", "Method", "Module", "Namespace", "Package",
								"Property", "Struct", "Trait",
							},
						},
					},
				},
				lsp_references = {
					win = { type = "split", relative = "win", position = "bottom", size = 0.25 },
				},
			},
		},
		cmd = "Trouble",
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace diagnostics" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
			{ "<leader>cs", "<cmd>Trouble lsp_document_symbols toggle<cr>", desc = "Symbols sidebar" },
			{ "<leader>cl", "<cmd>Trouble lsp toggle<cr>", desc = "LSP definitions/references" },
			{ "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix" },
			{ "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
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
  },
  {
    "cuducos/yaml.nvim",
    ft = { "yaml" },
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
  },
  {
    "phelipetls/vim-hugo",
    -- Load early to enable filetype detection for Hugo templates
    lazy = false,
  },
	{
		"ThePrimeagen/99",
		dependencies = { { "saghen/blink.compat", version = "2.*" } },
		keys = {
			{ "<leader>9v", function() require("99").visual() end, mode = "v", desc = "99 visual replace" },
			{ "<leader>9x", function() require("99").stop_all_requests() end, mode = "n", desc = "99 stop all requests" },
			{ "<leader>9s", function() require("99").search() end, mode = "n", desc = "99 search" },
			{ "<leader>9m", function() require("99.extensions.telescope").select_model() end, mode = "n", desc = "99 select model" },
			{ "<leader>9p", function() require("99.extensions.telescope").select_provider() end, mode = "n", desc = "99 select provider" },
		},
		config = function()
			require("configs.99")
		end,
	},
}
