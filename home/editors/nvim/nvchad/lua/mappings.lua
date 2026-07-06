require("nvchad.mappings")

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

-- Code review: fuzzy-jump between dirty hunks across files (custom picker).
-- Rebound into the <leader>r "review" group alongside diffview/octo. Unique vs
-- diffview: fuzzy-typeahead over hunk section names, which diffview can't do.
local hunks_picker = require("configs.telescope").hunks_picker
map("n", "<leader>rh", hunks_picker, { desc = "Fuzzy hunks vs HEAD" })
map("n", "<leader>rH", function()
  vim.ui.input({ prompt = "Review against base: ", default = "origin/HEAD" }, function(base)
    if base and base ~= "" then
      hunks_picker({ base = base })
    end
  end)
end, { desc = "Fuzzy hunks vs base…" })
map("n", "<leader>gf", builtin.git_status, { desc = "Changed files (git status)" })

-- treesitter-textobjects remaps ]c/[c to next/prev class globally, which shadows
-- Vim's native ]c/[c "next/prev diff change" motion. In diff windows (diffview
-- review, :Gdiffsplit) restore native change-stepping buffer-locally so PR review
-- can walk changes the GitHub way. bang=true bypasses the global class-nav remap.
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "diff",
  callback = function()
    if not vim.wo.diff then
      return
    end
    map("n", "]c", function() vim.cmd.normal({ "]c", bang = true }) end, { buffer = 0, desc = "Next diff change" })
    map("n", "[c", function() vim.cmd.normal({ "[c", bang = true }) end, { buffer = 0, desc = "Prev diff change" })
  end,
})
