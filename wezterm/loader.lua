package.path = os.getenv("USERPROFILE") .. "/.config/wezterm/?.lua;" .. package.path

return dofile(os.getenv("USERPROFILE") .. "/.config/wezterm/wezterm.lua")
