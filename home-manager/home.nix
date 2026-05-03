{ pkgs, ... }:

{
  imports = [
    ./mise.nix
    ./direnv.nix
    ./starship.nix
    ./zellij.nix
    ./git.nix
    ./zsh.nix
  ];

  home.username = "akihiro";
  home.homeDirectory = "/home/akihiro";

  # Home Manager のリリースバージョンに紐づくため、原則変更しない。
  # 変更する場合はリリースノートを参照すること。
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    nixfmt
    gh
    uv
    trufflehog
  ];

  programs.home-manager.enable = true;
}
