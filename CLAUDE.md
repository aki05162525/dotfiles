# dotfiles

WSL2 (Ubuntu) と macOS (Apple Silicon) 両対応の Home Manager (flake構成) で管理する個人 dotfiles。

## ディレクトリ構成

```
dotfiles/
├─ flake.nix              # ルートに配置(エントリポイント)
├─ flake.lock
├─ README.md
├─ CLAUDE.md
├─ memo.md                # 作業中のTODOメモ
├─ lefthook.yml           # ローカル git hook(pre-commit / pre-push)
├─ stylua.toml            # Lua フォーマッタ設定(2スペース字下げ)
├─ docs/
│  ├─ setup.md            # 別マシンでのセットアップ手順
│  └─ tool-management.md  # Nix / mise / corepack 等のレイヤー構造
├─ home-manager/
│  ├─ home.nix            # エントリ。ツール別モジュールを imports
│  ├─ direnv/default.nix
│  ├─ fzf/default.nix
│  ├─ git/default.nix
│  ├─ mise/default.nix
│  ├─ zsh/default.nix
│  ├─ starship/
│  │  ├─ default.nix
│  │  └─ starship.toml
│  ├─ wezterm/default.nix # WezTerm 反映(macOS symlink / WSL2 コピー activation)
│  └─ ...
├─ wezterm/               # WezTerm 設定の実体(switch で各 OS へ反映)
│  ├─ wezterm.lua
│  ├─ appearance.lua
│  ├─ keys.lua
│  ├─ platform.lua
│  ├─ workspace.lua
│  ├─ workspace.local.lua.example
│  └─ loader.lua
└─ (scripts なし: WezTerm の Windows 側反映は home-manager switch に統合済み)
```

## 設定ファイル分割の方針

**ツールごとに `home-manager/<tool>/default.nix` のフォルダ構成**で分割し、`home.nix` の `imports` で取り込む。フォルダ名だけで `default.nix` が自動的に読まれる。

```nix
# home.nix
{ pkgs, ... }:
{
  imports = [
    ./mise
    ./direnv
    ./fzf
    ./starship
    ./git
    ./zsh
  ];

  # 共通設定はここに残す(home.username, home.stateVersion, home.packages 等)
}
```

各モジュールは独立した Nix モジュールとして書く:

```nix
# mise/default.nix
{ ... }:    # pkgs を使わないモジュールは { ... }: でOK
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig.tools = {
      node = "24";
      go = "1.26";
    };
  };
}
```

`pkgs` を参照する場合は `{ pkgs, ... }:` と明示する。**未使用引数は書かない**(例: `config` を使わないなら `{ pkgs, ... }:`)。

設定ファイル(`.toml` 等)を持つツールはフォルダ内に同居させ、`./<filename>` で参照する。

## 適用コマンド

リポジトリルートで、マシンに対応する構成を指定する:

```sh
home-manager switch --flake .#akihiro@wsl   # WSL2 (Windows)
home-manager switch --flake .#takagi@mac   # macOS (Apple Silicon)
```

ホスト別の構成は `flake.nix` の `homeConfigurations` で定義している。
新しいマシンを足すときは `"<username>@<host>" = mkHome { system = ...; username = ...; };` を1行追加する(homeDirectory は OS から自動導出)。

**新規 `.nix` ファイルを追加した場合は必ず `git add` してから switch する**こと(Nix flake は git tracked なファイルしか見ない)。

## WezTerm 設定の更新手順

WezTerm は Windows 側アプリだが、設定実体はこのリポジトリの `wezterm/` で管理し、**`home-manager switch` で各 OS へ反映**する(専用スクリプトは廃止)。リポジトリが常に source of truth で、Windows 側に古いコピーが置き去りになるドリフトを防ぐ。

