#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
win_user="$(cmd.exe /c echo %USERNAME% | tr -d '\r')"
win_home="/mnt/c/Users/${win_user}"
config_dir="${win_home}/.config/wezterm"

mkdir -p "${config_dir}"
cp "${repo_root}/wezterm/"*.lua "${config_dir}/"
cp "${repo_root}/wezterm/loader.lua" "${win_home}/.wezterm.lua"

echo "Installed ${config_dir}/wezterm.lua"
echo "Installed ${win_home}/.wezterm.lua"
