# TODO: モジュール分割の続き

## 完了

- [x] mise.nix を切り出し
- [x] direnv.nix を作成 + `programs.direnv` モジュールへリファクタ
- [x] starship.nix を切り出し
- [x] zellij.nix を切り出し
- [x] git.nix を作成 + `programs.git` (settings方式) へリファクタ

## 優先度低: zsh.nix

`programs.zsh` のブロックを別ファイルへ。

## 注意

新しい `.nix` ファイルを追加したら必ず `git add` してから `home-manager switch`(flake は git tracked なファイルしか見ない)。
