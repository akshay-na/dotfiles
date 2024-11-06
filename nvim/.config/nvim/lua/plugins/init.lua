-- Plugin configurations
return {
  -- LSP and Autocompletion
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v1.x',
    dependencies = {
      { 'neovim/nvim-lspconfig' },                                   -- Core LSP support
      { 'williamboman/mason.nvim',          cmd = "Mason" },         -- Lazy load Mason on command
      { 'williamboman/mason-lspconfig.nvim' },                       -- Mason integration for LSP
      { 'hrsh7th/nvim-cmp',                 event = "InsertEnter" }, -- Autocomplete in insert mode
      { 'hrsh7th/cmp-nvim-lsp' },                                    -- LSP source for autocompletion
      { 'L3MON4D3/LuaSnip',                 event = "InsertEnter" }, -- Snippet support in insert mode
    }
  },

  -- Git Commands (Lazy load on Git commands)
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gstatus", "Gcommit" },
  },

  -- Github Copilot
  {
    'github/copilot.vim',
    lazy = true, -- Loads plugin only when needed
    config = function()
      -- Recommended: Set keymaps for GitHub Copilot
      vim.g.copilot_no_tab_map = true -- Disable automatic Tab mapping
      vim.api.nvim_set_keymap("i", "<C-l>", 'copilot#Accept("<CR>")', { silent = true, expr = true })

      -- Set Copilot suggestion display mode and other options
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_filetypes = {
        ["*"] = true, -- Enable Copilot for all file types
      }
    end,
  },

  -- Telescope (Load only on command)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    opts = require "plugins.configs.telescope".opts,
  },

  -- Colorizer for highlighting color codes (Lazy load on BufRead for certain file types)
  {
    "norcalli/nvim-colorizer.lua",
    ft = { "css", "html", "javascript" },
    config = function()
      require("colorizer").setup()
    end
  },

  -- Symbols Outline (Lazy load for structured code outline on command)
  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    config = function()
      require("symbols-outline").setup()
    end
  },

  -- Trouble (Load only on command for diagnostics)
  {
    "folke/trouble.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("trouble").setup()
    end
  },

  -- File Explorer and File Management (Keep nvim-tree as is)
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "kyazdani42/nvim-web-devicons" },
    opts = (require "plugins.configs.nvim-tree").opts,
  },

  -- Debugging Console Logs (Lazy load on LSP attach)
  {
    "andrewferrier/debugprint.nvim",
    event = "LspAttach",
    config = function()
      require("debugprint").setup()
    end,
  },

  -- Text Surround (Lazy load on buffer read)
  {
    "kylechui/nvim-surround",
    event = "BufReadPre",
    config = true,
  },

  -- Session Management (Auto-session with lazy load)
  {
    "rmagatti/auto-session",
    event = "VimEnter",
  },

  -- Bookmark Management (Lazy load on command)
  {
    "ThePrimeagen/harpoon",
    cmd = "Harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon").setup { menu = { width = vim.api.nvim_get_option("columns") * 0.5 } }
    end,
  },

  -- Project Management (Lazy load with Telescope)
  {
    "ahmedkhalf/project.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    event = "BufReadPre",
  },

  -- Autopairs and Tag Auto-closing (Lazy load on InsertEnter)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
  },
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    after = "nvim-treesitter.nvim",
    config = true,
  },

  {
    "ianding1/leetcode.vim",
    cmd = { "LeetCode", "LeetCodeTest" },
    config = function()
      -- Set the default browser to use for LeetCode
      vim.g.leetcode_browser = 'chrome'               -- use 'firefox' if preferred
      vim.g.leetcode_solution_filetype = 'Typescript' -- change to your preferred language
      -- Uncomment this line if using the LeetCode China site
      -- vim.g.leetcode_china = 1
    end
  },

  -- Multi-Cursor Editing (Lazy load on key press)
  {
    "mg979/vim-visual-multi",
    branch = "master",
    keys = { "<C-n>", "<C-p>" },
  },

  -- Performance Optimization
  {
    "lewis6991/impatient.nvim",
    config = function()
      require("impatient").enable_profile()
    end,
  },

  -- Text Alignment (Lazy load on EasyAlign command)
  {
    "junegunn/vim-easy-align",
    cmd = "EasyAlign",
  },

  -- Code Commenting (Lazy load on commenting keys)
  {
    "numToStr/Comment.nvim",
    keys = { "gc", "gcc", "gbc" },
    config = true,
  },

  -- Parentheses Highlighting and Treesitter Config (Lazy load on buffer read)
  {
    "p00f/nvim-ts-rainbow",
    event = "BufRead",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter.configs").setup({
        rainbow = { enable = true, extended_mode = true },
      })
    end,
  },

  -- Notification System (Lazy load on first use)
  {
    "rcarriga/nvim-notify",
    config = function()
      vim.notify = require("notify")
    end,
    event = "VimEnter",
  },

  -- Navigator for enhanced LSP features (Lazy load on LSP attach)
  {
    "ray-x/navigator.lua",
    dependencies = { "neovim/nvim-lspconfig", "ray-x/guihua.lua" },
    event = "LspAttach",
  },

  -- Git Integration (Lazy load on buffer read)
  {
    "lewis6991/gitsigns.nvim",
    event = "BufRead",
    config = true,
  },

  -- Markdown Preview (Lazy load on Markdown filetype)
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    run = "cd app && yarn install",
    cmd = "MarkdownPreview",
  },

  -- Formatting and Linting (Lazy load on buffer read)
  {
    "jose-elias-alvarez/null-ls.nvim",
    event = "BufReadPre",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-treesitter/nvim-treesitter", event = "BufRead", run = ":TSUpdate" },
    },
  },

  -- Highlight TODO Comments (Lazy load on buffer read)
  {
    "folke/todo-comments.nvim",
    event = "BufRead",
    dependencies = "nvim-lua/plenary.nvim",
    config = true,
  },

  -- Key Binding Help (Eager load for quick access)
  {
    "folke/which-key.nvim",
    lazy = false,
  },

  -- Whitespace Management (Lazy load on buffer read)
  {
    "ntpeters/vim-better-whitespace",
    event = "BufRead",
  },
}
