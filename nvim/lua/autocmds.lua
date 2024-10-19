local autocmd = vim.api.nvim_create_autocmd

autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client.supports_method('textDocument/formatting') then
      -- Format the current buffer on save
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = args.buf,
        callback = function()
          vim.lsp.buf.format({bufnr = args.buf, id = client.id})
        end,
      })
    end
  end,
})

autocmd('LspDetach', {
  callback = function(args)
    -- Get the detaching client
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    -- Remove the autocommand to format the buffer on save, if it exists
    if client.supports_method('textDocument/formatting') then
        vim.api.nvim_clear_autocmds({
            event = 'BufWritePre',
            buffer = args.buf,
        })
    end
  end,
})

