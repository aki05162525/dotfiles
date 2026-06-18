# dotfiles

Home Manager (flake構成) で管理する個人 dotfiles。WSL2 (Ubuntu) と macOS (Apple Silicon) に対応。

## Docs

- [セットアップ手順](docs/setup.md)
- [ツール管理の役割分担](docs/tool-management.md)

## コマンド

```sh
# 設定の反映(新規 .nix は git add してから)
home-manager switch --flake .#akihiro@wsl   # WSL2
home-manager switch --flake .#takagi@mac    # macOS

# flake の更新
nix flake update

# フォーマット
nix fmt
```
