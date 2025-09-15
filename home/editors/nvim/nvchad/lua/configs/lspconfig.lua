local configs = require("nvchad.configs.lspconfig")
configs.defaults()

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
				venvPath = vim.fn.getcwd() .. "/.venv",
				pythonPath = vim.fn.getcwd() .. "/.venv/bin/python3",
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
end

for name, opts in pairs(servers) do
	opts.on_init = configs.on_init
	opts.on_attach = on_attach
	opts.capabilities = configs.capabilities

	require("lspconfig")[name].setup(opts)
end
