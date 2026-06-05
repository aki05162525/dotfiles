#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$(uname -s)" in
  Darwin)
    # macOS: WezTerm はネイティブアプリで ~/.config/wezterm を直接読む。
    # リポジトリが mac 上にあるので symlink して編集を即反映させる。
    config_dir="${HOME}/.config/wezterm"
    mkdir -p "${config_dir}"

    # loader.lua は Windows 専用(USERPROFILE 経由)なので mac では貼らない。
    for f in "${repo_root}/wezterm/"*.lua; do
      name="$(basename "$f")"
      [ "$name" = "loader.lua" ] && continue
      ln -sf "$f" "${config_dir}/${name}"
    done

    echo "Linked ${config_dir}/wezterm.lua -> ${repo_root}/wezterm/wezterm.lua"
    ;;

  *)
    # WSL (Windows): 設定実体は Windows 側にあるのでコピーする。
    win_home="$(wslpath -u "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')")"
    config_dir="${win_home}/.config/wezterm"

    mkdir -p "${config_dir}"
    cp "${repo_root}/wezterm/"*.lua "${config_dir}/"
    cp "${repo_root}/wezterm/loader.lua" "${win_home}/.wezterm.lua"

    echo "Installed ${config_dir}/wezterm.lua"
    echo "Installed ${win_home}/.wezterm.lua"
    ;;
esac
