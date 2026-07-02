{ pkgs, ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    # nixpkgs の mise は checkPhase で cargo test を走らせる(doCheck = true)ため、
    # rattler 等の重い dev-dependencies まで毎回コンパイルされてビルドが非常に遅くなる。
    # 日常使いのCLIとしてはテスト不要なので無効化する。
    package = pkgs.mise.overrideAttrs (_: {
      doCheck = false;
    });
    globalConfig = {
      tools = {
        node = "24";
        go = "1.26";
      };
    };
  };
}
