-- ~/.config/nvim/lua/config/clipboard.lua

-- Check if running in WSL and configure clipboard accordingly
if vim.fn.has("wsl") == 1 then
  -- WSL Clipboard configuration for cross-platform support
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
    paste = {
      ["+"] = "pwsh.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace('`r', ''))",
      ["*"] = "pwsh.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace('`r', ''))",
    },
    cache_enabled = 0,
  }
else
  -- Default clipboard configuration for non-WSL systems
  vim.opt.clipboard = "unnamedplus" -- Use system clipboard
end
