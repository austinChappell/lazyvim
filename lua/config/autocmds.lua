-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Some repos (e.g. web_app) keep a stricter `eslint.config.local.mjs` that's
-- normally only run by a pre-commit hook via `--config`, so editor diagnostics
-- silently use the looser default `eslint.config.mjs` instead. Point the
-- eslint LSP at the stricter file when one exists at the project root.
--
-- neoconf.nvim used to handle this kind of per-project override, but it hooks
-- the legacy `require('lspconfig')[server].setup()` path; LazyVim now enables
-- servers via the native vim.lsp.config()/vim.lsp.enable() API, which neoconf
-- never patches, so it's a no-op on current Neovim/LazyVim.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "eslint" or not client.config.root_dir then
      return
    end

    local override = client.config.root_dir .. "/eslint.config.local.mjs"
    if vim.uv.fs_stat(override) then
      client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
        options = { overrideConfigFile = override },
      })
      client:notify("workspace/didChangeConfiguration", { settings = client.settings })
    end
  end,
})
