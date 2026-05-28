WEZTERM_DOTFILES_CONFIG_DIR = os.getenv("USERPROFILE") .. "/.config/wezterm"
package.path = WEZTERM_DOTFILES_CONFIG_DIR .. "/?.lua;" .. package.path

return dofile(WEZTERM_DOTFILES_CONFIG_DIR .. "/wezterm.lua")
