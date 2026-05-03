{ pkgs, ... }:

{
  home.packages = [ pkgs.zellij ];
  home.file.".config/zellij/config.kdl".source = ./zellij/config.kdl;
}
