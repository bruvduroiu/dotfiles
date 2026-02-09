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
		config = function()
			local _99 = require("99")

            -- For logging that is to a file if you wish to trace through requests
            -- for reporting bugs, i would not rely on this, but instead the provided
            -- logging mechanisms within 99.  This is for more debugging purposes
            local cwd = vim.uv.cwd()
            local basename = vim.fs.basename(cwd)
			_99.setup({
				logger = {
					level = _99.DEBUG,
					path = "/tmp/" .. basename .. ".99.debug",
					print_on_error = true,
				},

        --- A new feature that is centered around tags
        completion = {
          --- Defaults to .cursor/rules
          -- I am going to disable these until i understand the
          -- problem better.  Inside of cursor rules there is also
          -- application rules, which means i need to apply these
          -- differently
          -- cursor_rules = "<custom path to cursor rules>"

          --- A list of folders where you have your own SKILL.md
          --- Expected format:
          --- /path/to/dir/<skill_name>/SKILL.md
          ---
          --- Example:
          --- Input Path:
          --- "scratch/custom_rules/"
          ---
          --- Output Rules:
          --- {path = "scratch/custom_rules/vim/SKILL.md", name = "vim"},
          --- ... the other rules in that dir ...
          ---
          custom_rules = {
            "scratch/custom_rules/",
          },

          --- What autocomplete do you use.  We currently only
          --- support cmp right now
          source = "cmp",
        },

        --- WARNING: if you change cwd then this is likely broken
        --- ill likely fix this in a later change
        ---
        --- md_files is a list of files to look for and auto add based on the location
        --- of the originating request.  That means if you are at /foo/bar/baz.lua
        --- the system will automagically look for:
        --- /foo/bar/AGENT.md
        --- /foo/AGENT.md
        --- assuming that /foo is project root (based on cwd)
				md_files = {
					"AGENT.md",
				},
			})

            -- Create your own short cuts for the different types of actions
			vim.keymap.set("n", "<leader>9f", function()
				_99.fill_in_function()
			end)
            -- take extra note that i have visual selection only in v mode
            -- technically whatever your last visual selection is, will be used
            -- so i have this set to visual mode so i dont screw up and use an
            -- old visual selection
            --
            -- likely ill add a mode check and assert on required visual mode
            -- so just prepare for it now
			vim.keymap.set("v", "<leader>9v", function()
				_99.visual()
			end)

            --- if you have a request you dont want to make any changes, just cancel it
			vim.keymap.set("v", "<leader>9s", function()
				_99.stop_all_requests()
			end)

            --- Example: Using rules + actions for custom behaviors
            --- Create a rule file like ~/.rules/debug.md that defines custom behavior.
            --- For instance, a "debug" rule could automatically add printf statements
            --- throughout a function to help debug its execution flow.
			vim.keymap.set("n", "<leader>9fd", function()
				_99.fill_in_function()
			end)
		end,
	},
}
