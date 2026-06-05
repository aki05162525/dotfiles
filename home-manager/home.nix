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
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      net-tools # Linux 専用(Darwin では別系統のためここに置かない)
    ];

  programs.home-manager.enable = true;
}
