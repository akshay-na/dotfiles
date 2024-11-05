-- File: ~/.config/nvim/lua/configs/lsp-config.lua

-- Unified configuration table for LSP, Mason, and Treesitter parsers
local server_and_parser_config = {
  lsp_servers = { "html", "cssls", "ts_ls", "volar", "pyright", "bashls", "lemminx", "jsonls", "marksman", "yamlls", "dockerls", "prismals", "lua_ls" },
  tools = { "prettier", "eslint_d" },
  parsers = { "lua", "python", "javascript", "typescript", "dockerfile", "json", "jsonc", "xml" },
}

-- Mason Setup
local mason_status, mason = pcall(require, "mason")
if mason_status then
  mason.setup({
    ensure_installed = server_and_parser_config.tools,
    auto_update = false,
  })
end

-- LSP Zero Setup
local lsp_status, lsp = pcall(require, "lsp-zero")
if lsp_status then
  lsp.preset('recommended')
  lsp.ensure_installed(server_and_parser_config.lsp_servers)

  lsp.on_attach(function(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
    if package.loaded["navigator"] then
      require("navigator.lspclient.mapping").setup({ bufnr = bufnr })
    end
  end)

  -- Configure each LSP server
  local lspconfig = require("lspconfig")
  for _, server_name in ipairs(server_and_parser_config.lsp_servers) do
    lspconfig[server_name].setup({})
  end

  -- Lua LSP specific configuration
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

  -- Enhanced diagnostics
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
      underline = true,
      virtual_text = { spacing = 4, prefix = "●" },
      update_in_insert = false,
    }
  )

  -- Reuse window for go-to definition
  vim.lsp.handlers["textDocument/definition"] = vim.lsp.with(vim.lsp.handlers.definition, { reuse_win = true })

  -- Finalize LSP setup
  lsp.setup()
end

-- Lazy Load Navigator
local navigator_status, navigator = pcall(require, "navigator")
if navigator_status then
  navigator.setup({
    lsp = {
      disable_lsp = false,
      lsp_installer = false,
    },
  })
end

-- Lazy Load Treesitter
local nvim_treesitter_status, nvim_treesitter = pcall(require, "nvim-treesitter")
if nvim_treesitter_status then
  nvim_treesitter.setup({
    ensure_installed = server_and_parser_config.parsers,
    highlight = { enable = true },
  })
end


-- Treesitter Context
local treesitter_context_status, treesitter_context = pcall(require, "treesitter-context")
if treesitter_context_status then
  treesitter_context.setup({
    enable = true,
    max_lines = 0,
    trim_scope = 'both',
    mode = 'topline', -- Ensures the context updates with scrolling
    patterns = {
      default = {
        'class', 'function', 'method', 'for', 'while', 'if', 'switch', 'case',
        'interface', 'struct', 'enum', 'trait', 'impl', 'type', 'const', 'let',
        'do', 'try', 'catch', 'finally', 'repeat', 'until', 'match', 'namespace',
        'module', 'import', 'export', 'table', 'array', 'map', 'object',
        'attribute', 'annotation', 'alias', 'typedef', 'record', 'union',
      },
      lua = { 'table_constructor', 'local_function' },
      python = { 'def', 'class', 'with', 'try', 'except' },
      javascript = { 'variable_declaration', 'arrow_function', 'class_method' },
      typescript = { 'interface_declaration', 'type_alias_declaration' },
      rust = { 'macro', 'impl_item', 'mod_item' },
      go = { 'func', 'var_declaration', 'const_declaration' },
    },
    zindex = 10,
    mode = 'cursor',
    separator = '-',
  })
end
