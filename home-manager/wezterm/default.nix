{
  pkgs,
  lib,
  config,
  ...
}:

{
  # macOS はリポジトリへリンクし、WSL2 は activation で Windows 側へコピーする。
  home.file.".config/wezterm" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/wezterm";
  };

  # wsl.localhost 越しの参照は遅く不安定なことがあるため、switch 時に
  # wezterm/ を %USERPROFILE%/.config/wezterm へミラーし、~/.wezterm.lua を生成する。
  # 非 WSL の Linux では実行しない。
  # Windows ホームが有効な絶対パスの場合だけコピーし、同じ内容は書き込まない。
  # dry-run では一時ファイルも作らず、手書きの ~/.wezterm.lua は上書きしない。
  home.activation.weztermWslConfig = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      (
        if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
          src="${config.home.homeDirectory}/dotfiles/wezterm"
          if [ ! -f "$src/wezterm.lua" ]; then
            echo "wezterm: $src が見つからないためスキップしました。" >&2
          else
            # activation は最小 PATH で走るため wslpath / cmd.exe を絶対パスで呼ぶ。
            # 空文字を wslpath に渡すと '.' になるので、変換前にも検証する。
            if ! win_profile="$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null)"; then
              echo "wezterm: Windows ホームの取得に失敗したためスキップしました。" >&2
              exit 0
            fi
            win_profile="$(printf '%s' "$win_profile" | tr -d '\r')"
            if [ -z "$win_profile" ] || ! win_home="$(/usr/bin/wslpath -u "$win_profile")"; then
              echo "wezterm: Windows ホームの変換に失敗したためスキップしました。" >&2
              exit 0
            fi
            if [[ "$win_home" != /* ]] || [ ! -d "$win_home" ]; then
              echo "wezterm: Windows ホームを特定できないためスキップしました。" >&2
            else
              dest="$win_home/.config/wezterm"
              run mkdir -p "$dest"

              # repo の wezterm モジュールを Windows 側へミラー(loader と .example は除外)。
              for f in "$src"/*.lua; do
                base="$(basename "$f")"
                case "$base" in
                loader.lua) continue ;;
                esac
                if ! cmp -s "$f" "$dest/$base"; then
                  run cp "$f" "$dest/$base"
                  if [[ ! -v DRY_RUN ]]; then
                    echo "wezterm: $dest/$base を更新しました。"
                  fi
                fi
              done
              # コピー元にない lua と loader.lua をコピー先から削除する。
              # workspace.local.lua はコピー元に存在する限り残す。
              for f in "$dest"/*.lua; do
                [ -e "$f" ] || continue # glob 無マッチ対策
                base="$(basename "$f")"
                if [ ! -f "$src/$base" ] || [ "$base" = loader.lua ]; then
                  run rm -f "$f"
                  if [[ ! -v DRY_RUN ]]; then
                    echo "wezterm: $f を削除しました(コピー対象外のため)。"
                  fi
                fi
              done

              # Windows 側エントリ ~/.wezterm.lua を生成(コピー先を指す bootstrap)。
              target="$win_home/.wezterm.lua"
              if [ -f "$target" ] && ! grep -qF 'WEZTERM_DOTFILES_CONFIG_DIR' "$target"; then
                echo "wezterm: $target は dotfiles 管理外のため上書きしません。" >&2
                exit 0
              fi
              # メモリ上で比較し、dry-run では一時ファイルも作らない。
              bootstrap="$(
                printf '%s\n' 'WEZTERM_DOTFILES_CONFIG_DIR = os.getenv("USERPROFILE") .. "/.config/wezterm"'
                cat "$src/loader.lua"
              )"
              if cmp -s <(printf '%s\n' "$bootstrap") "$target"; then
                exit 0
              fi
              if [[ -v DRY_RUN ]]; then
                echo "wezterm: $target を更新する予定です(dry-run)。"
                exit 0
              fi
              tmp="$(mktemp)"
              trap 'rm -f "$tmp"' EXIT
              printf '%s\n' "$bootstrap" >"$tmp"
              run mv "$tmp" "$target"
              echo "wezterm: $target を更新しました。"
            fi
          fi
        fi
      )
    ''
  );
}
