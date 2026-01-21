-- Save this as ~/.config/nvim/lua/project-manager.lua
-- Then add to your init.lua: require('project-manager').setup()

local M = {}

-- Project root markers (can be files or directories)
local root_markers = {
  ".git",
  "pom.xml",
  "go.mod",
  "Cargo.toml",
  "package.json",
  "pyproject.toml",
  "setup.py",
  "CMakeLists.txt",
  "Makefile",
  ".project",
  ".root",
  "composer.json",
  "build.gradle",
  "tsconfig.json",
}

-- Find project root by looking for markers
local function find_project_root(start_path)
  -- Handle empty path
  if not start_path or start_path == "" then
    start_path = vim.fn.getcwd()
  end

  -- Ensure we're working with a directory
  local stat = vim.loop.fs_stat(start_path)
  if stat and stat.type == "file" then
    start_path = vim.fn.fnamemodify(start_path, ":h")
  end

  local current = start_path

  -- Keep going up until we hit root
  while current and current ~= "/" and current ~= "" do
    for _, marker in ipairs(root_markers) do
      local marker_path = current .. "/" .. marker
      local marker_stat = vim.loop.fs_stat(marker_path)
      if marker_stat then
        -- Found a marker (file or directory)
        return current
      end
    end
    -- Go up one directory
    local parent = vim.fn.fnamemodify(current, ":h")
    if parent == current then
      break
    end -- Prevent infinite loop
    current = parent
  end

  return nil
end

-- Get all project directories recursively (with depth limit)
local function get_project_dirs(root, max_depth)
  if not root then
    return {}
  end
  max_depth = max_depth or 2 -- Default depth

  local dirs = {}

  -- Add root first
  table.insert(dirs, {
    path = root,
    display = "📁 . (root)",
    priority = 1,
  })

  -- Recursive function to scan directories
  local function scan_dir(dir, depth, prefix)
    if depth > max_depth then
      return
    end

    local handle = vim.loop.fs_scandir(dir)
    if not handle then
      return
    end

    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end

      -- Skip hidden directories (except root level .git if you want to see it)
      local should_skip = name:match("^%.")
        or name == "node_modules"
        or name == "target"
        or name == "build"
        or name == "dist"
        or name == "__pycache__"
        or name == ".venv"
        or name == "venv"

      if type == "directory" and not should_skip then
        local full_path = dir .. "/" .. name
        local display_prefix = prefix .. "  "
        local display_name = prefix .. "📂 " .. name

        table.insert(dirs, {
          path = full_path,
          display = display_name,
          priority = depth + 1,
        })

        -- Recurse into subdirectory
        scan_dir(full_path, depth + 1, display_prefix)
      end
    end
  end

  -- Start scanning from root
  scan_dir(root, 1, "")

  return dirs
end

