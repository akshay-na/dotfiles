-- ~/.config/nvim/lua/config/autocmds.lua

require "nvchad.autocmds"

-- Add any additional autocmds here to improve startup efficiency and --
-- Auto-save on focus loss and before exit
vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  callback = function()
    vim.cmd("silent! wall") -- Save all files
    print("Auto-saved all files.")
  end,
})

-- Switch between relative and absolute line numbers in insert and normal modes
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    vim.opt.relativenumber = false
  end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    vim.opt.relativenumber = true
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Only open nvim-tree if no file was specified on the command line
    if #vim.fn.argv() == 0 then
      require("nvim-tree.api").tree.toggle({ focus = false })
    end
  end,
})

-- Remove trailing spaces on save
vim.api.nvim_create_autocmd("BufWritePre", {
  command = "%s/\\s\\+$//e" -- Remove trailing spaces
})
