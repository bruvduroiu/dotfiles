return function()
  local neotest_ns = vim.api.nvim_create_namespace("neotest")
  vim.diagnostic.config({
    virtual_text = {
      format = function(diagnostic)
        local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
        return message
      end,
    },
  }, neotest_ns)

  require("neotest").setup({
    adapters = {
      require("neotest-go"),
      require("neotest-python")({
        dap = { justMyCode = false },
        args = { "-s", "-v", "--tb=short" },
      }),
      require("neotest-vitest"),
    },
    -- summary opens with neotest's default vsplit; edgy adopts it into the
    -- right rail by ft (the old "botright split" override opened it bottom
    -- full-width first, then edgy yanked it right — needless flicker).
    -- Keymaps live in the plugin spec (lua/plugins/init.lua) so they can
    -- lazy-load the plugin.
  })
end
