-- lua/plugins/configs/lsp.lua

local lsp = require('lsp-zero').preset({
  -- Choose 'recommended' for sensible defaults, but customize as needed
  name = 'recommended',
  set_lsp_keymaps = false, -- We’ll set keymaps manually to match your existing setup
})

-- Define your language servers and filetypes, as you did previously
local servers = {
  ["html"] = "html",
  ["cssls"] = "css",
  ["tsserver"] = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
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
  -- Uncomment any additional servers here
  -- ["graphql"] = "graphql",
  -- ["rust_analyzer"] = "rust",
  -- ["solidity_ls"] = "solidity",
}

-- Automatically install and configure servers with Mason-LSPConfig
lsp.ensure_installed(vim.tbl_keys(servers))

-- Setting up servers with specific file types, capabilities, and on_attach
local lspconfig = require("lspconfig")
for server_name, filetypes in pairs(servers) do
  lspconfig[server_name].setup({
    on_attach = function(client, bufnr)
      lsp.build_options('on_attach')(client, bufnr)                   -- lsp-zero on_attach function
      require("navigator.lspclient.mapping").setup({ bufnr = bufnr }) -- Use navigator.nvim’s mappings
    end,
    capabilities = lsp.capabilities,
    filetypes = type(filetypes) == "table" and filetypes or { filetypes },
  })
end


-- Enable caching for LSP handlers (preserving the definition reuse functionality)
vim.lsp.handlers["textDocument/definition"] = vim.lsp.with(vim.lsp.handlers.definition, {
  reuse_win = true,
})

-- Finalize `lsp-zero` setup
lsp.setup()
