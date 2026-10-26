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

設定の変更後は `nix flake check` で実行中の OS 向け構成をビルド検証する。
WSL のコピー処理は `python3 tests/test_wezterm_activation.py` で検証できる(Nix / Bash / Python 3 が必要)。
テストは一時ディレクトリと Windows コマンドの代替を使うため、Windows 側の設定を変更しない。
