-- Import custom configurations for plugins
local nvim_tree = require "plugins.configs.nvim-tree"
local telescope = require "plugins.configs.telescope"

-- Plugin configurations
return {
  -- LSP and Autocompletion
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v1.x',
    dependencies = {
      { 'neovim/nvim-lspconfig' },             -- Required for LSP support
      { 'williamboman/mason.nvim' },           -- Mason for managing language servers
      { 'williamboman/mason-lspconfig.nvim' }, -- Integration with Mason
      { 'hrsh7th/nvim-cmp' },                  -- Autocompletion plugin
      { 'hrsh7th/cmp-nvim-lsp' },              -- LSP completion source for nvim-cmp
      { 'L3MON4D3/LuaSnip' },                  -- Snippet engine
    }
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
  },

  -- Bookmark Management
  {
    "ThePrimeagen/harpoon", -- Fast bookmarking tool
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Harpoon",
    config = function()
      require("harpoon").setup { menu = { width = vim.api.nvim_get_option("columns") * 0.5 } }
    end,
  },

  -- Project Management and Navigation
  {
    "ahmedkhalf/project.nvim", -- Project manager for Telescope
    dependencies = { "nvim-telescope/telescope.nvim" },
  },

  -- Autopairs and Tag Auto-closing
  {
    "windwp/nvim-autopairs", -- Auto-pair brackets
    event = "InsertEnter",
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
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter.configs").setup({
        rainbow = { enable = true, extended_mode = true },
      })
    end,
  },

  {
    "rcarriga/nvim-notify",
    config = function()
      vim.notify = require("notify")
    end,
  },

  {
    "ray-x/navigator.lua",
    dependencies = {
      "neovim/nvim-lspconfig",
      "ray-x/guihua.lua",
    },
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
  },

  -- Formatting and Linting
  {
    "jose-elias-alvarez/null-ls.nvim",
    event = "BufReadPre",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-treesitter/nvim-treesitter", event = "BufRead", run = ":TSUpdate" },
    },
  },

  -- Highlight TODO Comments
  {
    "folke/todo-comments.nvim", -- Highlight TODO comments
    event = "BufRead",
    dependencies = "nvim-lua/plenary.nvim",
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
  },
}
