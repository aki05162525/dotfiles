# TODO: モジュール分割の続き

## 完了

- [x] mise.nix を切り出し
- [x] direnv.nix を作成 + `programs.direnv` モジュールへリファクタ

## 優先度中: starship.nix を作成

```nix
# home-manager/starship.nix
{ ... }:
{
  programs.starship.enable = true;
  home.file.".config/starship.toml".source = ./starship.toml;
}
```

## 優先度中: zellij.nix を作成

```nix
# home-manager/zellij.nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.zellij ];
  home.file.".config/zellij/config.kdl".source = ./zellij/config.kdl;
}
```

## 優先度低: git.nix

`home.file.".gitconfig".source = ./git/.gitconfig;` のままモジュール分割するか、
それとも `programs.git` モジュールで宣言的に書き直すかを決めてから着手する。

## 優先度低: zsh.nix

`programs.zsh` のブロックを別ファイルへ。

## 注意

新しい `.nix` ファイルを追加したら必ず `git add` してから `home-manager switch`(flake は git tracked なファイルしか見ない)。
