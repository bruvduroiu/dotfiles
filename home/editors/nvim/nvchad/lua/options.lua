require("nvchad.options")

-- add yours here!

local o = vim.o
o.cursorlineopt = "both" -- to enable cursorline!

-- Hugo template filetype detection
-- Detect .html files in Hugo layouts/templates directories as htmlhugo (vim-hugo filetype)
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*/layouts/*.html", "*/layouts/**/*.html" },
	callback = function()
		vim.bo.filetype = "htmlhugo"
	end,
})
