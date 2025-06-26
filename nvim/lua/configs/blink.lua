return {
  enabled = function() return not vim.tbl_contains({ "typr" }, vim.bo.filetype)
    and vim.bo.buftype ~= "prompt"
    and vim.b.completion ~= false
  end,
  keymap = {
    ["<C-n>"] = { "show", "hide" },
    ["<C-p>"] = { "show_documentation", "hide_documentation" },

    ["<C-k>"] = { "select_prev", "fallback" },
    ["<C-j>"] = { "select_next", "fallback" },
    ["<CR>"] = { "select_and_accept", "fallback" },

    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<C-b>"] = { "scroll_documentation_down", "fallback" },
  },
  completion = {
    menu = {
      draw = {
        treesitter = { "lsp" }
      }
    },
    ghost_text = {
      enabled = true,
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    }
  }
}
