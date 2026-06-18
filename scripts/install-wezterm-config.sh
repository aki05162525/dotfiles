#!/usr/bin/env bash
set -euo pipefail

# WSL2 専用。macOS は home-manager switch で ~/.config/wezterm symlink が自動作成される。
if ! grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
  echo "Error: このスクリプトは WSL2 でのみ動作します。" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

distro="${WSL_DISTRO_NAME:-}"
if [ -z "${distro}" ]; then
  echo "Error: WSL_DISTRO_NAME が取得できません(WSL 上で実行してください)。" >&2
  exit 1
fi

win_home="$(wslpath -u "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')")"

# 例: //wsl.localhost/Ubuntu/home/akihiro/dotfiles/wezterm
unc_config_dir="//wsl.localhost/${distro}${repo_root}/wezterm"

{
  echo "WEZTERM_DOTFILES_CONFIG_DIR = \"${unc_config_dir}\""
  cat "${repo_root}/wezterm/loader.lua"
} > "${win_home}/.wezterm.lua"

echo "Installed ${win_home}/.wezterm.lua"
echo "  → ${unc_config_dir} を直接参照します(コピー不要)。"
echo "  今後は wezterm/*.lua を編集して WezTerm をリロード(Ctrl+Shift+R)するだけで反映されます。"
echo "  ※ workspace.local.lua は ${repo_root}/wezterm/workspace.local.lua に置いてください。"
