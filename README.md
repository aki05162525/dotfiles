# dotfiles

WSL (Ubuntu) 上の Home Manager (flake構成) で管理する個人 dotfiles。

## Docs

- [新しいマシンでのセットアップ手順](docs/setup.md) — 別PCでこのdotfilesを使い始めるとき
- [ツール管理の役割分担](docs/tool-management.md) — Nix / mise / corepack / pnpm 等のレイヤー構造と責務

## 重要なコマンド

### 設定の反映

```sh
home-manager switch --flake .#akihiro@wsl   # WSL2 (Windows)
home-manager switch --flake .#takagi@mac   # macOS (Apple Silicon)
```

`home.nix` 配下の `.nix` ファイルを変更したらリポジトリルートで、マシンに対応する構成を指定して実行。

新規 `.nix` ファイルを追加した場合は **`git add` してから** switch すること(flake は git tracked なファイルしか見ない)。

### パッケージの更新

```sh
nix flake update nixpkgs
```

`flake.lock` が更新され、nixpkgs(各種パッケージのビルドレシピ)が最新になる。

```sh
nix flake update home-manager
```

`flake.lock` が更新され、Home Manager 本体のビルドレシピが最新になる。

更新後は `home-manager switch --flake .#akihiro@wsl`(mac は `.#takagi@mac`)で反映。

### Nix ファイルのフォーマット

```sh
nixfmt flake.nix home-manager/*.nix
```

公式フォーマッタでスタイル統一。
