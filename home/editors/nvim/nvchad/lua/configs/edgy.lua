-- edgy.nvim — three-rail layout contract:
--   left   = project navigation (file tree, diffview panels, git status)
--   bottom = transient output (terminal, quickfix, diagnostics, test output)
--   right  = code context while reading (symbols outline, LSP refs/defs, test summary)
--
-- Trouble placement: trouble's mode config (plugins/init.lua) is the single
-- source of truth for which edge a mode opens at; the filters below make edgy
-- adopt each trouble window at that edge. A bare ft=trouble entry instead
-- RELOCATES every trouble window to one hardcoded rail while trouble itself
-- keeps opening at its configured position — that tug-of-war is what made
-- references land on different rails depending on which edgebars were open.
local function trouble_at(pos)
	return {
		ft = "trouble",
		filter = function(_, win)
			local t = vim.w[win].trouble
			return t ~= nil and t.position == pos and t.type == "split" and t.relative == "editor"
		end,
	}
end

-- Edgy should only manage real splits; floats (NvTerm_float, pickers) pass through.
local function is_split(_, win)
	return vim.api.nvim_win_get_config(win).relative == ""
end

return {
	animate = { enabled = false },
	exit_when_last = false,

	left = {
		-- height 0.5 keeps the tree at half the rail when a diffview/fugitive
		-- panel stacks below it during review
		{ ft = "NvimTree", size = { height = 0.5 } },
		{ ft = "DiffviewFiles", title = "Diff Files" },
		{ ft = "DiffviewFileHistory", title = "Diff History" },
		{ ft = "fugitive" },
		{ ft = "gitcommit" },
	},

	bottom = {
		-- NvChad's term module tags horizontal terminals NvTerm_sp (there is no
		-- toggleterm in this config); vsp/float terminals are left alone
		{ ft = "NvTerm_sp", title = "Terminal" },
		trouble_at("bottom"), -- diagnostics / qflist / loclist modes
		{ ft = "qf", title = "Quickfix" },
		{ ft = "neotest-output-panel", title = "Test Output" },
		-- noice's long-message splits (presets.long_message_to_split)
		{ ft = "noice", filter = is_split },
	},

	right = {
		trouble_at("right"), -- symbols outline, lsp defs/refs panels
		{ ft = "neotest-summary", title = "Tests" },
	},

	options = {
		left = { size = 35 },
		bottom = { size = 0.3 },
		right = { size = 0.3 },
	},
}
