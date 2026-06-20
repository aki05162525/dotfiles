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
  ];

  # username / homeDirectory は flake.nix で注入される

  # Home Manager のリリースバージョンに紐づくため、原則変更しない。
  # 変更する場合はリリースノートを参照すること。
  home.stateVersion = "25.11";

  # 自己更新する AI CLI 等を置く ~/.local/bin を PATH に通す。
  # hm-session-vars.sh 経由で全シェルから一貫して読まれる。
  home.sessionPath = [ "$HOME/.local/bin" ];

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
