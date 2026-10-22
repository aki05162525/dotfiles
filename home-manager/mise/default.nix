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
        # macOS 同梱の Python は 3.9 系で、pip を要求バージョン(>=3.10 必須)へ
        # 上げられない。Python も mise 管理に寄せてシステム Python を使わない。
        python = "3.14";
      };
      # pnpm / yarn は corepack に任せる(docs/tool-management.md)。
      # corepack enable は Node のインストール単位で効くため、Node を上げるたびに
      # pnpm シムが消える。インストール時に mise が自動で有効化するようにする。
      settings.node.corepack = true;
    };
  };
}
