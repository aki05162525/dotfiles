local wezterm = require("wezterm")

local config = wezterm.config_builder()

require("platform").apply(config)
require("appearance").apply(config)
require("keys").apply(config)

return config
