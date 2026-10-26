{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
    };
    shellAliases = {
      ll = "ls -la";
      g = "git";
    };
    # eMudhra 中間CA の秘密鍵漏洩(2026-10)への対応。
    # macOS 同梱の curl は MultiSSL ビルドで既定バックエンドが LibreSSL なので、
    # 失効情報を見ない静的バンドル /etc/ssl/cert.pem を参照し、漏洩鍵で偽造された
    # 証明書を受け入れてしまう。SecureTransport なら Apple 側の失効判定が効く。
    # Apple が cert.pem を更新しても、AAA Certificate Services 経由のクロス署名
    # 経路は静的バンドルでは原理的に塞げないため、恒久的にこちらを既定にする。
    # 非対話シェルから呼ばれる curl にも効かせたいので .zshrc ではなく .zshenv に置く。
    # WSL の curl には secure-transport バックエンドが無いので macOS 限定。
    envExtra = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      export CURL_SSL_BACKEND=secure-transport
    '';

    initContent = ''
      if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
        function _wezterm_osc7_pwd() {
          printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"
        }
        precmd_functions+=(_wezterm_osc7_pwd)
      fi

      function hms() {
        if [[ "$(uname)" == "Darwin" ]]; then
          home-manager switch --flake "$HOME/dotfiles#takagi@mac" "$@"
        else
          home-manager switch --flake "$HOME/dotfiles#akihiro@wsl" "$@"
        fi
      }
    '';
    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];
  };
}
