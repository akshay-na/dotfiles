-- ~/.config/nvim/lua/options.lua

require "nvchad.options"

-- Add any additional options here to improve startup efficiency and --
local opt = vim.opt
local o = vim.o
local g = vim.g

-- Basic settings for efficiency
opt.number = true                  -- Show line numbers
opt.relativenumber = false         -- Enable relative line numbers for easier line jumps
opt.smartindent = true             -- Smart indentation
opt.expandtab = true               -- Use spaces instead of tabs
opt.tabstop = 4                    -- Tab width
opt.shiftwidth = 4                 -- Indentation width
opt.termguicolors = true           -- Enable 24-bit RGB colors
opt.updatetime = 200               -- Faster completion and diagnostics
opt.cursorline = true              -- Highlight the current line
opt.scrolloff = 8                  -- Maintain cursor context
opt.swapfile = false               -- Disable swap files for lower disk I/O
opt.backup = false                 -- Disable backup for faster write speeds
opt.undofile = true                -- Enable undofile for persistent undo history
opt.clipboard = "unnamedplus"      -- System clipboard integration
opt.ignorecase = true              -- Ignore case in search
opt.smartcase = true               -- Smart case-sensitive search
opt.hlsearch = false               -- Disable search highlight by default
opt.incsearch = true               -- Incremental search
opt.signcolumn = "yes"             -- Show sign column for LSP, Git, diagnostics
opt.splitright = true              -- Vertical splits open on the right
opt.splitbelow = true              -- Horizontal splits open below
opt.mouse = "a"                    -- Enable mouse support
opt.wrap = false                   -- Disable line wrapping

o.timeoutlen = 300                 -- Shorter key timeout for faster mappings
o.completeopt = "menuone,noselect" -- Completion menu optimized

g.better_whitespace_enabled = 1
g.strip_whitespace_on_save = 1

g.loaded_matchparen = 1 -- Disable matchparen for less flicker

-- Miscellaneous productivity tweaks
vim.cmd("syntax on")                 -- Enable syntax highlighting
vim.cmd("filetype plugin indent on") -- Enable filetype-based plugins and indentation

return {}
