return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true, -- load immediately
    priority = 1000, -- before everything else
    config = function()
      vim.cmd.colorscheme("catppuccin")
      require("config.highlights")
    end,
  },
  {
    "sainnhe/gruvbox-material",
    lazy = true,
    priority = 1000,
    config = function()
      vim.cmd("colorscheme gruvbox-material")
    end,
  },
  {
    "sainnhe/everforest",
    lazy = true,
    priority = 1000,
    config = function()
      -- Optionally configure and load the colorscheme
      -- directly inside the plugin declaration.
      vim.g.everforest_enable_italic = true
      vim.cmd.colorscheme("everforest")
      require("config.highlights")
    end,
  },
  {
    "nvimdev/zephyr-nvim",
    lazy = true, -- load immediately (colorschemes often need early load)
    config = function()
      -- set the colorscheme after plugin load
      vim.cmd.colorscheme("zephyr")
      require("config.highlights")
    end,
  },
  {
    "ptdewey/monalisa-nvim",
    priority = 1000,
  },
  {
    "nyngwang/nvimgelion",
    lazy = false,
    config = function()
      -- do whatever you want for further customization~
      vim.cmd("colorscheme nvimgelion")
    end,
  },
  {
    "zootedb0t/citruszest.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "xero/miasma.nvim",
    lazy = true,
    priority = 1000,
    config = function()
      vim.cmd("colorscheme miasma")
    end,
  }, -- Using lazy.nvim
  {
    "ribru17/bamboo.nvim",
    lazy = true,
    priority = 1000,
    config = function()
      require("bamboo").setup({
        -- optional configuration here
      })
      require("bamboo").load()
    end,
  },
  { "cryptomilk/nightcity.nvim", version = "*" },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    priority = 1000,
    config = function()
      vim.cmd("colorscheme gruvbox")
    end,
  },
}
