-- File: ~/.config/nvim/lua/plugins/configs/null-ls.lua

local status, null_ls = pcall(require, "null-ls")
if status then
  null_ls.setup({
    sources = {
      -- JavaScript/TypeScript Formatter: Prettier
      null_ls.builtins.formatting.prettier.with({
        extra_args = { "--config-precedence", "prefer-file" },
        condition = function(utils)
          return utils.root_has_file({ ".prettierrc", ".prettierrc.json", ".prettierrc.js" })
        end,
      }),

      -- Lua Formatter: Stylua
      null_ls.builtins.formatting.stylua.with({
        condition = function(utils)
          return utils.root_has_file({ "stylua.toml", ".stylua.toml" })
        end,
      }),

      -- Python Formatter: Black
      null_ls.builtins.formatting.black.with({
        extra_args = { "--fast" },
        condition = function(utils)
          return utils.root_has_file({ "pyproject.toml", "black.toml" })
        end,
      }),

      -- JavaScript/TypeScript Linter: ESLint
      null_ls.builtins.diagnostics.eslint.with({
        condition = function(utils)
          return utils.root_has_file({ ".eslintrc", ".eslintrc.js", ".eslintrc.json" })
        end,
      }),

      -- Shell Script Formatter and Linter: shfmt and shellcheck
      null_ls.builtins.formatting.shfmt,
      null_ls.builtins.diagnostics.shellcheck,
    },

    -- Async formatting to avoid blocking
    async = true,

    -- On attach, auto-format on save if the buffer supports it
    on_attach = function(client, bufnr)
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ bufnr = bufnr, async = true })
          end,
        })
      end
    end,
  })
end
