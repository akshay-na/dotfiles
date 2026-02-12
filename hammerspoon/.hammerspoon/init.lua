-- ============================================================================
-- Hammerspoon Configuration for Maximum Developer Productivity
-- ============================================================================
-- This configuration provides powerful window management, clipboard history,
-- app launching, and automation features to boost your productivity 10x.

-- Disable animations for instant window operations
hs.window.animationDuration = 0

-- Enable Spotlight for application name searches
hs.application.enableSpotlightForNameSearches(true)

-- ============================================================================
-- CONFIGURATION VARIABLES
-- ============================================================================

-- Modifier keys: Use hyper key (cmd+alt+ctrl+shift) for most shortcuts
local hyper = {"cmd", "alt", "ctrl", "shift"}
local super = {"cmd", "alt", "ctrl"}
local altCtrl = {"alt", "ctrl"}

-- Grid configuration for window snapping
hs.grid.setGrid('8x4')  -- 8 columns, 4 rows
hs.grid.setMargins({0, 0})

-- ============================================================================
-- WINDOW MANAGEMENT - Grid-based Window Snapping
-- ============================================================================

-- Show grid overlay for manual window positioning
hs.hotkey.bind(hyper, 'g', function()
  hs.grid.show()
end)

-- Quick window snapping to halves
hs.hotkey.bind(super, 'Left', function()
  local win = hs.window.focusedWindow()
  if win then
    local screen = win:screen()
    local max = screen:frame()
    win:setFrame({x = max.x, y = max.y, w = max.w / 2, h = max.h})
  end
end)

hs.hotkey.bind(super, 'Right', function()
  local win = hs.window.focusedWindow()
  if win then
    local screen = win:screen()
    local max = screen:frame()
    win:setFrame({x = max.x + max.w / 2, y = max.y, w = max.w / 2, h = max.h})
  end
end)

hs.hotkey.bind(super, 'Up', function()
  local win = hs.window.focusedWindow()
  if win then
    local screen = win:screen()
    local max = screen:frame()
    win:setFrame({x = max.x, y = max.y, w = max.w, h = max.h / 2})
  end
end)

hs.hotkey.bind(super, 'Down', function()
  local win = hs.window.focusedWindow()
  if win then
    local screen = win:screen()
    local max = screen:frame()
    win:setFrame({x = max.x, y = max.y + max.h / 2, w = max.w, h = max.h / 2})
  end
end)

-- Maximize window
hs.hotkey.bind(super, 'm', function()
  local win = hs.window.focusedWindow()
  if win then
    win:maximize()
  end
end)

-- Center window
hs.hotkey.bind(super, 'c', function()
  local win = hs.window.focusedWindow()
  if win then
    local screen = win:screen()
    local max = screen:frame()
    local f = win:frame()
    win:setFrame({
      x = max.x + (max.w - f.w) / 2,
      y = max.y + (max.h - f.h) / 2,
      w = f.w,
      h = f.h
    })
  end
end)

-- Grid-based window positioning (using numpad-style keys)
-- Top-left quarter
hs.hotkey.bind(super, '7', function()
  local win = hs.window.focusedWindow()
  if win then hs.grid.set(win, '0,0 4x2', win:screen()) end
end)

-- Top-right quarter
hs.hotkey.bind(super, '9', function()
  local win = hs.window.focusedWindow()
  if win then hs.grid.set(win, '4,0 4x2', win:screen()) end
end)

-- Bottom-left quarter
hs.hotkey.bind(super, '1', function()
  local win = hs.window.focusedWindow()
  if win then hs.grid.set(win, '0,2 4x2', win:screen()) end
end)

-- Bottom-right quarter
hs.hotkey.bind(super, '3', function()
  local win = hs.window.focusedWindow()
  if win then hs.grid.set(win, '4,2 4x2', win:screen()) end
end)

-- Left half
hs.hotkey.bind(super, '4', function()
  local win = hs.window.focusedWindow()
  if win then hs.grid.set(win, '0,0 4x4', win:screen()) end
end)

-- Right half
hs.hotkey.bind(super, '6', function()
  local win = hs.window.focusedWindow()
  if win then hs.grid.set(win, '4,0 4x4', win:screen()) end
end)

-- Top half
hs.hotkey.bind(super, '8', function()
  local win = hs.window.focusedWindow()
  if win then hs.grid.set(win, '0,0 8x2', win:screen()) end
end)

-- Bottom half
hs.hotkey.bind(super, '2', function()
  local win = hs.window.focusedWindow()
  if win then hs.grid.set(win, '0,2 8x2', win:screen()) end
end)

-- Full screen
hs.hotkey.bind(super, '5', function()
  local win = hs.window.focusedWindow()
  if win then hs.grid.set(win, '0,0 8x4', win:screen()) end
end)

-- Move window to next screen
hs.hotkey.bind(super, 'n', function()
  local win = hs.window.focusedWindow()
  if win then
    local screen = win:screen()
    local nextScreen = screen:next()
    win:moveToScreen(nextScreen)
  end
end)

