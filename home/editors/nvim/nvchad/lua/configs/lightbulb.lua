return {
  sign = {
    enabled = true,
    text = "󰌶",
    texthl = "DiagnosticSignHint",
    linehl = "",
    numhl = "",
    priority = 10,
  },
  float = {
    enabled = false,
  },
  virtual_text = {
    enabled = false,
  },
  status_text = {
    enabled = false,
  },
  autocmd = {
    enabled = true,
    updatetime = 100,
    events = { "CursorHold", "CursorHoldI", "InsertLeave" },
    pattern = { "*" },
  },
  ignore = {
    clients = {},
    ft = {},
    actions = {},
  },
}
