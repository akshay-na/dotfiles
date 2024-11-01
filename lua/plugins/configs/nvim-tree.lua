-- lua/plugins/configs/nvim-tree.lua

-- Define a module table to hold the configuration
local M = {}

-- nvim-tree options
M.opts = {
  -- View settings
  view = {
    side = "right", -- Position the tree on the right side
    width = 30,     -- Set tree width
  },

  update_focused_file = {
    enable = true,
    update_cwd = true,
  },

  git = {
    enable = true,
    ignore = true, -- Set this to true if you don’t want to track .gitignored files
  },

  -- Renderer settings
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      },
      glyphs = {
        default = "", -- Use Material style default icon
        symlink = "",
        git = {
          unstaged = "",
          staged = "S",
          unmerged = "",
          renamed = "➜",
          untracked = "U",
          deleted = "",
          ignored = "◌",
        },
        folder = {
          default = "",
          open = "",
          empty = "",
          empty_open = "",
          symlink = "",
        },
      },
    },
  },

  -- Action settings
  actions = {
    open_file = {
      quit_on_open = false, -- Close nvim-tree when opening a file
    },
  },
}

-- Return the module table
return M