-- ============================================================================
-- WINDOW MOVEMENT - Fine-grained control with arrow keys
-- ============================================================================

local function moveWindow(dx, dy)
  local win = hs.window.focusedWindow()
  if win then
    local f = win:frame()
    f.x = f.x + dx
    f.y = f.y + dy
    win:setFrame(f)
  end
end

local function resizeWindow(dw, dh)
  local win = hs.window.focusedWindow()
  if win then
    local f = win:frame()
    f.w = f.w + dw
    f.h = f.h + dh
    win:setFrame(f)
  end
end

-- Arrow keys for window movement (hold shift for fine movement)
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Left", function() moveWindow(-20, 0) end)
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Right", function() moveWindow(20, 0) end)
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Up", function() moveWindow(0, -20) end)
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Down", function() moveWindow(0, 20) end)

-- Shift + Arrow for fine movement
hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "Left", function() moveWindow(-5, 0) end)
hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "Right", function() moveWindow(5, 0) end)
hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "Up", function() moveWindow(0, -5) end)
hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "Down", function() moveWindow(0, 5) end)

-- ============================================================================
-- APP LAUNCHER - Quick app switching and launching with fallbacks
-- ============================================================================

local function launchAppWithFallback(apps)
  for _, app in ipairs(apps) do
    -- Try to launch/focus the app (will launch if not running)
    local success, err = pcall(function()
      hs.application.launchOrFocus(app)
    end)
    if success then
      return true
    end
  end
  return false
end

-- Cursor (or VS Code as fallback)
hs.hotkey.bind(altCtrl, 'c', function()
  launchAppWithFallback({"Cursor", "Visual Studio Code"})
end)

-- Chrome
hs.hotkey.bind(altCtrl, 'g', function()
  hs.application.launchOrFocus("Google Chrome")
end)

-- Terminal (Alacritty or Terminal as fallback)
hs.hotkey.bind(altCtrl, 't', function()
  launchAppWithFallback({"Alacritty", "Terminal", "iTerm2"})
end)

-- Gmail (Chrome app/site or Mac Mail as fallback)
hs.hotkey.bind(altCtrl, 'e', function()
  launchAppWithFallback({"Gmail", "Mail"})
end)

-- Calendar (Chrome app/site or Mac Calendar as fallback)
hs.hotkey.bind(altCtrl, 'l', function()
  launchAppWithFallback({"Google Calendar", "Calendar"})
end)

-- Obsidian (or Chrome app/site or Mac Notes as fallback)
hs.hotkey.bind(altCtrl, 'o', function()
  launchAppWithFallback({"Obsidian", "Google Keep", "Notes"})
end)

-- Finder
hs.hotkey.bind(altCtrl, 'f', function()
  launchAppWithFallback({"Finder"})
end)

-- ChatGPT
hs.hotkey.bind(altCtrl, 'h', function()
  launchAppWithFallback({"Atlas", "ChatGPT"})
  if not success then
    hs.urlevent.openURL("https://chatgpt.com")
  end
end)

-- ============================================================================
-- WINDOW SWITCHER - Cycle through windows of current app
-- ============================================================================

local function cycleWindows()
  local win = hs.window.focusedWindow()
  if not win then return end

  local app = win:application()
  local windows = app:allWindows()
  local visibleWindows = {}

  for _, w in ipairs(windows) do
    if w:isStandard() and w:isVisible() then
      table.insert(visibleWindows, w)
    end
  end

  if #visibleWindows <= 1 then return end

  local currentIndex = 1
  for i, w in ipairs(visibleWindows) do
    if w == win then
      currentIndex = i
      break
    end
  end

  local nextIndex = (currentIndex % #visibleWindows) + 1
  visibleWindows[nextIndex]:focus()
end

hs.hotkey.bind(altCtrl, '`', cycleWindows)

-- ============================================================================
-- FOCUS MANAGEMENT - Focus windows on current screen
-- ============================================================================

local function focusWindow(direction)
  local win = hs.window.focusedWindow()
  if not win then return end

  local screen = win:screen()
  local windows = hs.window.filter.new():setCurrentSpace(true):getWindows()

  local currentPos = win:frame()
  local candidates = {}

  for _, w in ipairs(windows) do
    if w ~= win and w:screen() == screen and w:isStandard() then
      local pos = w:frame()
      local dx, dy = pos.x - currentPos.x, pos.y - currentPos.y

      if direction == "left" and dx < 0 then
        table.insert(candidates, {win = w, dist = math.abs(dx) + math.abs(dy)})
      elseif direction == "right" and dx > 0 then
        table.insert(candidates, {win = w, dist = math.abs(dx) + math.abs(dy)})
      elseif direction == "up" and dy < 0 then
        table.insert(candidates, {win = w, dist = math.abs(dx) + math.abs(dy)})
      elseif direction == "down" and dy > 0 then
        table.insert(candidates, {win = w, dist = math.abs(dx) + math.abs(dy)})
      end
    end
  end

  if #candidates > 0 then
    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    candidates[1].win:focus()
  end
end

hs.hotkey.bind(hyper, 'Left', function() focusWindow("left") end)
hs.hotkey.bind(hyper, 'Right', function() focusWindow("right") end)
hs.hotkey.bind(hyper, 'Up', function() focusWindow("up") end)
hs.hotkey.bind(hyper, 'Down', function() focusWindow("down") end)

-- ============================================================================
-- SCREEN MANAGEMENT - Multi-monitor support
-- ============================================================================

local function reconfigureGrid()
  local screens = hs.screen.allScreens()
  for _, screen in ipairs(screens) do
    hs.grid.setGrid('8x4', screen)
  end
end

-- Reconfigure grid when screens change
local screenWatcher = hs.screen.watcher.new(reconfigureGrid)
screenWatcher:start()
reconfigureGrid()

-- ============================================================================
-- PASTE BLOCKING DEFEATER - Force paste anywhere
-- ============================================================================

hs.hotkey.bind({"cmd", "alt"}, "V", function()
  hs.eventtap.keyStrokes(hs.pasteboard.getContents())
end)

-- ============================================================================
-- CONFIG RELOAD - Auto-reload on file changes
-- ============================================================================

function reloadConfig(files)
  doReload = false
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end

local configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig)
configWatcher:start()

