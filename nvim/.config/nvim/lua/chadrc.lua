-- ~/.config/nvim/lua/chadrc.lua

---@class ChadrcConfig
local M = {}

M.plugins = pcall(require, "plugins")
pcall(require, "plugins.configs")

M.ui = {
  statusline = {
    theme = "vscode_colored",
    separator_style = "arrow", -- Choose from "round", "block", "arrow"
  },
}

-- Theme and highlight configuration
M.base46 = {
  theme = "onedark", -- You can set this to a preferred theme, like "gruvbox", "tokyonight", etc.

  -- Optional: Override highlights for productivity (e.g., italics for comments)
  hl_override = {
    Comment = { italic = true, fg = "#5C6370" },      -- Greyish tone for comments
    ["@comment"] = { italic = true, fg = "#5C6370" }, -- Italics for treesitter comments
  },
}

M.mappings = pcall(require, "mappings")

-- Add any additional configurations here to improve startup efficiency and --

pcall(require, "options")
pcall(require, "configs.autocmds")
pcall(require, "configs.clipboard")

return M
