require("nvchad.mappings")

-- Free <leader>h from NvChad's horizontal terminal so Harpoon can use it
vim.keymap.del("n", "<leader>h")

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Telescope pickers
local builtin = require("telescope.builtin")
map("n", "<C-P>", builtin.find_files, { desc = "Find files" })
map("n", "<C-f>", builtin.live_grep, { desc = "Live grep" })
map("n", "<leader>fs", builtin.grep_string, { desc = "Grep string under cursor" })
map("n", "<leader>fS", builtin.lsp_dynamic_workspace_symbols, { desc = "Workspace symbols" })
map("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
map("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
map("n", "<leader>co", builtin.git_branches, { desc = "Git branches" })
map("n", "<leader>fu", "<cmd>Telescope undo<cr>", { desc = "Undo tree" })
map("n", "<leader>fr", builtin.resume, { desc = "Resume last picker" })
map("n", "<leader>fo", builtin.oldfiles, { desc = "Recent files" })

