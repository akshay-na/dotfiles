-- lua/plugins/configs/lspconfig.lua

-- Define the servers with their respective filetypes as you provided
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
  -- ["graphql"] = "graphql",
  -- ["rust_analyzer"] = "rust",
  -- ["solidity_ls"] = "solidity",
}

-- Extract server names as a list for ensure_installed
local server_names = {}
for server_name, _ in pairs(servers) do
  table.insert(server_names, server_name)
end

print(server_names)

-- Install and configure Mason and Mason-LSPConfig
require("mason").setup()
require("mason-lspconfig").setup {
  ensure_installed = server_names, -- Automatically install servers in `servers`
  automatic_installation = true,
}

local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"

-- Consolidated setup for each LSP server in `servers`
for server_name, filetypes in pairs(servers) do
  lspconfig[server_name].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
    filetypes = type(filetypes) == "table" and filetypes or { filetypes }
  }
end

-- Key binding to bypass auto-formatting and organizing (Ctrl + Shift + S)
vim.api.nvim_set_keymap('n', '<C-S-s>',
  [[:lua vim.lsp.buf.formatting_sync(nil, 1000)<CR>:lua vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })<CR>]],
  { noremap = true, silent = true })

-- Enable LSP caching for faster response times
vim.lsp.handlers["textDocument/definition"] = vim.lsp.with(vim.lsp.handlers.definition, {
  reuse_win = true,
})
