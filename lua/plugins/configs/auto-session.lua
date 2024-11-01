-- File: ~/.config/nvim/lua/plugins/configs/auto-session.lua

-- Set session options
vim.o.sessionoptions = "buffers,curdir,help,tabpages,winsize,localoptions"

require("auto-session").setup {
  log_level = "info",
  auto_session_enable_last_session = true,
  auto_save_enabled = true,
  auto_restore_enabled = true,
  auto_session_suppress_dirs = { "~/" }, -- Suppress sessions in the home directory
  auto_session_use_git_branch = true,    -- Separate sessions by git branch

  -- Hooks for session management
  pre_save_cmds = { "NvimTreeClose" }, -- Close nvim-tree before saving session

  -- Automatically clean up outdated sessions
  auto_session_create_enabled = true,                             -- Automatically create sessions for each directory
  auto_session_allowed_dirs = { "~/projects" },                   -- Only save sessions in specific directories
  auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/", -- Set custom directory for sessions

  -- Optional: Automatically delete old sessions after a number of days
  session_lens = {
    theme_conf = { border = true },
    previewer = false,
  },
}
