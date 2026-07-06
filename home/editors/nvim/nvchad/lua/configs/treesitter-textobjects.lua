local select = require("nvim-treesitter-textobjects.select").select_textobject
local move = require("nvim-treesitter-textobjects.move")
local swap = require("nvim-treesitter-textobjects.swap")

require("nvim-treesitter-textobjects").setup({
	select = {
		lookahead = true,
		selection_modes = {
			["@parameter.outer"] = "v",
			["@function.outer"] = "V",
			["@class.outer"] = "V",
		},
		include_surrounding_whitespace = false,
	},
})

-- Select keymaps (visual + operator-pending)
local so = { "x", "o" }
vim.keymap.set(so, "af", function() select("@function.outer", "textobjects") end, { desc = "Around function" })
vim.keymap.set(so, "if", function() select("@function.inner", "textobjects") end, { desc = "Inside function" })
vim.keymap.set(so, "ac", function() select("@class.outer", "textobjects") end, { desc = "Around class" })
vim.keymap.set(so, "ic", function() select("@class.inner", "textobjects") end, { desc = "Inside class" })
vim.keymap.set(so, "aa", function() select("@parameter.outer", "textobjects") end, { desc = "Around parameter" })
vim.keymap.set(so, "ia", function() select("@parameter.inner", "textobjects") end, { desc = "Inside parameter" })

-- Move keymaps (normal + visual + operator-pending)
local nso = { "n", "x", "o" }
vim.keymap.set(nso, "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function" })
vim.keymap.set(nso, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Prev function" })
vim.keymap.set(nso, "]c", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class" })
vim.keymap.set(nso, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Prev class" })
vim.keymap.set(nso, "]a", function() move.goto_next_start("@parameter.inner", "textobjects") end, { desc = "Next parameter" })
vim.keymap.set(nso, "[a", function() move.goto_previous_start("@parameter.inner", "textobjects") end, { desc = "Prev parameter" })

-- Swap keymaps (normal only)
vim.keymap.set("n", "<leader>sa", function() swap.swap_next("@parameter.inner") end, { desc = "Swap parameter forward" })
vim.keymap.set("n", "<leader>sA", function() swap.swap_previous("@parameter.inner") end, { desc = "Swap parameter backward" })
