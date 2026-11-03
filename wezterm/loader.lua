-- Windows 側 ~/.wezterm.lua の本体。
-- activation が先頭に WEZTERM_DOTFILES_CONFIG_DIR(%USERPROFILE%/.config/wezterm)を追加する。
package.path = WEZTERM_DOTFILES_CONFIG_DIR .. "/?.lua;" .. package.path

return dofile(WEZTERM_DOTFILES_CONFIG_DIR .. "/wezterm.lua")
