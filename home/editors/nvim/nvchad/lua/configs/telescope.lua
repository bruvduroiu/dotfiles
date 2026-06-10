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
    file_ignore_patterns = { "node_modules", ".venv/", ".git/", "%.lock", "CLAUDE.md", "%AGENTS.md" },
    mappings = {
      i = {
        ["<C-S>"] = actions.to_fuzzy_refine,
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
    -- Big preview for reviewing changed files, but start hidden ('o' toggles it)
    git_status = vim.tbl_extend("force", fullscreen, {
      preview = { hide_on_startup = true },
    }),
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

-- ── Cross-file hunk picker ────────────────────────────────────────────────
-- Flat, fuzzy-searchable list of every hunk dirty vs a base (default HEAD),
-- with a diff previewer. Built by parsing `git diff` directly rather than
-- gitsigns.get_hunks(), so it never races the async buffer attach and works
-- on files that aren't open yet.
local function parse_git_hunks(base)
  base = base or "HEAD"
  -- List form → no shell, so fish quoting can't interfere.
  local lines = vim.fn.systemlist({ "git", "--no-pager", "diff", "--no-color", "-U3", base })
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local results, cur_file, cur = {}, nil, nil
  local function flush()
    if cur then
      table.insert(results, cur)
      cur = nil
    end
  end

  for _, line in ipairs(lines) do
    if line:sub(1, 11) == "diff --git " then
      flush() -- new file boundary: close out the previous file's last hunk
    elseif line:sub(1, 6) == "+++ b/" then
      local p = line:sub(7)
      if p ~= "/dev/null" then
        cur_file = p
      end
    elseif line:sub(1, 2) == "@@" then
      flush()
      local nstart = tonumber(line:match("^@@ %-%d+,?%d* %+(%d+)"))
      cur = {
        file = cur_file,
        lnum = nstart or 1,
        section = line:match("@@.-@@%s?(.*)") or "",
        lines = { line },
        adds = 0,
        dels = 0,
      }
    elseif cur then
      local c = line:sub(1, 1)
      if c == "+" then
        cur.adds = cur.adds + 1
      elseif c == "-" then
        cur.dels = cur.dels + 1
      end
      if c ~= "\\" then -- skip "\ No newline at end of file"
        table.insert(cur.lines, line)
      end
    end
  end
  flush()
  return results
end

local function hunks_picker(opts)
  opts = opts or {}
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values

  local hunks = parse_git_hunks(opts.base)
  if vim.tbl_isempty(hunks) then
    vim.notify("No dirty hunks vs " .. (opts.base or "HEAD"), vim.log.levels.INFO)
    return
  end

  pickers
    .new(fullscreen, {
      prompt_title = "Git Hunks (" .. (opts.base or "HEAD") .. ")",
      finder = finders.new_table({
        results = hunks,
        entry_maker = function(e)
          return {
            value = e,
            -- filename + lnum make the default select action jump straight to the hunk
            filename = e.file,
            lnum = e.lnum,
            ordinal = e.file .. " " .. e.section,
            display = string.format("%s:%d  +%d -%d  %s", e.file, e.lnum, e.adds, e.dels, e.section),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_buffer_previewer({
        title = "Hunk Diff",
        define_preview = function(self, entry)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entry.value.lines)
          vim.bo[self.state.bufnr].filetype = "diff"
        end,
      }),
    })
    :find()
end

return {
  hunks_picker = hunks_picker,
}
