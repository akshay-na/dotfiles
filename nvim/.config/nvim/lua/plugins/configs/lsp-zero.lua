-- File: ~/.config/nvim/lua/plugins/configs/lsp.lua

local lsp = require('lsp-zero').preset({
  name = 'recommended',
  set_lsp_keymaps = false, -- Manually manage keymaps
})

-- Define language servers and filetypes
local servers = {
  ["html"] = "html",
  ["cssls"] = "css",
  ["ts_ls"] = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  ["volar"] = "vue",
  ["pyright"] = "python",
  ["bashls"] = "sh",
  ["lemminx"] = "xml",
  ["jsonls"] = { "json", "jsonc" },
  ["marksman"] = "markdown",
  ["yamlls"] = "yaml",
  ["dockerls"] = "dockerfile",
  ["prismals"] = "prisma",
  ["lua_ls"] = "lua",
  -- Uncomment additional servers as needed
  -- ["graphql"] = "graphql",
  -- ["rust_analyzer"] = "rust",
  -- ["solidity_ls"] = "solidity",
}

-- Install LSP servers with Mason
lsp.ensure_installed(vim.tbl_keys(servers))

-- Define common on_attach function for all LSPs
lsp.on_attach(function(client, bufnr)
  -- Disable formatting capabilities for all language servers to defer to null-ls
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false

  -- Optionally set up navigator mappings if available
  if package.loaded["navigator"] then
    require("navigator.lspclient.mapping").setup({ bufnr = bufnr })
  end
end)

-- Configure language servers
local lspconfig = require("lspconfig")
for server_name, filetypes in pairs(servers) do
  lspconfig[server_name].setup({
    filetypes = type(filetypes) == "table" and filetypes or { filetypes },
  })
end

-- Custom configuration for Lua language server
lsp.configure('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})

-- Enhanced diagnostics with floating previews and icons
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true,
    virtual_text = { spacing = 4, prefix = "●" },
    update_in_insert = false,
  }
)

-- Reuse window for go-to definition
vim.lsp.handlers["textDocument/definition"] = vim.lsp.with(vim.lsp.handlers.definition, { reuse_win = true })

-- Finalize LSP-zero setup
lsp.setup()
