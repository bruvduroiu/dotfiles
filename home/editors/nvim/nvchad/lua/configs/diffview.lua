-- diffview.nvim — whole-branch / PR diff review (file-tree panel + per-file diff).
-- Keymaps live in the plugin spec (lua/plugins/init.lua) under the <leader>r group.
return {
  enhanced_diff_hl = true,

  -- --imply-local makes the RIGHT diff pane the live working-tree buffer, so
  -- LSP, gd, and formatting work inside the review (without it the right side is
  -- a read-only git blob). Baked into the default so PR-range opens always get it.
  default_args = {
    DiffviewOpen = { "--imply-local" },
  },

  -- Tree listing reads best for big multi-file PRs.
  file_panel = {
    listing_style = "tree",
  },
}
