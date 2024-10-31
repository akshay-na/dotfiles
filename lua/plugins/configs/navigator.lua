-- File: ~/.config/nvim/lua/plugins/configs/navigator.lua

require("navigator").setup({
  lsp = {
    disable_lsp = false,   -- Allow `navigator.nvim` to enhance LSP features
    lsp_installer = false, -- Disable Navigator’s installer to avoid conflicts with `lsp-zero`
  },
})
