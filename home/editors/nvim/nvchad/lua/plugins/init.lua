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
		branch = "main",
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
				"zig",
				"nix",
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
		cmd = {
			"Git",
			"G",
			"Gdiffsplit",
			"Gvdiffsplit",
			"Gwrite",
			"Gread",
			"Ggrep",
			"GMove",
			"GDelete",
			"GBrowse",
			"Gstatus",
			"Gedit",
			"Glog",
		},
		keys = {
			{ "<leader>gs", "<cmd>vertical Git<cr>" },
			desc = "Open Fugitive",
		},
		dependencies = {
			"tpope/vim-rhubarb",
		},
	},
	"tpope/vim-rhubarb",
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
		opts = {},
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("harpoon"):setup()
		end,
		keys = {
			{
				"<leader>ha",
				function()
					require("harpoon"):list():add()
				end,
				desc = "Harpoon add",
			},
			{
				"<leader>hm",
				function()
					require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
				end,
				desc = "Harpoon menu",
			},
			{
				"<leader>hH",
				function()
					require("harpoon"):list():clear()
				end,
				desc = "Harpoon clear all",
			},
			{
				"<leader>1",
				function()
					require("harpoon"):list():select(1)
				end,
				desc = "Harpoon 1",
			},
			{
				"<leader>2",
				function()
					require("harpoon"):list():select(2)
				end,
				desc = "Harpoon 2",
			},
			{
				"<leader>3",
				function()
					require("harpoon"):list():select(3)
				end,
				desc = "Harpoon 3",
			},
			{
				"<leader>4",
				function()
					require("harpoon"):list():select(4)
				end,
				desc = "Harpoon 4",
			},
		},
	},
	{
		"folke/trouble.nvim",
		opts = {
			auto_close = false,
			auto_refresh = true,
			auto_preview = false,
			warn_no_results = false,
			modes = {
				diagnostics = {
					auto_close = true, -- bottom panel closes when no diagnostics
				},
				lsp_document_symbols = {},
				lsp = {
					filter = {
						any = {
							ft = { "help", "markdown" },
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
				lsp_references = {},
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
				signature = {
					enabled = false,
				},
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
				lsp_doc_border = true, -- add a border to hover docs and signature help
			},
		},
		dependencies = {
			"MunifTanjim/nui.nvim",
			{ "rcarriga/nvim-notify", opts = { background_colour = "#000000" } },
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
		-- inline images in markdown buffers (e.g. newsboat ,f full-text view).
		-- Ghostty implements the kitty graphics protocol, so use that backend.
		"3rd/image.nvim",
		ft = { "markdown" },
		opts = {
			backend = "kitty",
			processor = "magick_rock",
			integrations = {
				markdown = {
					enabled = true,
					-- render only the image on the cursor's line — one at a
					-- time, so a stack of images never overlaps the text
					only_render_image_at_cursor = true,
					download_remote_images = true,
				},
			},
			-- bound height so image.nvim reserves the same number of rows it
			-- renders (mismatch is what makes images overlap the alt text)
			max_width_window_percentage = 80,
			max_height_window_percentage = 50,
			-- repaint when other windows overlap, so scroll/wrap don't leave
			-- the image stamped over text
			window_overlap_clear_enabled = true,
		},
	},

	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		enabled = true,
		init = function()
			vim.opt.laststatus = 3
			vim.opt.splitkeep = "screen"
		end,
		opts = require("configs.edgy"),
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
		"lewis6991/gitsigns.nvim",
		-- NvChad includes gitsigns by default; override its opts
		opts = require("configs.gitsigns"),
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-neotest/neotest-go",
			"nvim-neotest/neotest-python",
			"marilari88/neotest-vitest",
		},
		lazy = false,
		config = function()
			require("configs.neotest")()
		end,
	},
	{
		"kosayoda/nvim-lightbulb",
		event = "LspAttach",
		opts = require("configs.lightbulb"),
	},
}
