{
  pkgs,
  lib,
  config,
  ...
}:

{
  # macOS: ~/.config/wezterm → ~/dotfiles/wezterm をディレクトリごと symlink する
  #         (symlink なので常に repo と同期)。
  # WSL2 は下の weztermWslConfig activation で Windows 側へコピーする。
  home.file.".config/wezterm" = lib.mkIf pkgs.stdenv.isDarwin {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/wezterm";
  };

  # WSL2 専用: WezTerm は Windows 側アプリで wsl.localhost 越しの直接参照は遅い・たまに
  # 不安定なため、switch のたびに repo の wezterm/ を Windows 側 %USERPROFILE%/.config/wezterm
  # へミラーコピーし、エントリ ~/.wezterm.lua をそこへ向ける。これで「古いコピーが置き去り」に
  # なるドリフトを防ぐ(repo が常に source of truth)。
  # macOS は上の home.file で symlink 済み。非 WSL の Linux では何もしない。
  # 旧 scripts/install-wezterm-config.sh を home-manager switch に統合したもの。
  #
  # 安全策:
  #   - WSL ランタイム判定でガード(/proc/version)
  #   - 内容が同じファイルは書き込まない(cmp で冪等)
  #   - ~/.wezterm.lua は dotfiles 生成物(WEZTERM_DOTFILES_CONFIG_DIR 署名)以外は上書きしない
  home.activation.weztermWslConfig = lib.mkIf pkgs.stdenv.isLinux (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
        src="${config.home.homeDirectory}/dotfiles/wezterm"
        if [ ! -f "$src/wezterm.lua" ]; then
          echo "wezterm: $src が見つからないためスキップしました。" >&2
        else
          # activation は最小 PATH で走るため wslpath / cmd.exe を絶対パスで呼ぶ。
          win_home="$(/usr/bin/wslpath -u "$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"
          if [ -z "$win_home" ] || [ ! -d "$win_home" ]; then
            echo "wezterm: Windows ホームを特定できないためスキップしました。" >&2
          else
            dest="$win_home/.config/wezterm"
            mkdir -p "$dest"

            # repo の wezterm モジュールを Windows 側へミラー(loader と .example は除外)。
            for f in "$src"/*.lua; do
              base="$(basename "$f")"
              case "$base" in
              loader.lua | workspace.local.lua.example) continue ;;
              esac
              if ! cmp -s "$f" "$dest/$base"; then
                cp "$f" "$dest/$base"
                echo "wezterm: $dest/$base を更新しました。"
              fi
            done
            # repo から消えた/リネームされた lua を Windows 側からも掃除(ドリフト防止)。
            # コピー対象(src の *.lua から loader と .example を除いた集合)に無い dest 側の
            # lua を削除する。これで rename / 削除が反映され、旧コピー方式の名残
            # (.config/wezterm/loader.lua)もここで消える。
            # workspace.local.lua(PC ごと・git 管理外だが src には存在しコピー対象)は
            # src に在る限り消されない。
            for f in "$dest"/*.lua; do
              [ -e "$f" ] || continue # glob 無マッチ対策
              base="$(basename "$f")"
              if [ ! -f "$src/$base" ] || [ "$base" = loader.lua ] || [ "$base" = workspace.local.lua.example ]; then
                rm -f "$f"
                echo "wezterm: $f を削除しました(repo に存在しないため)。"
              fi
            done

            # Windows 側エントリ ~/.wezterm.lua を生成(コピー先を指す bootstrap)。
            target="$win_home/.wezterm.lua"
            tmp="$(mktemp)"
            {
              printf '%s\n' 'WEZTERM_DOTFILES_CONFIG_DIR = os.getenv("USERPROFILE") .. "/.config/wezterm"'
              cat "$src/loader.lua"
            } >"$tmp"
            if [ -f "$target" ] && ! grep -qF 'WEZTERM_DOTFILES_CONFIG_DIR' "$target"; then
              echo "wezterm: $target は dotfiles 管理外のため上書きしません。" >&2
              rm -f "$tmp"
            elif ! cmp -s "$tmp" "$target"; then
              mv "$tmp" "$target"
              echo "wezterm: $target を更新しました。"
            else
              rm -f "$tmp"
            fi
          fi
        fi
      fi
    ''
  );
}
