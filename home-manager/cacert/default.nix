{ pkgs, lib, ... }:

# eMudhra 中間CA の秘密鍵漏洩(2026-10)への対応(macOS 限定)。
#
# シェルの NIX_SSL_CERT_FILE は、Nix 本体付属のプロファイル
# (/nix/var/nix/profiles/default) の nss-cacert を指す。これは Determinate Nix を
# 3.24.1 に上げても 3.121 のままで、emSign ECC Root CA - G3 を含む。nixpkgs 由来の
# OpenSSL 系ツールがこれを使うので、nixpkgs の cacert (3.131.1 以降は G3 を含まず、
# AAA はサーバー認証の信頼を外されている) に向け直す。
#
# 固定パスに置くのは、store パスを直接書くと flake 更新や GC で壊れるため。home.file の
# symlink なら Home Manager の世代が store パスを GC root として保持し、switch のたびに追従する。
#
# Nix 本体の ssl-cert-file (/etc/nix/macos-keychain.crt) は Determinate Nix 3.24.0 で
# 修正済みなので上書きしない。上書きするとキーチェーンの MDM 証明書なども外れてしまう。
#
# WSL2 はシステムストア (apt の ca-certificates) を使っていて問題がないので対象外。
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.file.".local/share/nix-cacert/ca-bundle.crt".source =
    "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  # hm-session-vars は .zshenv で読まれ、/etc/zshrc の nix-daemon.sh は
  # 既に設定済みの NIX_SSL_CERT_FILE を上書きしない。
  home.sessionVariables.NIX_SSL_CERT_FILE = "$HOME/.local/share/nix-cacert/ca-bundle.crt";
}