- **WSL2 (Windows)**: `home-manager/wezterm/default.nix` の `weztermWslConfig` activation が、`switch` のたびに `wezterm/*.lua` を Windows 側 `%USERPROFILE%\.config\wezterm` へミラーコピーし、エントリ `~/.wezterm.lua` をそこへ向ける(`\\wsl.localhost` 越しの直接参照は遅い・たまに不安定なためコピー方式)。
- **macOS**: `~/.config/wezterm` をリポジトリの `wezterm/` へ symlink する(`home-manager/wezterm/default.nix` の `home.file`。symlink なので常に同期)。

どちらも `switch` 後に追加作業は不要で、`wezterm/*.lua` を編集したら **WSL は `home-manager switch` でコピーを更新 → WezTerm をリロード(Ctrl+Shift+R)、macOS はリロードのみ**で反映される。

`wezterm/` の役割:

- `wezterm.lua`: エントリポイント。各設定モジュールを読み込む
- `appearance.lua`: 配色、透過、フォントなど見た目の設定
- `keys.lua`: キーバインド
- `platform.lua`: Windows / WSL など環境依存の設定
- `workspace.lua`: workspace 切り替えの共通ロジック
- `workspace.local.lua`: PC ごとの workspace 一覧。git 管理しない
- `workspace.local.lua.example`: `workspace.local.lua` のサンプル
- `loader.lua`: Windows 側 `~/.wezterm.lua` の本体。WSL2 で activation が先頭に `WEZTERM_DOTFILES_CONFIG_DIR`(コピー先 `%USERPROFILE%/.config/wezterm`)を書き足して生成する

WSL2 の `weztermWslConfig` activation の挙動と安全策:

- WSL ランタイム判定(`/proc/version`)でガードし、非 WSL の Linux と macOS では何もしない。
- `wezterm/*.lua`(`loader.lua` と `*.example` は除く)を `%USERPROFILE%\.config\wezterm` へコピーし、内容が同じファイルは書き込まない(`cmp` で冪等)。
- `~/.wezterm.lua` は dotfiles 生成物(`WEZTERM_DOTFILES_CONFIG_DIR` 署名を含むファイル)のときだけ更新し、手書きの無関係なファイルは上書きしない。
- activation は最小 PATH で走るため、`wslpath` / `cmd.exe` は絶対パスで呼ぶ。

`workspace.local.lua`(PC ごとの workspace、git 管理外)も `wezterm/` に置けばコピー対象になる。`switch` のたびにコピーが最新化されるので、Windows 側を直接いじる必要はない。

## フォーマット

`flake.nix` の `formatter` に nixfmt(公式フォーマッタ)を定義済み。変更後はリポジトリルートで:

```sh
nix fmt
```

特定ファイルだけ整形したいときは `nixfmt <file>...` を直接呼んでもよい。

## ツール管理の棲み分け

詳細は [docs/tool-management.md](docs/tool-management.md) 参照。要約:

- **Nix (Home Manager)**: グローバルCLI(git, gh, mise, direnv, starship, jq, ripgrep など)
- **WezTerm**: Windows側ターミナルアプリ。設定実体は `wezterm/` で管理し、`home-manager switch` の activation で各 OS へ反映する(WSL2 は Windows 側へコピー、macOS は symlink)
- **mise**: Node, Go など言語ランタイムのバージョン管理(プロジェクト別の `.tool-versions` 対応)
- **corepack** (Node 同梱): pnpm, yarn のバージョン管理(`package.json` の `packageManager` フィールド)
- **direnv**: プロジェクト別の環境変数(`.envrc`)

Claude Code / codex / gemini などの AI CLI は **自己更新する**ため Nix 管理しない(read-only な Nix store と相性が悪い)。`~/.local/bin/claude` のような形で公式インストーラに任せる。

Rust の cargo/rustc は **rustup のまま**(rustup 自体が公式のバージョン管理機構なので)。

## 別マシンへの展開

[docs/setup.md](docs/setup.md) 参照。
