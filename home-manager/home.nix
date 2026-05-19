{ pkgs, ... }:

{
  imports = [
    ./mise
    ./direnv
    ./starship
    ./zellij
    ./git
    ./zsh
  ];

  # username / homeDirectory は flake.nix で注入される

  # Home Manager のリリースバージョンに紐づくため、原則変更しない。
  # 変更する場合はリリースノートを参照すること。
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    nixfmt
    gh
    uv
    trufflehog
    jq
    ripgrep
    supabase-cli
    net-tools
  ];

  programs.home-manager.enable = true;
}
