# dotfiles

WSL (Ubuntu) 上の Home Manager (flake構成) で管理する個人 dotfiles。

## ディレクトリ構成

```
dotfiles/
├─ flake.nix         # ルートに配置(エントリポイント)
├─ flake.lock
└─ home-manager/
   ├─ home.nix       # メインの設定。ツール別の .nix を imports する
   ├─ mise.nix       # ツール別モジュール
   ├─ starship.toml
   ├─ git/.gitconfig
   └─ zellij/config.kdl
```

## 設定ファイル分割の方針

ツールごとの設定は `home-manager/<tool>.nix` に分割し、`home.nix` の `imports` で取り込む。

```nix
# home.nix
{ config, pkgs, ... }:
{
  imports = [
    ./mise.nix
    ./direnv.nix
    # ...
  ];

  # 共通設定はここに残す(home.username, home.stateVersion, etc.)
}
```

各モジュールは独立した Nix モジュールとして書く:

```nix
# mise.nix
{ ... }:    # pkgs を使わないモジュールは { ... }: でOK
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig.tools.node = "22";
  };
}
```

`pkgs` を参照する場合は `{ pkgs, ... }:` と明示する。

## 適用コマンド

リポジトリルートで:

```sh
home-manager switch --flake .#akihiro
```

新規 `.nix` ファイルを追加した場合は、Nix flake の仕様上 git に tracked されていないファイルは見えないので、必ず `git add` してから switch すること。

## ツール管理の棲み分け

- **Nix (Home Manager)**: グローバルCLI(git, mise, direnv, starship, zellij など)
- **mise**: Node など言語ランタイムのバージョン管理(プロジェクト別の `.tool-versions` 対応)
- **direnv**: プロジェクト別の環境変数

Claude Code / codex / gemini などの AI CLI は自己更新するため Nix 管理しない。
