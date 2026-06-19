-- WezTerm config ローダー。Windows 側 ~/.wezterm.lua の本体として
-- home-manager の weztermWslConfig activation がこの内容を流用する。
-- WEZTERM_DOTFILES_CONFIG_DIR(コピー先 = %USERPROFILE%/.config/wezterm)は
-- activation が先頭に書き足すので、ここでは定義しない。
package.path = WEZTERM_DOTFILES_CONFIG_DIR .. "/?.lua;" .. package.path

return dofile(WEZTERM_DOTFILES_CONFIG_DIR .. "/wezterm.lua")
