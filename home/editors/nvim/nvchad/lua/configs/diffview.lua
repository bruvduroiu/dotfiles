-- diffview.nvim — whole-branch / PR diff review (file-tree panel + per-file diff).
-- Keymaps live in the plugin spec (lua/plugins/init.lua) under the <leader>r group.
--
-- Navigation is all builtin: ]c/[c walk hunks in a file (native diff motions,
-- restored buffer-locally in mappings.lua), <Tab>/<S-Tab> next/prev file,
-- <leader>e focus the file panel, gf open the file for real edits.

-- Hunk-level stage/reset via gitsigns, which lives on the RIGHT pane because
-- --imply-local makes it the live working-tree buffer. The left pane is a git
-- blob with no gitsigns state — guard instead of erroring there.
-- Note: gitsigns hunks are worktree-vs-index, matching the <leader>rw review;
-- in a base...HEAD review already-committed hunks have nothing to stage.
local function gs_hunk(fn_name, visual)
  return function()
    if not vim.b.gitsigns_status_dict then
      vim.notify("No gitsigns here — stage/reset from the local (right) pane", vim.log.levels.WARN)
      return
    end
    local gs = require("gitsigns")
    if visual then
      gs[fn_name]({ vim.fn.line("."), vim.fn.line("v") })
    else
      gs[fn_name]()
    end
  end
end

return {
  enhanced_diff_hl = true,

  -- --imply-local makes the RIGHT diff pane the live working-tree buffer, so
  -- LSP, gd, formatting — and gitsigns staging — work inside the review.
  -- Baked into the default so PR-range opens always get it.
  default_args = {
    DiffviewOpen = { "--imply-local" },
  },

  -- Tree listing reads best for big multi-file PRs.
  file_panel = {
    listing_style = "tree",
  },

  hooks = {
    -- gitsigns is lazy (NvChad: User FilePost) and attaches from a BufRead
    -- autocmd; diffview loads the local buffer in a hidden temp window, so
    -- when gitsigns isn't loaded yet that autocmd never ran for this buffer
    -- and hunk stage/reset silently has no state. Force load + attach here;
    -- attach is a no-op when already attached and rejects non-file buffers
    -- (left-pane blobs), so this is safe to fire for every diff buffer.
    diff_buf_read = function(bufnr)
      pcall(function()
        require("gitsigns").attach(bufnr)
      end)
    end,
  },

  keymaps = {
    view = {
      -- `-` mirrors the file panel's `-` (stage entry) at hunk granularity;
      -- whole-file staging stays on the file panel's `-`.
      { "n", "-", gs_hunk("stage_hunk"), { desc = "Stage/unstage hunk" } },
      { "v", "-", gs_hunk("stage_hunk", true), { desc = "Stage selected lines" } },
      -- `X` mirrors the file panel's `X` (restore entry) at hunk granularity.
      { "n", "X", gs_hunk("reset_hunk"), { desc = "Reset hunk" } },
      { "v", "X", gs_hunk("reset_hunk", true), { desc = "Reset selected lines" } },
    },
  },
}
