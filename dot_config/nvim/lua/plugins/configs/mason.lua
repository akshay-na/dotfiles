-- File: ~/.config/nvim/lua/plugins/configs/mason.lua

local status, mason = pcall(require, "mason")
if status then
  mason.setup({
    ensure_installed = {
      "prettier",
      "eslint_d",
    },
    auto_update = false,
  })
end
