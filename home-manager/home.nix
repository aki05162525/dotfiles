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
    ./ai-skills
    ./herdr
  ];

  # username / homeDirectory は flake.nix で注入される

  # Home Manager のリリースバージョンに紐づくため、原則変更しない。
  # 変更する場合はリリースノートを参照すること。
  home.stateVersion = "25.11";

  # 自己更新する AI CLI 等を置く ~/.local/bin を PATH に通す。
  # hm-session-vars.sh 経由で全シェルから一貫して読まれる。
  #
  # mise の shims も同様にここへ通す。`programs.mise.enableZshIntegration` の
  # `mise activate zsh` は対話シェルの .zshrc でしか読まれず、husky 等が
  # git hook を非対話シェルで実行すると mise 管理下の node/pnpm が PATH に
  # 乗らず "pnpm: command not found" で失敗する。shims 経由なら非対話シェルでも動く。
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/mise/shims"
  ];

  home.sessionVariables = {
    # 未設定だと go が $HOME/go を GOPATH として使い、ホーム直下に go/
    # (モジュールキャッシュ等)が散らかる。XDG データディレクトリ配下へ逃がす。
    GOPATH = "$HOME/.local/share/go";
  }
  // lib.optionalAttrs pkgs.stdenv.isLinux {
    # WSL2: BROWSER を設定すると xdg-open がこれを最優先で使うため、
    # Linux 側の chromium 等へフォールバックせず常に Windows 既定ブラウザが開く
    # (wsl-open は下の home.packages が提供。wslu は discontinued のため使わない)。
    BROWSER = "wsl-open";
  };

  # OS 共通のパッケージ。OS 依存のものは lib.optionals で足す。
  home.packages =
    with pkgs;
    [
      nixfmt
      gh
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
    ++ lib.optionals pkgs.stdenv.isLinux [
      net-tools # Linux 専用(Darwin では別系統のためここに置かない)
      wsl-open # WSL2: xdg-open から Windows 既定ブラウザを開く(wslu は discontinued のため代替)
    ];

  programs.home-manager.enable = true;

  # dotfiles リポジトリの lefthook git hook を自動注入する。
  # switch のたびに実行されるが lefthook install は冪等なので問題ない。
  home.activation.lefthookInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.git}/bin:$PATH"
    dotfiles_dir="${config.home.homeDirectory}/dotfiles"
    if [ -d "$dotfiles_dir/.git" ]; then
      cd "$dotfiles_dir"
      run ${pkgs.lefthook}/bin/lefthook install
    fi
  '';
}
