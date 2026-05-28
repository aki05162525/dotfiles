local wezterm = require("wezterm")

local M = {}

function M.apply(config)
  config.font = wezterm.font("JetBrainsMono Nerd Font")
  config.font_size = 11.0
end

return M
