{ config, pkgs, ... }:

{
  # herdr の通知音(mp3)を WSLg の PulseAudio ブリッジで再生するため mpg123 を入れる。
  home.packages = [ pkgs.mpg123 ];

  # herdr が onboarding フラグ等を書き戻すことがあるため working copy にリンクする。
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/herdr/config.toml";
}
