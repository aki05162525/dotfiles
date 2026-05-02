# TODO: モジュール分割の続き

## 優先度高: direnv.nix を作成 + リファクタ

現状は `home.packages` に `direnv` / `nix-direnv` を入れて、`programs.zsh.initContent` で手動で `eval "$(direnv hook zsh)"` している。
`programs.direnv` モジュールを使えば一気にきれいになる。

```nix
# home-manager/direnv.nix
{ ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
```

合わせて `home.nix` から:
- `home.packages` の `direnv`, `nix-direnv` を削除
- `programs.zsh.initContent` の `eval "$(direnv hook zsh)"` を削除(空になればブロックごと消してOK)
- `imports` に `./direnv.nix` を追加

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

direnv を切り出した後、`programs.zsh` のブロックを別ファイルへ。

## 注意

新しい `.nix` ファイルを追加したら必ず `git add` してから `home-manager switch`(flake は git tracked なファイルしか見ない)。
