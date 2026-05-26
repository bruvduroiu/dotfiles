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
    summary = {
      open = "botright split | resize 15",
    },
    -- icons = {
    --   passed = "✓",
    --   failed = "✗",
    --   running = "●",
    --   skipped = "○",
    -- },
  })

  vim.keymap.set("n", "<leader>tr", function()
    require("neotest").run.run()
  end, { desc = "Run nearest test" })

  vim.keymap.set("n", "<leader>tR", function()
    require("neotest").run.run(vim.fn.expand("%"))
  end, { desc = "Run current file tests" })

  vim.keymap.set("n", "<leader>tt", function()
    require("neotest").summary.toggle()
  end, { desc = "Toggle test summary" })

  vim.keymap.set("n", "<leader>to", function()
    require("neotest").output.open({ enter = true, short = true })
  end, { desc = "Show test output" })

  vim.keymap.set("n", "<leader>tO", function()
    require("neotest").output_panel.toggle()
  end, { desc = "Toggle output panel" })

  vim.keymap.set("n", "<leader>ts", function()
    require("neotest").run.stop()
  end, { desc = "Stop test run" })

  vim.keymap.set("n", "<leader>tl", function()
    require("neotest").run.run_last()
  end, { desc = "Run last test" })
end
