require("nvchad.mappings")


-- Free <leader>h from NvChad's horizontal terminal so Harpoon can use it
-- vim.keymap.del("n", "<leader>h") -- uncommented: use <leader>h for terminal

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

-- Code review: jump between dirty hunks across files
local hunks_picker = require("configs.telescope").hunks_picker
map("n", "<leader>gh", hunks_picker, { desc = "Git hunks vs HEAD" })
map("n", "<leader>gH", function()
  vim.ui.input({ prompt = "Review against base: ", default = "origin/HEAD" }, function(base)
    if base and base ~= "" then
      hunks_picker({ base = base })
    end
  end)
end, { desc = "Git hunks vs base…" })
map("n", "<leader>gf", builtin.git_status, { desc = "Changed files (git status)" })
