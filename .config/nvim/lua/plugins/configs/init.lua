-- File: ~/.config/nvim/lua/plugins/configs/init.lua

local config_dir = vim.fn.stdpath("config") .. "/lua/plugins/configs"

-- Helper function to safely require modules
local function safe_require(module)
  local ok, err = pcall(require, module)
  if not ok then
    vim.notify("Error loading module: " .. module .. "\n\n" .. err, vim.log.levels.ERROR)
  end
end

-- Read all Lua files in the specified config directory
local function load_configs()
  local handle = vim.loop.fs_scandir(config_dir)
  if not handle then return end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end

    if type == "file" and name:match("%.lua$") then
      -- Remove the `.lua` extension and replace `/` with `.`
      local module_name = "plugins.configs." .. name:gsub("%.lua$", "")
      if module_name ~= "plugins.configs.init" then -- Skip the init.lua itself
        safe_require(module_name)
      end
    end
  end
end

-- Execute the loading function
load_configs()

return {}
