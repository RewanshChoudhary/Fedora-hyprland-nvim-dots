-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- In your init.lua
require("project-manager").setup({
  keymap = "p",
  use_telescope = true,
  on_select = function(path)
    -- Custom action when selecting a directory
    vim.cmd("cd " .. path)
    vim.cmd("NvimTreeOpen") -- Or whatever you prefer
  end,
})
