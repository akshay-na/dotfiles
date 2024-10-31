-- Import custom configurations for plugins
local nvim_tree = require "plugins.configs.nvim-tree"
local telescope = require "plugins.configs.telescope"

-- Plugin configurations
return {

  -- Core Language Server Protocol (LSP) setup
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig" -- Load custom LSP configuration
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "Telescope",
    opts = telescope.opts,
  },

  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end
  },

  -- Material Icon Theme
  {
    "nvim-tree/nvim-web-devicons",
    cmd = { "NvimTreeToggle", "NvimTreeOpen" },
  },

  {
    "simrat39/symbols-outline.nvim",
    config = function()
      require("symbols-outline").setup()
    end
  },

  {
    "folke/trouble.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("trouble").setup()
    end
  },
  -- File Explorer and File Management
  {
    "nvim-tree/nvim-tree.lua",                         -- File explorer
    dependencies = { "kyazdani42/nvim-web-devicons" }, -- Icon support
    opts = nvim_tree.opts,
  },

  -- LSP-related plugins
  {
    "williamboman/mason.nvim", -- LSP server manager
  },
  {
    "williamboman/mason-lspconfig.nvim", -- Mason and LSP integration
    after = "mason.nvim",
  },

  -- Debugging and Console Log
  {
    "andrewferrier/debugprint.nvim", -- Quick console log tool
    event = "LspAttach",
    config = function()
      require("debugprint").setup({ create_keymaps = true })
    end,
  },

  -- Surround and Bracket Handling
  {
    "kylechui/nvim-surround", -- Surround text with custom characters
    event = "BufReadPre",
    config = true,
  },

  -- Session Management
  {
    "rmagatti/auto-session", -- Auto-session management
    config = function()
      require("auto-session").setup {
        log_level = "info",
        auto_session_enable_last_session = true,
        auto_save_enabled = true,
        auto_restore_enabled = true,
      }
    end,
  },

  -- Bookmark Management
  {
    "ThePrimeagen/harpoon", -- Fast bookmarking tool
    requires = { "nvim-lua/plenary.nvim" },
    cmd = "Harpoon",
    config = function()
      require("harpoon").setup { menu = { width = vim.api.nvim_get_option("columns") * 0.5 } }
    end,
  },

  -- Project Management and Navigation
  {
    "ahmedkhalf/project.nvim", -- Project manager for Telescope
    config = function()
      require("project_nvim").setup {
        detection_methods = { "lsp", "pattern" },
        patterns = { ".git", "Makefile", "package.json" },
      }
      require("telescope").load_extension("projects")
    end,
  },

  -- Autopairs and Tag Auto-closing
  {
    "windwp/nvim-autopairs", -- Auto-pair brackets
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
  {
    "windwp/nvim-ts-autotag", -- Auto-close HTML/JSX tags
    event = "InsertEnter",
    after = "nvim-treesitter.nvim",
    config = true,
  },

  -- Multi-Cursor Editing
  {
    "mg979/vim-visual-multi",    -- Multi-cursor support
    branch = "master",
    keys = { "<C-n>", "<C-p>" }, -- Optional key bindings
  },

  -- Performance Optimization
  {
    "lewis6991/impatient.nvim", -- Speed up plugin loading
    config = function()
      require("impatient").enable_profile()
    end,
  },

  -- Enhanced Error Display
  {
    "chikko80/error-lens.nvim", -- Enhanced error highlighting
    mazy = false,
    config = function()
      require("error-lens").setup({ auto_enable = true, hl_priority = 100 })
    end,
  },

  -- Text Alignment
  {
    "junegunn/vim-easy-align", -- Align text easily
    cmd = "EasyAlign",
    config = function()
      vim.keymap.set("n", "ga", "<Plug>(EasyAlign)", { desc = "Align text" })
      vim.keymap.set("x", "ga", "<Plug>(EasyAlign)", { desc = "Align text in visual mode" })
    end,
  },

  -- Code Commenting
  {
    "numToStr/Comment.nvim", -- Comment out code blocks
    keys = { "gc", "gcc", "gbc" },
    config = true,
  },

  -- Parentheses Highlighting and Treesitter Config
  {
    "p00f/nvim-ts-rainbow", -- Rainbow parentheses
    event = "BufRead",
    requires = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter.configs").setup({
        rainbow = { enable = true, extended_mode = true },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter", -- Treesitter configurations
  },

  {
    "rcarriga/nvim-notify",
    config = function()
      vim.notify = require("notify")
    end,
  },

  { "ray-x/guihua.lua" },

  {
    "ray-x/navigator.lua",
    dependencies = {
      "neovim/nvim-lspconfig",
      "ray-x/guihua.lua", -- required GUI components for navigator.nvim
    },
    config = function()
      require("navigator").setup({
        lsp = {
          disable_lsp = "all", -- Disable built-in LSP to let Navigator handle it
        },
      })
    end,
  },

  -- Git Integration
  {
    "lewis6991/gitsigns.nvim", -- Git signs in gutter
    event = "BufRead",
    config = true,
  },

  -- Markdown Preview
  {
    "iamcco/markdown-preview.nvim", -- Preview markdown files
    ft = { "markdown" },
    run = "cd app && yarn install",
    cmd = "MarkdownPreview",
    config = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_refresh_slow = 1
    end,
  },

  -- Formatting and Linting
  {
    "jose-elias-alvarez/null-ls.nvim", -- Interface for formatters/linters
    event = "BufReadPre",
    requires = {
      "nvim-lua/plenary.nvim",
      { "nvim-treesitter/nvim-treesitter", event = "BufRead", run = ":TSUpdate" }
    },
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.prettier.with({
            extra_args = { "--config-precedence", "prefer-file" },
          }),
        },
      })
    end,
  },

  -- Highlight TODO Comments
  {
    "folke/todo-comments.nvim", -- Highlight TODO comments
    event = "BufRead",
    requires = "nvim-lua/plenary.nvim",
    config = true,
  },

  {
    "folke/which-key.nvim",
    lazy = false, -- Ensure lazy loading is disabled
  },

  -- Whitespace Management
  {
    "ntpeters/vim-better-whitespace", -- Highlight and remove trailing spaces
    event = "BufRead",
    config = function()
      vim.g.better_whitespace_enabled = 1
      vim.g.strip_whitespace_on_save = 1
    end,
  },
}
