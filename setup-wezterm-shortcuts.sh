#!/usr/bin/env bash

set -euo pipefail

WEZTERM_CONFIG="$HOME/.wezterm.lua"
BACKUP="$HOME/.wezterm.lua.backup.$(date +%Y%m%d-%H%M%S)"

echo "Setting up WezTerm shortcuts..."

# Back up an existing configuration.
if [[ -f "$WEZTERM_CONFIG" ]]; then
  cp "$WEZTERM_CONFIG" "$BACKUP"
  echo "Backed up existing config to:"
  echo "  $BACKUP"
fi

cat > "$WEZTERM_CONFIG" <<'EOF'
local wezterm = require("wezterm")
local act = wezterm.action

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Appearance
config.color_scheme = "Catppuccin Mocha"

config.font = wezterm.font_with_fallback({
  "JetBrainsMono Nerd Font",
  "JetBrainsMono NFM",
  "Menlo",
})

config.font_size = 14.0
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20

config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingBar"

-- Performance
config.front_end = "WebGpu"
config.max_fps = 120
config.animation_fps = 120
config.scrollback_lines = 20000
config.enable_scroll_bar = false

-- Window
config.initial_cols = 170
config.initial_rows = 45
config.default_prog = { "/bin/zsh", "-l" }
config.window_close_confirmation = "NeverPrompt"
config.audible_bell = "Disabled"

-- Tabs
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- macOS shortcuts
config.keys = {
  -- Tabs
  { key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "[", mods = "CMD", action = act.ActivateTabRelative(-1) },
  { key = "]", mods = "CMD", action = act.ActivateTabRelative(1) },

  { key = "1", mods = "CMD", action = act.ActivateTab(0) },
  { key = "2", mods = "CMD", action = act.ActivateTab(1) },
  { key = "3", mods = "CMD", action = act.ActivateTab(2) },
  { key = "4", mods = "CMD", action = act.ActivateTab(3) },
  { key = "5", mods = "CMD", action = act.ActivateTab(4) },
  { key = "6", mods = "CMD", action = act.ActivateTab(5) },
  { key = "7", mods = "CMD", action = act.ActivateTab(6) },
  { key = "8", mods = "CMD", action = act.ActivateTab(7) },
  { key = "9", mods = "CMD", action = act.ActivateTab(8) },

  -- Splits
  {
    key = "d",
    mods = "CMD",
    action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "d",
    mods = "CMD|SHIFT",
    action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
  },

  -- Close pane
  {
    key = "W",
    mods = "CMD|SHIFT",
    action = act.CloseCurrentPane({ confirm = false }),
  },

  -- Zoom
  {
    key = "Enter",
    mods = "CMD",
    action = act.TogglePaneZoomState,
  },

  -- Pane navigation
  {
    key = "LeftArrow",
    mods = "OPT",
    action = act.ActivatePaneDirection("Left"),
  },
  {
    key = "RightArrow",
    mods = "OPT",
    action = act.ActivatePaneDirection("Right"),
  },
  {
    key = "UpArrow",
    mods = "OPT",
    action = act.ActivatePaneDirection("Up"),
  },
  {
    key = "DownArrow",
    mods = "OPT",
    action = act.ActivatePaneDirection("Down"),
  },

  -- Pane resizing
  {
    key = "LeftArrow",
    mods = "OPT|SHIFT",
    action = act.AdjustPaneSize({ "Left", 5 }),
  },
  {
    key = "RightArrow",
    mods = "OPT|SHIFT",
    action = act.AdjustPaneSize({ "Right", 5 }),
  },
  {
    key = "UpArrow",
    mods = "OPT|SHIFT",
    action = act.AdjustPaneSize({ "Up", 5 }),
  },
  {
    key = "DownArrow",
    mods = "OPT|SHIFT",
    action = act.AdjustPaneSize({ "Down", 5 }),
  },

  -- Clear terminal
  {
    key = "k",
    mods = "CMD",
    action = act.Multiple({
      act.ClearScrollback("ScrollbackAndViewport"),
      act.SendKey({ key = "L", mods = "CTRL" }),
    }),
  },

  -- Launcher / utilities
  {
    key = "l",
    mods = "CMD",
    action = act.ShowLauncher,
  },
  {
    key = "p",
    mods = "CMD",
    action = act.ActivateCommandPalette,
  },
}

return config
EOF

echo
echo "✓ WezTerm config written to $WEZTERM_CONFIG"
echo
echo "Restart WezTerm or reload the config with:"
echo "  Cmd+Shift+R"
echo
echo "Shortcut setup complete."
