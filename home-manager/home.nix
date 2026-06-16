{ pkgs, lib, ... }:

{
  imports = [
    ./mise
    ./direnv
    ./fzf
    ./starship
    ./git
    ./zsh
  ];

  # username / homeDirectory は flake.nix で注入される

  # Home Manager のリリースバージョンに紐づくため、原則変更しない。
  # 変更する場合はリリースノートを参照すること。
  home.stateVersion = "25.11";

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
}