-- Manual reload hotkeys
hs.hotkey.bind(hyper, 'r', function()
  hs.reload()
end)
-- Simpler reload hotkey (⌥⌃R)
hs.hotkey.bind(altCtrl, 'r', function()
  hs.reload()
end)

-- ============================================================================
-- CAFFEINE - Prevent display sleep
-- ============================================================================

local caffeine = hs.menubar.new()

local function setCaffeineDisplay(state)
  if state then
    caffeine:setTitle("☕")
  else
    caffeine:setTitle("😴")
  end
end

local function caffeineClicked()
  setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

if caffeine then
  caffeine:setClickCallback(caffeineClicked)
  setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end

-- Toggle caffeine with hotkey
hs.hotkey.bind(hyper, 's', function()
  hs.caffeinate.toggle("displayIdle")
  setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end)

-- ============================================================================
-- LOCK SCREEN - Quick lock
-- ============================================================================

hs.hotkey.bind(hyper, 'l', function()
  hs.caffeinate.lockScreen()
end)


-- ============================================================================
-- SYSTEM INFORMATION - Show system stats
-- ============================================================================

hs.hotkey.bind(hyper, 'i', function()
  local battery = hs.battery
  local batteryInfo = ""
  if battery then
    batteryInfo = string.format("Battery: %d%% %s\n",
      battery.percentage(),
      battery.isCharging() and "(Charging)" or "(Not Charging)")
  end

  local wifi = hs.wifi.currentNetwork()
  local wifiInfo = wifi and string.format("WiFi: %s\n", wifi) or "WiFi: Not Connected\n"

  local screenInfo = ""
  for i, screen in ipairs(hs.screen.allScreens()) do
    screenInfo = screenInfo .. string.format("Screen %d: %s\n", i, screen:name())
  end

  hs.alert.show(batteryInfo .. wifiInfo .. screenInfo, 3)
end)

-- ============================================================================
-- STARTUP MESSAGE
-- ============================================================================

hs.alert.show("Hammerspoon Config Loaded ✓", 2)

-- ============================================================================
-- KEYBINDING REFERENCE
-- ============================================================================
--
-- Window Management (⌘⌥⌃):
--   ← → ↑ ↓  - Snap to halves/quarters
--   1-9      - Grid positions (numpad layout)
--   M        - Maximize
--   C        - Center
--   N        - Move to next screen
--
-- Window Movement (⌘⌥⌃):
--   ← → ↑ ↓  - Move window 20px
--   ⇧←→↑↓    - Move window 5px (fine)
--
-- Clipboard (⌥⌃):
--   V        - Show clipboard history
--
-- App Launcher (⌥⌃):
--   C        - Cursor (or VS Code)
--   G        - Chrome
--   T        - Alacritty (or Terminal)
--   E        - Gmail (Chrome site or Mail app)
--   L        - Calendar (Chrome site or Calendar app)
--   O        - Obsidian (or Chrome site or Notes)
--   F        - Finder
--   R        - Reload config
--   `        - Cycle windows
--
-- Focus Management (⌘⌥⌃⇧):
--   ← → ↑ ↓  - Focus window in direction
--
-- Utilities (⌘⌥⌃⇧):
--   G        - Show grid overlay
--   R        - Reload config
--   D        - Find mouse cursor
--   S        - Toggle caffeine (prevent sleep)
--   L        - Lock screen
--   N        - New note
--   I        - System info
--
-- Paste Blocking (⌘⌥):
--   V        - Force paste (types clipboard)
-- ============================================================================
