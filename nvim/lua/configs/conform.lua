local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    python = { "ruff_format", "ruff_fix", "ruff_organize_imports" },
    go = { "goimports", "gofmt" },
    json = { "jq" },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_format = "fallback",
  },
  -- Set the log level. Use `:ConformInfo` to see the location of the log file.
  log_level = vim.log.levels.ERROR,
  -- Conform will notify you when a formatter errors
  notify_on_error = true,
  -- Conform will notify you when no formatters are available for the buffer
  notify_no_formatters = true,
}

return options
