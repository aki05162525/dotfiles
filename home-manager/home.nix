{
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [
    ./mise
    ./direnv
    ./fzf
    ./starship
    ./git
    ./zsh
    ./wezterm
    ./ai-instructions
    ./herdr
    ./claude-code
    ./cacert
  ];

  # username / homeDirectory は flake.nix で注入される

  # Home Manager のリリースバージョンに紐づくため、原則変更しない。
  # 変更する場合はリリースノートを参照すること。
  home.stateVersion = "25.11";

  # ~/.local/bin の自己更新 CLI と mise の shims を全シェルの PATH に追加する。
  # mise activate は対話シェル専用。shims がないと非対話の git hook で
  # node/pnpm が見つからないため、hm-session-vars.sh 経由で設定する。
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/mise/shims"
  ];

  home.sessionVariables = {
    # 既定の ~/go ではなく XDG データディレクトリにキャッシュ等を置く。
    GOPATH = "$HOME/.local/share/go";
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    # xdg-open から Windows 既定ブラウザを開く。wsl-open は home.packages で導入する。
    BROWSER = "wsl-open";
  };

  # OS 共通のパッケージ。OS 依存のものは lib.optionals で足す。
  home.packages =
    with pkgs;
    [
      nixfmt
      gh
      awscli2
      uv
      trufflehog
      jq
      ripgrep
      supabase-cli
      _1password-cli

      # ローカル git hook(lefthook)とその検査ツール群。
      # 詳細は repo root の lefthook.yml を参照。
      lefthook
      shellcheck
      stylua
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      net-tools # Linux 専用(Darwin では別系統のためここに置かない)
      wsl-open # WSL2: xdg-open から Windows 既定ブラウザを開く(wslu は discontinued のため代替)
    ];

  programs.home-manager.enable = true;

  # switch 時に dotfiles の git hook を登録する。lefthook install は冪等。
  home.activation.lefthookInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
      export PATH="${pkgs.git}/bin:$PATH"
      dotfiles_dir="${config.home.homeDirectory}/dotfiles"
      if [ -d "$dotfiles_dir/.git" ]; then
        cd "$dotfiles_dir"
        run ${pkgs.lefthook}/bin/lefthook install
      fi
    )
  '';
}
