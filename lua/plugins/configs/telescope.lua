-- lua/plugins/configs/telescope.lua

-- Define a module table to hold the configuration
local M = {}

-- Telescope options
M.opts = {
  defaults = {
    -- Specify patterns to ignore during search
    file_ignore_patterns = {
      "node_modules", -- Ignore node_modules for JavaScript/TypeScript
      "%.git/",       -- Ignore .git folder
      "venv/",        -- Ignore Python virtual environments
      "target/",      -- Ignore Rust target folder
      "build/",       -- Ignore build folders
      "dist/",        -- Ignore distribution folders
      "out/",         -- Ignore output folders
      "__pycache__/", -- Ignore Python cache
      "%.lock",       -- Ignore lock files like yarn.lock
    },
  },
}

-- Setup function to configure Telescope with the defined options
M.setup = function()
  require("telescope").setup(M.opts)
end

-- Return the module table
return M
