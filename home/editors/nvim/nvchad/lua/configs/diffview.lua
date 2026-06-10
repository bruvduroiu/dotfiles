-- diffview.nvim: review the whole change-stack as a hunk stream.
--
-- diffview itself only stages WHOLE FILES (stage_all / toggle_stage_entry). Hunk
-- granularity comes from gitsigns operating inside diffview's right (working-tree)
-- pane: that buffer is the real file, gitsigns auto-attaches and diffs it against
-- the index -- the same base diffview shows under "Changes". Staging a hunk writes
-- the index, which diffview watches, so the panel auto-refreshes.
--
-- Review loop (LLM code):
--   <leader>gdd            open: panel = Changes (unreviewed) + Staged (accepted)
--   ]h / [h               walk hunks, auto-rolling into the next/prev file
--   <leader>a / <leader>r  accept (stage) / reject (reset) the hunk  (also visual)
--   <leader>A / <leader>R  accept / reject the whole file (panel)
--   <tab> / <s-tab>        jump between files
--   q                      close
-- When "Changes" is empty the stack is reviewed; "Staged" is your commit.

local actions = require("diffview.actions")

-- gitsigns is the hunk engine. All helpers are no-ops off a gitsigns buffer
-- (e.g. the left/index pane), so keys are safe to press anywhere in the view.
local function gs()
  return package.loaded.gitsigns
end

-- Move to the next/prev file entry, then land on its first/last hunk.
local function roll(dir)
  if dir == "next" then
    actions.select_next_entry()
  else
    actions.select_prev_entry()
  end
  vim.schedule(function()
    local g = gs()
    if g then
      g.nav_hunk(dir, { wrap = true }) -- cursor at file top -> first (or last) hunk
    end
  end)
end

-- Hunk navigation that crosses file boundaries: step within the file, and when
-- there is no hunk left in this direction, roll into the neighbouring file.
local function nav(dir)
  local g = gs()
  if not g then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local hunks = g.get_hunks(bufnr)
  if hunks == nil then
    return -- not attached (index pane); do nothing
  end
  if #hunks == 0 then
    roll(dir) -- file has no working-tree hunks; skip to the neighbour
    return
  end
  local before = vim.api.nvim_win_get_cursor(0)[1]
  g.nav_hunk(dir, { wrap = false })
  vim.schedule(function()
    if vim.api.nvim_win_get_cursor(0)[1] == before then
      roll(dir) -- did not move => at the last hunk this way => next file
    end
  end)
end

-- Accept = stage the hunk (or the visually selected lines). Reject = reset it.
local function stage_hunk()
  local g = gs()
  if g then
    g.stage_hunk()
  end
end
local function reset_hunk()
  local g = gs()
  if g then
    g.reset_hunk()
  end
end
local function stage_range()
  local g = gs()
  if g then
    g.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end
end
local function reset_range()
  local g = gs()
  if g then
    g.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end
end

return {
  enhanced_diff_hl = true, -- richer in-hunk add/change highlighting
  use_icons = true,

  file_panel = {
    listing_style = "list", -- flat file list, not a tree (hunk-first mindset)
    win_config = { position = "left", width = 35 },
  },

  file_history_panel = {
    win_config = { position = "bottom", height = 16 },
  },

  keymaps = {
    -- providing keymaps merges with diffview defaults; these add/override.
    view = {
      { "n", "]h", function() nav("next") end, { desc = "Next hunk (rolls into next file)" } },
      { "n", "[h", function() nav("prev") end, { desc = "Prev hunk (rolls into prev file)" } },
      { "n", "<leader>a", stage_hunk, { desc = "Accept hunk (stage)" } },
      { "n", "<leader>r", reset_hunk, { desc = "Reject hunk (reset)" } },
      { "x", "<leader>a", stage_range, { desc = "Accept selected lines (stage)" } },
      { "x", "<leader>r", reset_range, { desc = "Reject selected lines (reset)" } },
      { "n", "<leader>A", actions.toggle_stage_entry, { desc = "Accept whole file (stage)" } },
      { "n", "<leader>R", actions.restore_entry, { desc = "Reject whole file (restore)" } },
      { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
    },
    file_panel = {
      { "n", "]h", function() nav("next") end, { desc = "Next hunk" } },
      { "n", "[h", function() nav("prev") end, { desc = "Prev hunk" } },
      { "n", "<leader>a", actions.toggle_stage_entry, { desc = "Accept file (stage)" } },
      { "n", "<leader>r", actions.restore_entry, { desc = "Reject file (restore)" } },
      { "n", "<leader>A", actions.stage_all, { desc = "Accept all files" } },
      { "n", "<leader>R", actions.unstage_all, { desc = "Unstage all files" } },
      { "n", "<cr>", actions.select_entry, { desc = "Open diff for entry" } },
      { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
    },
    file_history_panel = {
      { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
    },
  },
}
