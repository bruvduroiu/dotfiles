local ts = require("telescope")
local actions = require("telescope.actions")
local layout_actions = require("telescope.actions.layout")
local undo_actions = require("telescope-undo.actions")

local h_pct = 0.90
local w_pct = 0.80
local w_limit = 100

-- Compact: vertical, preview hidden — for quick picks (files, buffers, branches)
local compact = {
  preview = { hide_on_startup = true },
  layout_strategy = "vertical",
  layout_config = {
    vertical = {
      mirror = true,
      prompt_position = "top",
      width = function(_, cols, _)
        return math.min(math.floor(w_pct * cols), w_limit)
      end,
      height = function(_, _, rows)
        return math.floor(rows * h_pct)
      end,
      preview_cutoff = 10,
      preview_height = 0.4,
    },
  },
}

-- Fullscreen: flex (adapts to terminal width), preview always visible — for grep, LSP, undo
local fullscreen = {
  preview = { hide_on_startup = false },
  layout_strategy = "flex",
  layout_config = {
    flex = { flip_columns = 120 },
    horizontal = {
      mirror = false,
      prompt_position = "top",
      width = function(_, cols, _)
        return math.floor(cols * w_pct)
      end,
      height = function(_, _, rows)
        return math.floor(rows * h_pct)
      end,
      preview_cutoff = 10,
      preview_width = 0.5,
    },
    vertical = {
      mirror = true,
      prompt_position = "top",
      width = function(_, cols, _)
        return math.floor(cols * w_pct)
      end,
      height = function(_, _, rows)
        return math.floor(rows * h_pct)
      end,
      preview_cutoff = 10,
      preview_height = 0.5,
    },
  },
}

ts.setup({
  defaults = vim.tbl_extend("error", compact, {
    sorting_strategy = "ascending",
    path_display = { "filename_first" },
    file_ignore_patterns = { "node_modules", ".venv/", ".git/", "%.lock" },
    mappings = {
      i = {
        ["<C-Space>"] = actions.to_fuzzy_refine,
        ["<C-o>"] = layout_actions.toggle_preview,
      },
      n = {
        ["o"] = layout_actions.toggle_preview,
        ["<C-c>"] = actions.close,
      },
    },
  }),
  pickers = {
    find_files = vim.tbl_extend("force", compact, {
      find_command = { "fd", "--type", "f", "-H", "--strip-cwd-prefix" },
    }),
    live_grep = fullscreen,
    grep_string = fullscreen,
    lsp_dynamic_workspace_symbols = fullscreen,
    help_tags = fullscreen,
    buffers = {
      sort_lastused = true,
      mappings = {
        n = { ["dd"] = actions.delete_buffer },
      },
    },
    git_branches = compact,
  },
  extensions = {
    undo = vim.tbl_extend("force", fullscreen, {
      vim_diff_opts = { ctxlen = 4 },
      mappings = {
        i = {
          ["<cr>"] = undo_actions.restore,
          ["<C-y>d"] = undo_actions.yank_deletions,
          ["<C-y>a"] = undo_actions.yank_additions,
        },
        n = {
          ["<cr>"] = undo_actions.restore,
          ["ya"] = undo_actions.yank_additions,
          ["yd"] = undo_actions.yank_deletions,
        },
      },
    }),
  },
})

ts.load_extension("fzf")
ts.load_extension("undo")
