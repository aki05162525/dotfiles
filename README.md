# dotfiles

WSL (Ubuntu) 上の Home Manager (flake構成) で管理する個人 dotfiles。

## Docs

- [ツール管理の役割分担](docs/tool-management.md) — Nix / mise / corepack / pnpm 等のレイヤー構造と責務

## 重要なコマンド

### 設定の反映

```sh
home-manager switch --flake .#akihiro
```

`home.nix` 配下の `.nix` ファイルを変更したらリポジトリルートで実行。

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

更新後は `home-manager switch --flake .#akihiro` で反映。

### Nix ファイルのフォーマット

```sh
nixfmt flake.nix home-manager/*.nix
```

公式フォーマッタでスタイル統一。