-- Show project picker using vim.ui.select
local function show_project_picker()
  local current_file = vim.fn.expand("%:p")
  local current_dir = vim.fn.expand("%:p:h")

  -- If no file is open, use current working directory
  if current_file == "" then
    current_dir = vim.fn.getcwd()
  end

  local project_root = find_project_root(current_dir)

  if not project_root then
    vim.notify("❌ No project root found. Looking for: " .. table.concat(root_markers, ", "), vim.log.levels.WARN)
    return
  end

  vim.notify("📂 Project root: " .. project_root, vim.log.levels.INFO)

  local dirs = get_project_dirs(project_root)

  if #dirs == 0 then
    vim.notify("No directories found in project", vim.log.levels.WARN)
    return
  end

  vim.ui.select(dirs, {
    prompt = "Select Project Directory (" .. vim.fn.fnamemodify(project_root, ":t") .. "):",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if choice then
      -- Change to the selected directory
      vim.cmd("cd " .. vim.fn.fnameescape(choice.path))
      vim.notify(" Changed to: " .. choice.path, vim.log.levels.INFO)

      -- Open file explorer based on what's available
      -- Try nvim-tree first
      local has_nvim_tree = pcall(require, "nvim-tree")
      if has_nvim_tree then
        vim.cmd("NvimTreeOpen")
      else
        -- Try neo-tree
        local has_neo_tree = pcall(require, "neo-tree")
        if has_neo_tree then
          vim.cmd("Neotree")
        else
          -- Fallback to netrw (built-in)
          vim.cmd("Explore " .. vim.fn.fnameescape(choice.path))
        end
      end
    end
  end)
end

-- Enhanced version using Telescope (if available)
local function show_project_picker_telescope()
  local has_telescope, telescope = pcall(require, "telescope")

  if not has_telescope then
    show_project_picker()
    return
  end

  local current_file = vim.fn.expand("%:p")
  local current_dir = vim.fn.expand("%:p:h")

  if current_file == "" or current_dir == "" then
    current_dir = vim.fn.getcwd()
  end

  local project_root = find_project_root(current_dir)

  if not project_root then
    vim.notify("❌ No project root found. Looking for: " .. table.concat(root_markers, ", "), vim.log.levels.WARN)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local dirs = get_project_dirs(project_root)

  pickers
    .new({}, {
      prompt_title = "📂 Project Directories - " .. vim.fn.fnamemodify(project_root, ":t"),
      finder = finders.new_table({
        results = dirs,
        entry_maker = function(entry)
          return {
            value = entry.path,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          vim.cmd("cd " .. vim.fn.fnameescape(selection.value))
          vim.notify(" Changed to: " .. selection.value, vim.log.levels.INFO)

          -- Open file explorer based on what's available
          vim.schedule(function()
            local has_nvim_tree = pcall(require, "nvim-tree")
            if has_nvim_tree then
              vim.cmd("NvimTreeOpen")
            else
              local has_neo_tree = pcall(require, "neo-tree")
              if has_neo_tree then
                vim.cmd("Neotree")
              else
                -- Fallback to Telescope file browser or netrw
                local has_fb = pcall(require, "telescope._extensions.file_browser")
                if has_fb then
                  vim.cmd("Telescope file_browser path=" .. vim.fn.fnameescape(selection.value))
                else
                  vim.cmd("Explore " .. vim.fn.fnameescape(selection.value))
                end
              end
            end
          end)
        end)
        return true
      end,
    })
    :find()
end

-- Dashboard integration for alpha-nvim
local function setup_alpha_dashboard(keymap)
  local has_alpha, alpha = pcall(require, "alpha")
  if not has_alpha then
    return false
  end

  local dashboard = require("alpha.themes.dashboard")

  -- Add project picker button
  local project_button = dashboard.button(keymap, "📂  Project Directories", ":ProjectDirs<CR>")

  -- Try to insert after common buttons
  local config = alpha.config or {}
  local layout = config.layout or {}

  for i, section in ipairs(layout) do
    if section.val and type(section.val) == "table" then
      for j, button in ipairs(section.val) do
        -- Insert after "Find file" or similar
        if button.val and (button.val:match("Find") or button.val:match("Recent")) then
          table.insert(section.val, j + 1, project_button)
          return true
        end
      end
    end
  end

  return false
end

-- Dashboard integration for dashboard-nvim
local function setup_dashboard_nvim(keymap)
  local has_dashboard, db = pcall(require, "dashboard")
  if not has_dashboard then
    return false
  end

  -- This depends on your dashboard-nvim config
  -- Add to your dashboard config in init.lua instead
  return true
end

-- Setup function
function M.setup(opts)
  opts = opts or {}

  -- Allow custom root markers
  if opts.root_markers then
    root_markers = opts.root_markers
  end

  -- Decide which picker to use
  local picker = show_project_picker
  if opts.use_telescope ~= false then
    picker = show_project_picker_telescope
  end

  -- Create user command
  vim.api.nvim_create_user_command("ProjectDirs", picker, {})

  -- Create keymap
  local keymap = opts.keymap or "p"
  vim.keymap.set("n", keymap, picker, {
    desc = "Show project directories",
    silent = true,
  })

  -- Debug command to show current project root
  vim.api.nvim_create_user_command("ProjectRoot", function()
    local current_dir = vim.fn.expand("%:p:h")
    if current_dir == "" then
      current_dir = vim.fn.getcwd()
    end
    local root = find_project_root(current_dir)
    if root then
      vim.notify("📂 Project root: " .. root, vim.log.levels.INFO)
    else
      vim.notify(" No project root found", vim.log.levels.WARN)
    end
  end, {})

  -- Setup dashboard integration if enabled
  if opts.dashboard ~= false then
    vim.defer_fn(function()
      setup_alpha_dashboard(keymap)
    end, 100)
  end
end

-- Export for manual use
M.show_picker = show_project_picker_telescope
M.find_root = find_project_root
M.get_dirs = get_project_dirs

return M
