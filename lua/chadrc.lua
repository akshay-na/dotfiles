-- ~/.config/nvim/lua/chadrc.lua

---@type ChadrcConfig
local M = {}

M.plugins = require "custom.plugins"
M.mappings = require "custom.mappings"

-- Theme and highlight configuration
M.base46 = {
  theme = "onedark", -- You can set this to a preferred theme, like "gruvbox", "tokyonight", etc.

  -- Optional: Override highlights for productivity (e.g., italics for comments)
  hl_override = {
    Comment = { italic = true, fg = "#5C6370" },      -- Greyish tone for comments
    ["@comment"] = { italic = true, fg = "#5C6370" }, -- Italics for treesitter comments
  },
}

-- Add any additional configurations here to improve startup efficiency and --

return M
