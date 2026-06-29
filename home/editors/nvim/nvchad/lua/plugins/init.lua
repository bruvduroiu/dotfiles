local function review_base()
	local head = vim.fn.systemlist({ "git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })
	if vim.v.shell_error == 0 and head[1] and head[1] ~= "" then
		return head[1]
	end
	for _, b in ipairs({ "origin/main", "origin/master", "main", "master" }) do
		vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", b })
		if vim.v.shell_error == 0 then
			return b
		end
	end
	return nil
end

local function review_pr_diff()
	local base = review_base()
	if not base then
		vim.notify("diffview: no base branch found (origin/HEAD unset; no main/master)", vim.log.levels.ERROR)
		return
	end
	vim.cmd("DiffviewOpen " .. base .. "...HEAD")
end

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

	-- ── PR review surface ─────────────────────────────────────────────────────
	{
		"sindrets/diffview.nvim",
		cmd = {
			"DiffviewOpen",
			"DiffviewFileHistory",
			"DiffviewClose",
			"DiffviewToggleFiles",
			"DiffviewFocusFiles",
			"DiffviewRefresh",
		},
		keys = {
			-- Triple-dot = merge-base diff = exact GitHub "Files changed" semantics.
			-- Base resolved locally (review_base) so it works without origin/HEAD set.
			{ "<leader>rd", review_pr_diff, desc = "Review: PR diff vs base" },
			{ "<leader>rw", "<cmd>DiffviewOpen<cr>", desc = "Review: working-tree diff" },
			{
				"<leader>rB",
				function()
					vim.ui.input({ prompt = "Diff vs base: ", default = review_base() or "origin/main" }, function(b)
						if b and b ~= "" then
							vim.cmd("DiffviewOpen " .. b .. "...HEAD")
						end
					end)
				end,
				desc = "Review: diff vs base…",
			},
			{ "<leader>rf", "<cmd>DiffviewFileHistory %<cr>", desc = "Review: file history" },
			{ "<leader>rl", "<cmd>DiffviewFileHistory<cr>", desc = "Review: branch history" },
			{ "<leader>rq", "<cmd>DiffviewClose<cr>", desc = "Review: close diffview" },
		},
		opts = require("configs.diffview"),
		init = function()
			-- Label the <leader>r "review" umbrella in which-key v3. init runs at
			-- lazy startup (before the User VeryLazy event fires), so the autocmd
			-- catches it. NvChad's which-key opts is a function, so a child
			-- opts.spec override can be dropped during lazy's merge — register
			-- imperatively instead, pcall-guarded in case which-key is absent.
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					local ok, wk = pcall(require, "which-key")
					if ok then
						wk.add({ { "<leader>r", group = "review" } })
					end
				end,
			})
		end,
	},
	{
		"pwntester/octo.nvim",
		cmd = "Octo",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		keys = {
			{ "<leader>ro", "<cmd>Octo pr list<cr>", desc = "Review: list PRs" },
			{ "<leader>rc", "<cmd>Octo pr checkout<cr>", desc = "Review: checkout PR" },
			{ "<leader>rs", "<cmd>Octo review start<cr>", desc = "Review: start review" },
			{ "<leader>rS", "<cmd>Octo review submit<cr>", desc = "Review: submit review" },
			{ "<leader>rr", "<cmd>Octo review resume<cr>", desc = "Review: resume review" },
			{ "<leader>ri", "<cmd>Octo issue list<cr>", desc = "Review: list issues" },
		},
		opts = require("configs.octo"),
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		-- Safe on treesitter branch="main": uses core vim.treesitter + its own
		-- bundled queries, not the rewritten nvim-treesitter module API.
		opts = {
			max_lines = 4, -- cap sticky-header height on deep nesting
			multiline_threshold = 1, -- collapse long signatures to one line
			trim_scope = "outer", -- keep innermost scope when over max_lines
			mode = "cursor",
			multiwindow = true, -- show context in BOTH diffview panes
		},
		keys = {
			-- [x, not [c: this config remaps ]c/[c to class-nav (via
			-- treesitter-textobjects), so [x is the free key for scope-jump.
			-- Native ]c/[c diff-change motion is restored in diff windows in mappings.lua.
			{
				"[x",
				function()
					require("treesitter-context").go_to_context(vim.v.count1)
				end,
				desc = "Jump to context",
			},
			{ "<leader>tC", "<cmd>TSContext toggle<cr>", desc = "Toggle sticky context" },
		},
	},
}
