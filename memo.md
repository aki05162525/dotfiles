# TODO: モジュール分割の続き

## 完了

- [x] mise.nix を切り出し
- [x] direnv.nix を作成 + `programs.direnv` モジュールへリファクタ
- [x] starship.nix を切り出し
- [x] zellij.nix を切り出し
- [x] git.nix を作成 + `programs.git` (settings方式) へリファクタ
- [x] zsh.nix を切り出し
- [x] home.nix のテンプレコメントを掃除 + 未使用 `config` 引数を削除
- [x] uv / trufflehog を Nix 管理化
- [x] nixfmt で全 .nix ファイルをフォーマット

## 残タスク(やる気が出たら)

## 完了(2回目)

- [x] apt の重い未使用パッケージ整理(mysql, postgresql, qemu, openjdk-21, maven, context, byobu, yarn 等)
- [x] jq / ripgrep を Home Manager 管理に追加

## 注意

新しい `.nix` ファイルを追加したら必ず `git add` してから `home-manager switch`(flake は git tracked なファイルしか見ない)。
