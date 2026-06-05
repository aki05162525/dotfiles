-- WezTerm config ローダー。Windows 側の ~/.wezterm.lua として
-- scripts/install-wezterm-config.sh が生成する。
-- WEZTERM_DOTFILES_CONFIG_DIR(設定実体のディレクトリ)はスクリプトが
-- このファイルの先頭に書き込むので、ここでは定義しない。
package.path = WEZTERM_DOTFILES_CONFIG_DIR .. "/?.lua;" .. package.path

return dofile(WEZTERM_DOTFILES_CONFIG_DIR .. "/wezterm.lua")
