-- File: ~/.config/nvim/lua/plugins/configs/error-lens.lua

-- Import and configure error-lens with performance-focused settings
require("error-lens").setup({
  auto_enable = true,                            -- Automatically enable error-lens on start
  hl_priority = 100,                             -- Set highlight priority
  severity_level = vim.diagnostic.severity.WARN, -- Show only warnings and above by default
  status_text = {
    enabled = false,                             -- Disable status text to reduce clutter
    signs = false,                               -- Use signs instead of inline status text
  },
  -- Customize colors for different diagnostic levels
  colors = {
    error_fg = "#FF5C57",
    warn_fg = "#FFB86C",
    info_fg = "#8BE9FD",
    hint_fg = "#50FA7B",
  },
})
