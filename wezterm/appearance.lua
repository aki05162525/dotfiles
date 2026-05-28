local wezterm = require("wezterm")

local M = {}

function M.apply(config)
  config.color_scheme = "OneHalfDark"
  config.window_background_opacity = 0.75
  config.font = wezterm.font_with_fallback({
    "JetBrains Mono NL",
    "JetBrainsMono Nerd Font",
  })
  config.font_size = 12.0
end

return M
