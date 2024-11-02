-- lua/plugins/configs/project.lua

-- Load and configure project_nvim with enhanced settings
require("project_nvim").setup {
  detection_methods = { "pattern", "lsp" }, -- Prioritize pattern matching for flexibility
  patterns = {
    ".git",                                 -- Detect Git projects
    "Makefile",                             -- Detect projects with Makefile
    "package.json",                         -- Detect JavaScript/Node projects
    "pyproject.toml",                       -- Detect Python projects
    "requirements.txt",                     -- Detect Python dependencies
    "Cargo.toml",                           -- Detect Rust projects
    "go.mod",                               -- Detect Go projects
    "composer.json",                        -- Detect PHP projects
    ".hg",                                  -- Detect Mercurial repositories
    ".svn",                                 -- Detect SVN repositories
  },
  ignore_lsp = { "null-ls" },               -- Ignore language servers that don’t define projects
  silent_chdir = false,                     -- Notify on directory change for awareness
  manual_mode = false,                      -- Automatic project switching for efficiency
}

-- Load Telescope extension for projects
require("telescope").load_extension("projects")

-- Optional: Map key for quick access to Telescope projects
vim.api.nvim_set_keymap(
  "n",
  "<leader>p", -- Press <leader> + p to quickly access projects
  ":Telescope projects<CR>",
  { noremap = true, silent = true }
)
