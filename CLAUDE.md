# dotfiles

WSL (Ubuntu) 上の Home Manager (flake構成) で管理する個人 dotfiles。

## ディレクトリ構成

```
dotfiles/
├─ flake.nix              # ルートに配置(エントリポイント)
├─ flake.lock
├─ README.md
├─ CLAUDE.md
├─ memo.md                # 作業中のTODOメモ
├─ docs/
│  ├─ setup.md            # 別マシンでのセットアップ手順
│  └─ tool-management.md  # Nix / mise / corepack 等のレイヤー構造
└─ home-manager/
   ├─ home.nix            # エントリ。ツール別モジュールを imports
   ├─ direnv/default.nix
   ├─ fzf/default.nix
   ├─ git/default.nix
   ├─ mise/default.nix
   ├─ zsh/default.nix
   ├─ starship/
   │  ├─ default.nix
   │  └─ starship.toml
   └─ ...
├─ wezterm/               # Windows側へコピーして使う WezTerm 設定
│  ├─ wezterm.lua
│  ├─ appearance.lua
│  ├─ keys.lua
│  ├─ platform.lua
│  └─ loader.lua
└─ scripts/
   └─ install-wezterm-config.sh
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
    globalConfig.tools.node = "22";
  };
}
```

`pkgs` を参照する場合は `{ pkgs, ... }:` と明示する。**未使用引数は書かない**(例: `config` を使わないなら `{ pkgs, ... }:`)。

設定ファイル(`.toml` 等)を持つツールはフォルダ内に同居させ、`./<filename>` で参照する。

## 適用コマンド

リポジトリルートで:

```sh
home-manager switch --flake .#akihiro
```

**新規 `.nix` ファイルを追加した場合は必ず `git add` してから switch する**こと(Nix flake は git tracked なファイルしか見ない)。

## WezTerm 設定の更新手順

WezTerm は Windows 側アプリなので、設定実体はこのリポジトリの `wezterm/` で管理し、変更後に Windows 側へコピーする。

`wezterm/` の役割:

- `wezterm.lua`: エントリポイント。各設定モジュールを読み込む
- `appearance.lua`: 配色、透過、フォントなど見た目の設定
- `keys.lua`: キーバインド
- `platform.lua`: Windows / WSL など環境依存の設定
- `loader.lua`: Windows 側の `~/.wezterm.lua` から repo 管理の設定を読み込むためのローダー

編集後は必ずリポジトリルートで反映スクリプトを実行する:

```sh
scripts/install-wezterm-config.sh
```

このスクリプトは `wezterm/*.lua` と `loader.lua` を Windows 側の WezTerm 設定へコピーする。反映確認は WezTerm を開き直すか設定をリロードして行う。

## フォーマット

`pkgs.nixfmt` (公式フォーマッタ)を導入済み。変更後はこれをかける:

```sh
nixfmt flake.nix home-manager/home.nix home-manager/*/default.nix
```

## ツール管理の棲み分け

詳細は [docs/tool-management.md](docs/tool-management.md) 参照。要約:

- **Nix (Home Manager)**: グローバルCLI(git, gh, mise, direnv, starship, jq, ripgrep など)
- **WezTerm**: Windows側ターミナルアプリ。設定実体は `wezterm/` で管理し、`scripts/install-wezterm-config.sh` で Windows 側へ反映する
- **mise**: Node, Go など言語ランタイムのバージョン管理(プロジェクト別の `.tool-versions` 対応)
- **corepack** (Node 同梱): pnpm, yarn のバージョン管理(`package.json` の `packageManager` フィールド)
- **direnv**: プロジェクト別の環境変数(`.envrc`)

Claude Code / codex / gemini などの AI CLI は **自己更新する**ため Nix 管理しない(read-only な Nix store と相性が悪い)。`~/.local/bin/claude` のような形で公式インストーラに任せる。

Rust の cargo/rustc は **rustup のまま**(rustup 自体が公式のバージョン管理機構なので)。

## 別マシンへの展開

[docs/setup.md](docs/setup.md) 参照。
