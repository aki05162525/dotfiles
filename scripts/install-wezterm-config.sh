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

    echo "Linked *.lua (except loader.lua) into ${config_dir}/"
    ;;

  Linux)
    # WSL2 (Windows) のみ対応。素の Linux では Windows 側のパスが取れないので弾く。
    if ! grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
      echo "Error: このスクリプトは WSL2 または macOS でのみ動作します(素の Linux は非対応)。" >&2
      exit 1
    fi

    # WSL (Windows): コピーせず、Windows 側 WezTerm から \\wsl.localhost 経由で
    # このリポジトリの wezterm/ を直接読ませる。これで「編集 → コピー」が不要になり、
    # wezterm/*.lua を編集して WezTerm をリロードするだけで反映される。
    distro="${WSL_DISTRO_NAME:-}"
    if [ -z "${distro}" ]; then
      echo "Error: WSL_DISTRO_NAME が取得できません(WSL 上で実行してください)。" >&2
      exit 1
    fi

    win_home="$(wslpath -u "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')")"

    # 例: //wsl.localhost/Ubuntu/home/akihiro/dotfiles/wezterm
    # forward slash の UNC パスは Windows / WezTerm から問題なく読める。
    unc_config_dir="//wsl.localhost/${distro}${repo_root}/wezterm"

    # loader.lua の先頭に設定ディレクトリ(UNC パス)を差し込んで生成する。
    {
      echo "WEZTERM_DOTFILES_CONFIG_DIR = \"${unc_config_dir}\""
      cat "${repo_root}/wezterm/loader.lua"
    } > "${win_home}/.wezterm.lua"

    echo "Installed ${win_home}/.wezterm.lua"
    echo "  → ${unc_config_dir} を直接参照します(コピー不要)。"
    echo "  今後は wezterm/*.lua を編集して WezTerm をリロード(Ctrl+Shift+R)するだけで反映されます。"
    echo "  ※ workspace.local.lua は ${repo_root}/wezterm/workspace.local.lua に置いてください。"
    ;;

  *)
    echo "Error: 未対応の環境です($(uname -s))。WSL2 または macOS で実行してください。" >&2
    exit 1
    ;;
esac
