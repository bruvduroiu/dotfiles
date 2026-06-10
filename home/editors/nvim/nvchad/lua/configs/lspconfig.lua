local configs = require("nvchad.configs.lspconfig")
configs.defaults()

-- Noice has lsp.signature.enabled = false, so signature_help uses the default
-- vim.lsp handler. focusable = false is REQUIRED: without it the cursor jumps
-- into the floating signature window on trigger. The :checkhealth noice warning
-- "signature_help is not configured to be handled by Noice" is expected here.
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
	focusable = false,
	silent = true,
})

local servers = {
	html = {},
	cssls = {},
	gopls = {
		analyses = {
			unusedparams = true,
		},
		staticcheck = true,
		gofumpt = true,
	},
	ruff = {
		lint = {
			run = "onSave",
		},
	},
	zls = {},
	terraformls = {},
	templ = {},
  gh_actions_ls = {},

	pyright = {
		settings = {
			python = {
				analysis = {
					autoSearchPaths = true,
					typeCheckingMode = "basic",
				},
				pythonPath = vim.fn.exepath("python3"),
			},
		},
	},
	ts_ls = {
		settings = {
			completions = {
				completeFunctionCalls = true,
			},
		},
	},
}

local on_attach = function(client, bufnr)
	configs.on_attach(client, bufnr)
	client.server_capabilities.documentFormattingProvider = true
	-- Use Trouble for references instead of Telescope (persistent split for browsing)
	vim.keymap.set("n", "gr", "<cmd>Trouble lsp_references toggle<cr>",
		{ buffer = bufnr, desc = "References (Trouble)" })
end

for name, opts in pairs(servers) do
  local ok = pcall(function()
    opts.on_init = configs.on_init
    opts.on_attach = on_attach
    opts.capabilities = configs.capabilities
    vim.lsp.config(name, opts)
    vim.lsp.enable({name})
  end)

  if not ok then
    vim.notify("Failed to set up LSP: " .. name, vim.log.levels.ERROR)
  end
end
