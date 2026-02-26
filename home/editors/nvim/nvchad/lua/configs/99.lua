local _99 = require("99")

local cwd = vim.uv.cwd()
local basename = vim.fs.basename(cwd)

_99.setup({
  provider = _99.Providers.ClaudeCodeProvider,  -- default: OpenCodeProvider
  logger = {
    level = _99.DEBUG,
    path = "/tmp/" .. basename .. ".99.debug",
    print_on_error = true,
  },
  tmp_dir = "./tmp",

  completion = {
    -- cursor_rules = "<custom path to cursor rules>"
    custom_rules = {
      "scratch/custom_rules/",
    },
    source = "blink",
  },

  md_files = {
    "AGENT.md",
  },
})

