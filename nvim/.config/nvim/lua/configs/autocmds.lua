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
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    vim.opt.relativenumber = true
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    vim.opt.relativenumber = false
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

-- Enable spell check for all file types
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    vim.opt_local.spell = true
  end,
})

-- Auto-source Lua config files on save
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.lua",
  callback = function()
    if vim.fn.expand("<afile>"):find(vim.fn.stdpath("config")) then
      vim.cmd("source " .. vim.fn.expand("<afile>"))
      print("Config reloaded!")
    end
  end,
})

-- Auto open quickfix list on error after saving a file
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = "[^l]*", -- Excludes loclist
  callback = function()
    if #vim.fn.getqflist() > 0 then
      vim.cmd("copen")
    end
  end,
})

-- Auto-resize splits when the Neovim window is resized
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    vim.cmd("wincmd =")
  end,
})

-- Go to the last known cursor position when opening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Autocommand to close all terminal jobs on Vim exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    -- Iterate over all open terminal buffers and send the exit command
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].buftype == "terminal" then
        -- Close the terminal job gracefully
        vim.fn.jobstop(vim.b[buf].terminal_job_id) -- Terminate the job
      end
    end
  end,
})

-- Remove trailing spaces on save
vim.api.nvim_create_autocmd("BufWritePre", {
  command = "%s/\\s\\+$//e" -- Remove trailing spaces
})
