local wezterm = require("wezterm")

local M = {}

function M.apply(config)
  if wezterm.target_triple:find("windows") then
    config.default_domain = "WSL:Ubuntu"
  end
end

return M
