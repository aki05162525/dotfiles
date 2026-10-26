{
  config,
  pkgs,
  lib,
  ...
}:

# eMudhra 中間CA の秘密鍵漏洩(2026-10)への対応(macOS 限定)。
#
# Determinate Nix は /etc/nix/nix.conf の ssl-cert-file に、macOS キーチェーンを
# 書き出した /etc/nix/macos-keychain.crt を指定する。PEM に書き出した時点で Apple 側の
# 失効情報は落ちるので、emSign ECC Root CA - G3 / AAA Certificate Services 配下の
# 偽造証明書を Nix (OpenSSL 系) が受け入れてしまう。シェルの NIX_SSL_CERT_FILE も
# Nix 本体付属の古い nss-cacert を指している。
#
# そこで nixpkgs の cacert (3.131.1 以降は G3 を含まず、AAA はサーバー認証の信頼を
# 外されている) を固定パスに置き、両方をそこへ向ける。固定パスにするのは、store パスを
# 直接書くと flake 更新や GC で壊れるため。home.file の symlink なら Home Manager の
# 世代が store パスを GC root として保持し、switch のたびに追従する。
#
# WSL2 はシステムストア (apt の ca-certificates) を使っていて問題がないので対象外。
lib.mkIf pkgs.stdenv.isDarwin {
  home.file.".local/share/nix-cacert/ca-bundle.crt".source =
    "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  # /etc/nix/nix.conf は `!include nix.custom.conf` より後ろで ssl-cert-file を
  # 設定しているので、nix.custom.conf に書いても上書きされる (nix.conf 自体は
  # Determinate Nix が置き換えるので編集できない)。ユーザー設定は /etc/nix/nix.conf の
  # 後に読まれるので、ここで指定すればクライアント側 (flake 入力や fetchurl の取得) に効く。
  # デーモン側は macos-keychain.crt のまま残るが、デーモンが取るのは署名検証される
  # バイナリキャッシュと、ハッシュ固定の fixed-output derivation なので影響しない。
  xdg.configFile."nix/nix.conf".text = ''
    ssl-cert-file = ${config.home.homeDirectory}/.local/share/nix-cacert/ca-bundle.crt
  '';

  # hm-session-vars は .zshenv で読まれ、/etc/zshrc の nix-daemon.sh は
  # 既に設定済みの NIX_SSL_CERT_FILE を上書きしない。
  home.sessionVariables.NIX_SSL_CERT_FILE = "$HOME/.local/share/nix-cacert/ca-bundle.crt";
}
