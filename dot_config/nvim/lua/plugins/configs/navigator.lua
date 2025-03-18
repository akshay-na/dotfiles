-- File: ~/.config/nvim/lua/plugins/configs/navigator.lua

local status, navigator = pcall(require, "navigator")
if status then
  navigator.setup({
    -- General LSP settings
    lsp = {
      disable_lsp = false,   -- Enable navigator.nvim to enhance LSP features
      lsp_installer = false, -- Disable Navigator’s LSP installer to avoid conflicts with lsp-zero
    },
  })
end
