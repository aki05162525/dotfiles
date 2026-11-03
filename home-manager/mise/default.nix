{ ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    # 標準パッケージを使い、nixpkgs のバイナリキャッシュを利用できるようにする。
    # doCheck などを上書きすると別の derivation になり、独自ビルドが必要になり得る。
    globalConfig = {
      tools = {
        node = "24";
        go = "1.26";
        # macOS 同梱の Python 3.9 では pip の要求(>=3.10)を満たせないため mise で管理する。
        python = "3.14";
      };
      # Node 更新後も pnpm / yarn を使えるよう、インストールごとに corepack を有効化する。
      settings.node.corepack = true;
    };
  };
}
