-- File: ~/.config/nvim/lua/plugins/configs/null-ls.lua

local null_ls = require("null-ls")

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.prettier.with({
      extra_args = { "--config-precedence", "prefer-file" },
    }),
  },
})
