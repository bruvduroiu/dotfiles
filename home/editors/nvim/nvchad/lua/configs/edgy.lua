return {
	animate = { enabled = false },
	exit_when_last = false,

	left = {
		-- nvim-tree auto-detected by edgy
		{ ft = "NvimTree", size = { height = 0.5, width = 0.3 } },
		{ ft = "fugitive", size = { width = 0.3 } },
		{ ft = "gitcommit", size = { width = 0.3 } },
		{ ft = "trouble", size = { width = 0.3 } },
		{ ft = "DiffviewFiles", title = "Diff Files", size = { width = 0.3 } },
		{ ft = "DiffviewFileHistory", title = "Diff History", size = { width = 0.3 } },
	},
	bottom = {
		{
			ft = "toggleterm",
			size = { height = 0.3 },
			filter = function(_, win)
				return vim.api.nvim_win_get_config(win).relative == ""
			end,
		},
		{ ft = "neotest-output-panel", size = { height = 0.3 } },
		{ ft = "qf", title = "Quickfix", size = { height = 0.3 } },
	},

	right = {
		{ ft = "neotest-summary", size = { width = 0.3 } },
	},

	options = {
		left = { size = 35 },
		bottom = { size = 20 },
		right = { size = 35 },
	},
}
