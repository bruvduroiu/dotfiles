require("nvchad.mappings")

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

map("n", "<C-P>", "<cmd> Telescope find_files<cr>")
map("n", "<C-f>", "<cmd> Telescope live_grep<cr>")
map("n", "<leader>fs", "<cmd> Telescope grep_string<cr>")
map("n", "<leader>fS", "<cmd> Telescope lsp_dynamic_workspace_symbols<cr>")
map("n", "<leader>fb", "<cmd> Telescope buffers<cr>")
map("n", "<leader>fh", "<cmd> Telescope help_tags<cr>")
map("n", "<leader>co", "<cmd> Telescope git_branches<cr>")
