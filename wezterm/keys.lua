local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function once(action)
  return act.Multiple({ action, act.PopKeyTable })
end

function M.apply(config)
  config.keys = {
    {
      key = "c",
      mods = "CTRL|SHIFT",
      action = act.CopyTo("Clipboard"),
    },
    {
      key = "v",
      mods = "CTRL|SHIFT",
      action = act.PasteFrom("Clipboard"),
    },

    -- Zellij-like direct pane navigation.
    { key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
    { key = "LeftArrow", mods = "ALT", action = act.ActivatePaneDirection("Left") },
    { key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },
    { key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
    { key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },

    -- Zellij-like quick actions.
    { key = "n", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "+", mods = "ALT", action = act.AdjustPaneSize({ "Up", 3 }) },
    { key = "=", mods = "ALT", action = act.AdjustPaneSize({ "Up", 3 }) },
    { key = "-", mods = "ALT", action = act.AdjustPaneSize({ "Down", 3 }) },
    { key = "[", mods = "ALT", action = act.ActivateTabRelative(-1) },
    { key = "]", mods = "ALT", action = act.ActivateTabRelative(1) },
    { key = "i", mods = "ALT", action = act.MoveTabRelative(-1) },
    { key = "o", mods = "ALT", action = act.MoveTabRelative(1) },

    -- Mode-style key tables, matching the old Zellij entry keys.
    { key = "q", mods = "CTRL", action = act.ActivateKeyTable({ name = "pane", one_shot = false, timeout_milliseconds = 1500 }) },
    { key = "t", mods = "CTRL", action = act.ActivateKeyTable({ name = "tab", one_shot = false, timeout_milliseconds = 1500 }) },
    { key = "n", mods = "CTRL", action = act.ActivateKeyTable({ name = "resize", one_shot = false, timeout_milliseconds = 1500 }) },
    { key = "h", mods = "CTRL", action = act.ActivateKeyTable({ name = "move", one_shot = false, timeout_milliseconds = 1500 }) },
    { key = "s", mods = "CTRL", action = act.ActivateCopyMode },
    { key = "o", mods = "CTRL", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
  }

  config.key_tables = {
    pane = {
      { key = "h", action = act.ActivatePaneDirection("Left") },
      { key = "j", action = act.ActivatePaneDirection("Down") },
      { key = "k", action = act.ActivatePaneDirection("Up") },
      { key = "l", action = act.ActivatePaneDirection("Right") },
      { key = "LeftArrow", action = act.ActivatePaneDirection("Left") },
      { key = "DownArrow", action = act.ActivatePaneDirection("Down") },
      { key = "UpArrow", action = act.ActivatePaneDirection("Up") },
      { key = "RightArrow", action = act.ActivatePaneDirection("Right") },
      { key = "d", action = once(act.SplitVertical({ domain = "CurrentPaneDomain" })) },
      { key = "r", action = once(act.SplitHorizontal({ domain = "CurrentPaneDomain" })) },
      { key = "n", action = once(act.SplitVertical({ domain = "CurrentPaneDomain" })) },
      { key = "p", action = once(act.PaneSelect) },
      { key = "f", action = once(act.TogglePaneZoomState) },
      { key = "x", action = once(act.CloseCurrentPane({ confirm = false })) },
      { key = "z", action = once(act.TogglePaneZoomState) },
      { key = "q", action = act.PopKeyTable },
      { key = "Escape", action = act.PopKeyTable },
      { key = "q", mods = "CTRL", action = act.PopKeyTable },
      { key = "p", mods = "CTRL", action = act.PopKeyTable },
    },

    tab = {
      { key = "h", action = once(act.ActivateTabRelative(-1)) },
      { key = "j", action = once(act.ActivateTabRelative(1)) },
      { key = "k", action = once(act.ActivateTabRelative(-1)) },
      { key = "l", action = once(act.ActivateTabRelative(1)) },
      { key = "LeftArrow", action = once(act.ActivateTabRelative(-1)) },
      { key = "DownArrow", action = once(act.ActivateTabRelative(1)) },
      { key = "UpArrow", action = once(act.ActivateTabRelative(-1)) },
      { key = "RightArrow", action = once(act.ActivateTabRelative(1)) },
      { key = "n", action = once(act.SpawnTab("CurrentPaneDomain")) },
      { key = "x", action = once(act.CloseCurrentTab({ confirm = false })) },
      { key = "[", action = once(act.MoveTabRelative(-1)) },
      { key = "]", action = once(act.MoveTabRelative(1)) },
      { key = "Tab", action = once(act.ActivateLastTab) },
      { key = "1", action = once(act.ActivateTab(0)) },
      { key = "2", action = once(act.ActivateTab(1)) },
      { key = "3", action = once(act.ActivateTab(2)) },
      { key = "4", action = once(act.ActivateTab(3)) },
      { key = "5", action = once(act.ActivateTab(4)) },
      { key = "6", action = once(act.ActivateTab(5)) },
      { key = "7", action = once(act.ActivateTab(6)) },
      { key = "8", action = once(act.ActivateTab(7)) },
      { key = "9", action = once(act.ActivateTab(8)) },
      {
        key = "r",
        action = act.PromptInputLine({
          description = "Rename tab",
          action = wezterm.action_callback(function(window, _, line)
            if line then
              window:active_tab():set_title(line)
            end
          end),
        }),
      },
      { key = "q", action = act.PopKeyTable },
      { key = "Escape", action = act.PopKeyTable },
      { key = "q", mods = "CTRL", action = act.PopKeyTable },
      { key = "t", mods = "CTRL", action = act.PopKeyTable },
    },

    resize = {
      { key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
      { key = "j", action = act.AdjustPaneSize({ "Down", 3 }) },
      { key = "k", action = act.AdjustPaneSize({ "Up", 3 }) },
      { key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
      { key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 3 }) },
      { key = "DownArrow", action = act.AdjustPaneSize({ "Down", 3 }) },
      { key = "UpArrow", action = act.AdjustPaneSize({ "Up", 3 }) },
      { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 3 }) },
      { key = "+", action = act.AdjustPaneSize({ "Up", 3 }) },
      { key = "=", action = act.AdjustPaneSize({ "Up", 3 }) },
      { key = "-", action = act.AdjustPaneSize({ "Down", 3 }) },
      { key = "q", action = act.PopKeyTable },
      { key = "Escape", action = act.PopKeyTable },
      { key = "q", mods = "CTRL", action = act.PopKeyTable },
      { key = "n", mods = "CTRL", action = act.PopKeyTable },
    },

    move = {
      { key = "h", action = once(act.RotatePanes("CounterClockwise")) },
      { key = "j", action = once(act.RotatePanes("Clockwise")) },
      { key = "k", action = once(act.RotatePanes("CounterClockwise")) },
      { key = "l", action = once(act.RotatePanes("Clockwise")) },
      { key = "n", action = once(act.RotatePanes("Clockwise")) },
      { key = "p", action = once(act.RotatePanes("CounterClockwise")) },
      { key = "Tab", action = once(act.RotatePanes("Clockwise")) },
      { key = "q", action = act.PopKeyTable },
      { key = "Escape", action = act.PopKeyTable },
      { key = "q", mods = "CTRL", action = act.PopKeyTable },
      { key = "h", mods = "CTRL", action = act.PopKeyTable },
    },
  }
end

return M
