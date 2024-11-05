-- ~/.config/nvim/lua/chadrc.lua

---@class ChadrcConfig
local M = {}

local status, plugins = pcall(require, "plugins")
if status then
  M.plugins = plugins
else
  error("Plugins Configuration not found")
end

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

local status, plugin_configs = pcall(require, "plugins.configs")
if not status then
  error("Plugins Configuration not found")
end

local status, mappings = pcall(require, "mappings")
if status then
  M.mappings = mappings
else
  error("Custom Mapping not found")
end

-- Add any additional configurations here to improve startup efficiency and --

pcall(require, "options")
pcall(require, "configs.autocmds")
pcall(require, "configs.clipboard")

return M
