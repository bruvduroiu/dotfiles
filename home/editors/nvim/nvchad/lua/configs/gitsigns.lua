return {
  signs = {
    add = { text = "│" },
    change = { text = "│" },
    delete = { text = "▁" },
    topdelete = { text = "▔" },
    changedelete = { text = "~" },
    untracked = { text = "┆" },
  },
  signcolumn = true,
  numhl = true,
  linehl = false,
  word_diff = false,
  watch_gitdir = {
    follow_files = true,
  },
  auto_attach = true,
  attach_to_untracked = true,
  current_line_blame = true,
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = "eol",
    delay = 1000,
    ignore_whitespace = false,
    virt_text_priority = 100,
  },
  current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil,
  max_file_length = 40000,
  preview_config = {
    border = "rounded",
    style = "minimal",
    relative = "cursor",
    row = 0,
    col = 1,
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation (use ]g/[g to avoid conflict with treesitter ]c/[c)
    map("n", "]g", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]g", bang = true })
      else
        gs.nav_hunk("next")
      end
    end, { desc = "Next hunk" })

    map("n", "[g", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[g", bang = true })
      else
        gs.nav_hunk("prev")
      end
    end, { desc = "Previous hunk" })

    -- Actions
    map("n", "<leader>gb", gs.blame, { desc = "Blame" })
    map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
    map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
    map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Stage selected hunk" })
    map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Reset selected hunk" })
    map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
    map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
    map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
    map("n", "<leader>hi", gs.preview_hunk_inline, { desc = "Preview hunk inline" })
    map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
    map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle line blame" })
    map("n", "<leader>tw", gs.toggle_word_diff, { desc = "Toggle word diff" })
    map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
    map("n", "<leader>hD", function() gs.diffthis("~") end, { desc = "Diff against HEAD~" })
    map("n", "<leader>hQ", function() gs.setqflist("all") end, { desc = "Hunks as qflist (all)" })
    map("n", "<leader>hq", gs.setqflist, { desc = "Hunks as qflist (buffer)" })
    map("n", "<leader>hu", gs.toggle_deleted, { desc = "Toggle deleted" })

    -- Text object
    map({ "o", "x" }, "ih", gs.select_hunk, { desc = "Select hunk inner" })
  end,
}
