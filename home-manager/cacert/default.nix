{ pkgs, lib, ... }:

# eMudhra 中間CA の秘密鍵漏洩(2026-10)への対応。詳細は docs/emudhra-ca-incident.md。
# macOS の NIX_SSL_CERT_FILE は Determinate Nix 3.24.1 でも古い nss-cacert 3.121 を
# 指すため、G3 を含まず AAA のサーバー認証を信頼しない nixpkgs の cacert に変更する。
# home.file で GC root を保持し、switch で更新する。store パスは直接固定しない。
# Nix 本体の ssl-cert-file は 3.24.0 で修正済み。MDM 証明書を除外しないよう上書きしない。
# WSL2 は更新済みのシステムストアを使うため対象外。
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.file.".local/share/nix-cacert/ca-bundle.crt".source =
    "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  # hm-session-vars は .zshenv で読まれ、/etc/zshrc の nix-daemon.sh は
  # 既に設定済みの NIX_SSL_CERT_FILE を上書きしない。
  home.sessionVariables.NIX_SSL_CERT_FILE = "$HOME/.local/share/nix-cacert/ca-bundle.crt";
}
