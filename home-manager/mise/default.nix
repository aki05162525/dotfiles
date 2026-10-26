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
