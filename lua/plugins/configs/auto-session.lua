-- lua/plugins/configs/auto-session.lua

require("auto-session").setup {
  log_level = "info",
  auto_session_enable_last_session = true,
  auto_save_enabled = true,
  auto_restore_enabled = true,
}
