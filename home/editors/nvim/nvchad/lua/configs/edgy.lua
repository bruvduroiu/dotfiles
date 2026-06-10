return {
	animate = { enabled = false },
	exit_when_last = false,

	left = {
		-- nvim-tree auto-detected by edgy
		{ ft = "NvimTree", size = { height = 0.5, width = 0.2 } },
		{ ft = "fugitive", size = { width = 0.2 } },
		{ ft = "gitcommit", size = { width = 0.2 } },
		{ ft = "DiffviewFiles", size = { width = 0.2 } },
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
		{ ft = "DiffviewFileHistory", size = { height = 0.3 } },
	},

	right = {
		{ ft = "trouble", size = { width = 0.2 } },
		{ ft = "neotest-summary", size = { width = 0.2 } },
	},
}
