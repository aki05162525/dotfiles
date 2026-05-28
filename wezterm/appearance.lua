local wezterm = require("wezterm")

local M = {}

local LEFT = wezterm.nerdfonts.pl_left_hard_divider
local RIGHT = wezterm.nerdfonts.pl_right_hard_divider

local BG       = "#282c34"
local ACT_BG   = "#a3d4f5"
local ACT_FG   = "#282c34"
local INACT_BG = "#3e4452"
local INACT_FG = "#9da5b4"

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local tab_bg = tab.is_active and ACT_BG or INACT_BG
  local tab_fg = tab.is_active and ACT_FG or INACT_FG

  local title = tab.active_pane.title
  if #title > max_width - 4 then
    title = wezterm.truncate_right(title, max_width - 4)
  end

  return {
    { Background = { Color = BG } },      { Foreground = { Color = tab_bg } },
    { Text = LEFT },
    { Background = { Color = tab_bg } },  { Foreground = { Color = tab_fg } },
    { Text = " " .. (tab.tab_index + 1) .. ": " .. title .. " " },
    { Background = { Color = BG } },      { Foreground = { Color = tab_bg } },
    { Text = RIGHT },
  }
end)

function M.apply(config)
  config.color_scheme = "OneHalfDark"
  config.window_background_opacity = 0.75
  config.font = wezterm.font_with_fallback({
    "JetBrains Mono NL",
    "JetBrainsMono Nerd Font",
  })
  config.font_size = 12.0
  config.colors = {
    foreground   = "#abb2bf",
    selection_bg = "#3e4452",
    selection_fg = "#abb2bf",
    split        = "#61afef",
  }
  config.inactive_pane_hsb = {
    saturation = 0.5,
    brightness = 0.4,
  }
  config.use_fancy_tab_bar = true
  config.tab_bar_at_bottom = false
  config.window_frame = {
    font = wezterm.font("JetBrainsMono Nerd Font"),
    font_size = 12.0,
    active_titlebar_bg   = "#282c34",
    inactive_titlebar_bg = "#1e2228",
    active_titlebar_fg   = "#dcdfe4",
    inactive_titlebar_fg = "#5c6370",
    button_fg            = "#9da5b4",
    button_bg            = "#282c34",
    button_hover_fg      = "#dcdfe4",
    button_hover_bg      = "#3e4452",
  }
end

return M
