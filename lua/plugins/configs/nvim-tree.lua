-- lua/plugins/configs/nvim-tree.lua

-- Define a module table to hold the configuration
local M = {}

-- nvim-tree options
M.opts = {
  -- View settings
  view = {
    side = "right",       -- Position the tree on the right side
    adaptive_size = true, -- Automatically resize width based on content
    width = 30,           -- Set default width
  },

  update_focused_file = {
    enable = true,
    update_cwd = true,
  },

  git = {
    enable = true,
    ignore = false, -- Show .gitignored files for comprehensive view
  },

  -- Renderer settings
  renderer = {
    highlight_git = true,
    highlight_opened_files = "all", -- Highlight all opened files
    group_empty = true,             -- Group empty folders for cleaner view
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

  -- Diagnostics settings
  diagnostics = {
    enable = true,       -- Show diagnostics in the file tree
    show_on_dirs = true, -- Display diagnostics on directories too
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },

  -- Action settings
  actions = {
    open_file = {
      quit_on_open = true, -- Close nvim-tree when opening a file
      window_picker = {    -- Ensure picker prompts only on buffers
        enable = true,
        exclude = {
          filetype = { "packer", "qf" },
          buftype = { "terminal" },
        },
      },
    },
  },

  -- Sort by modification time for efficient access
  sort_by = "modification_time",
}

-- Return the module table
return M
