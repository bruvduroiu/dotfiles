local configs = require("nvchad.configs.lspconfig")
configs.defaults()

-- Noice has lsp.signature.enabled = false, so signature_help uses the default
-- vim.lsp handler. focusable = false is REQUIRED: without it the cursor jumps
-- into the floating signature window on trigger. The :checkhealth noice warning
-- "signature_help is not configured to be handled by Noice" is expected here.
-- vim.lsp.with() was removed in nvim 0.12; wrap the handler manually (same effect).
vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
	return vim.lsp.handlers.signature_help(err, result, ctx,
		vim.tbl_deep_extend("force", { focusable = false, silent = true }, config or {}))
end

-- The interpreter pyright resolves imports against, chosen per project rather
-- than once when this file loads.
--
-- The previous value here was `vim.fn.exepath("python3")`, evaluated at startup:
-- every project got whatever python happened to be on PATH when nvim launched.
-- On NixOS that is a bare interpreter with no site-packages, so in a venv or uv
-- project every third-party import resolved to nothing - and typeshed hides half
-- of it, reporting stub-only hits (grpc, google.protobuf) as
-- reportMissingModuleSource *warnings* rather than errors.
--
-- Order: an already-activated venv (direnv, `source .venv/bin/activate`) is the
-- most specific answer available; then the project's own .venv/venv; then the
-- old PATH lookup as a floor. A repo that pins its own environment - pyright's
-- venvPath/venv under [tool.pyright], or a pyrightconfig.json - takes precedence
-- over whatever is sent from here, which is the right fix for a monorepo whose
-- python lives in a subdirectory.
local function project_python(root)
	local candidates = {}

	if vim.env.VIRTUAL_ENV then
		table.insert(candidates, vim.env.VIRTUAL_ENV .. "/bin/python")
	end
	if root then
		table.insert(candidates, root .. "/.venv/bin/python")
		table.insert(candidates, root .. "/venv/bin/python")
	end

	for _, path in ipairs(candidates) do
		if vim.uv.fs_stat(path) then
			return path
		end
	end

	-- exepath returns "" when nothing is found; return nil instead so
	-- pythonPath is left unset and pyright falls back to its own default,
	-- rather than being handed an empty interpreter path.
	local fallback = vim.fn.exepath("python3")
	return fallback ~= "" and fallback or nil
end

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
			},
		},
		-- root_dir is only known once a python buffer picks one (lspconfig's
		-- pyright root_markers: pyrightconfig.json, pyproject.toml, setup.py,
		-- setup.cfg, requirements.txt, Pipfile, .git - nearest ancestor wins),
		-- so the interpreter has to be filled in here rather than above.
		--
		-- Mutate in place. vim.lsp.Client captures `config.settings` by reference
		-- when the client is constructed, which happens BEFORE before_init runs -
		-- so rebuilding the table here (tbl_deep_extend and friends) leaves
		-- client.settings pointing at the original and the interpreter is never
		-- sent in the workspace/configuration reply.
		before_init = function(_, config)
			config.settings = config.settings or {}
			config.settings.python = config.settings.python or {}
			config.settings.python.pythonPath = project_python(config.root_dir)
		end,
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
