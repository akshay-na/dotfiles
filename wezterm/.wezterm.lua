local wezterm = require("wezterm")

-- Custom color schemes
local color_schemes = {
  ["Alabaster Dark"] = {
    background = "#0E1415",
    foreground = "#CECECE",
    cursor_bg = "#CECECE",
    cursor_fg = "#0E1415",
    selection_bg = "#2a2a2a",
    selection_fg = "#CECECE",

    -- Normal colors
    ansi = {
      "#0E1415", -- black
      "#e25d56", -- red
      "#73ca50", -- green
      "#e9bf57", -- yellow
      "#4a88e4", -- blue
      "#915caf", -- magenta
      "#23acdd", -- cyan
      "#f0f0f0", -- white
    },

    -- Bright colors
    brights = {
      "#777777", -- black
      "#f36868", -- red
      "#88db3f", -- green
      "#e9bf57", -- yellow
      "#6f8fdb", -- blue
      "#e987e9", -- magenta
      "#4ac9e2", -- cyan
      "#FFFFFF", -- white
    },
  },
}

return {
  -- Register custom color schemes
  color_schemes = color_schemes,

  -- Productivity & tmux-friendly keybindings
  keys = {
    -- Reload config
    {
      key = "r",
      mods = "CMD|SHIFT",
      action = wezterm.action.ReloadConfiguration,
    },
    -- Font size adjustments
    {
      key = "+",
      mods = "CMD",
      action = wezterm.action.IncreaseFontSize,
    },
    {
      key = "-",
      mods = "CMD",
      action = wezterm.action.DecreaseFontSize,
    },
    {
      key = "0",
      mods = "CMD",
      action = wezterm.action.ResetFontSize,
    },
    -- Fullscreen toggle
    {
      key = "f",
      mods = "CMD|SHIFT",
      action = wezterm.action.ToggleFullScreen,
    },
    -- Copy mode (tmux-style)
    {
      key = "[",
      mods = "CMD",
      action = wezterm.action.ActivateCopyMode,
    },
    -- Clear scrollback
    {
      key = "k",
      mods = "CMD|SHIFT",
      action = wezterm.action.ClearScrollback("ScrollbackOnly"),
    },
  },

  -- Font Settings
  font = wezterm.font_with_fallback({
    { family = "CaskaydiaCove Nerd Font", harfbuzz_features = { "calt=1", "clig=1", "liga=1" } },
    "JetBrainsMono Nerd Font",
    "FiraCode Nerd Font",
    "Hack Nerd Font",
    "Source Code Pro",
    "Consolas",
    "Monaco",
    "Menlo",
    "DejaVu Sans Mono",
    "Liberation Mono",
    "Ubuntu Mono",
    "Noto Color Emoji",
  }),

  font_size = 16,

  -- Appearance & Aesthetics
  color_scheme = "Alabaster Dark",
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true,
  -- window_decorations = "RESIZE",
  window_background_opacity = 0.95,
  window_padding = {
    left = 10,
    right = 10,
    top = 10,
    bottom = 10,
  },

  -- Performance optimizations
  animation_fps = 60,
  max_fps = 120,
  front_end = "WebGpu",
  enable_wayland = true,
  enable_kitty_graphics = true,
  tab_bar_at_bottom = true,
  use_fancy_tab_bar = true,
  tab_max_width = 25,
  show_tab_index_in_tab_bar = true,

  -- Scrollback
  scrollback_lines = 10000,

  window_close_confirmation = 'NeverPrompt',

  -- Cursor settings
  default_cursor_style = "BlinkingBar",
  cursor_thickness = 2,
}
