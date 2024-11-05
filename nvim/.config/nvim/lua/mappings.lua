-- ~/.config/nvim/lua/mappings.lua - Combined Key Mappings for Productivity

-- Load NvChad's default mappings
require "nvchad.mappings"

-- add yours here
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Save file with Ctrl-s in normal, insert, and visual modes
map({ "n", "i", "v" }, "<C-s>", "<cmd> w <CR>", { desc = "Save file" })

-- Easy Align Mapping
map("n", "ga", "<Plug>(EasyAlign)", { desc = "Align text" })
map("x", "ga", "<Plug>(EasyAlign)", { desc = "Align text in visual mode" })

-- Set keymap for bypassing auto-formatting and organizing imports (Ctrl + Shift + S)
map('n', '<C-S-s>',
  [[:lua vim.lsp.buf.formatting_sync(nil, 1000)<CR>:lua vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })<CR>]],
  opts)

-- Comments plugin (toggle comments in Normal and Visual mode)
map("n", "gcc", "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", opts)
map("v", "gc", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", opts)

-- LSP (Language Server Protocol) mappings for code actions, navigation, and formatting
map("n", "<leader>f", "<cmd>lua vim.lsp.buf.format()<CR>", opts)       -- Format code
map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts) -- Code actions
map("n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)  -- Go to definition
map("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)  -- Find references
map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)      -- Rename symbol

-- Optional: Key mappings for quick Harpoon actions
map("n", "<leader>a", ":lua require('harpoon.mark').add_file()<CR>",
  opts)
map("n", "<leader>h", ":lua require('harpoon.ui').toggle_quick_menu()<CR>",
  opts)
map("n", "<leader>1", ":lua require('harpoon.ui').nav_file(1)<CR>", opts)
map("n", "<leader>2", ":lua require('harpoon.ui').nav_file(2)<CR>", opts)
map("n", "<leader>3", ":lua require('harpoon.ui').nav_file(3)<CR>", opts)
map("n", "<leader>4", ":lua require('harpoon.ui').nav_file(4)<CR>", opts)

-- Terminal Mapping
map('t', '<M-h>', '<C-\\><C-n><C-w>h', opts)
map('t', '<M-j>', '<C-\\><C-n><C-w>j', opts)
map('t', '<M-k>', '<C-\\><C-n><C-w>k', opts)
map('t', '<M-l>', '<C-\\><C-n><C-w>l', opts)

-- File Explorer Toggle (NvimTree)
map("n", "<leader>e", ":NvimTreeToggle<CR>", opts)

-- Git mappings for stage, reset, and blame
map("n", "<leader>gs", ":Gitsigns stage_hunk<CR>", opts) -- Stage Git hunk
map("n", "<leader>gr", ":Gitsigns reset_hunk<CR>", opts) -- Reset Git hunk
map("n", "<leader>gb", ":Gitsigns blame_line<CR>", opts) -- Git blame line

-- Key mappings for window navigation
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Toggle between the current buffer and the terminal
map('n', '<leader>t', '<C-w>w', opts)
map('t', '<leader>t', '<C-w>w', opts)

-- Buffer navigation
map("n", "<Tab>", ":bnext<CR>", opts)
map("n", "<S-Tab>", ":bprevious<CR>", opts)

-- Quick save and quit
map("n", "<leader>w", ":w<CR>", opts)
map("n", "<leader>q", ":q<CR>", opts)
map("n", "<leader>x", ":x<CR>", opts)
