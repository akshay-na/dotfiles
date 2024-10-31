-- File: ~/.config/nvim/lua/plugins/configs/init.lua

-- Get the current directory path
local config_path = vim.fn.stdpath("config") .. "/lua/plugins/configs"

-- Load all Lua files in the `plugins/configs` directory
local files = vim.fn.globpath(config_path, "*.lua", false, true)

for _, file in ipairs(files) do
  -- Extract filename without the extension
  local module_name = file:match("([^/]+)%.lua$")
  if module_name ~= "init" then -- Skip the init.lua itself
    require("plugins.configs." .. module_name)
  end
end
