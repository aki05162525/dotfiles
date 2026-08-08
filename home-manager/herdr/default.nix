{ config, pkgs, ... }:

{
  # herdr は通知音(内蔵 mp3)を paplay/pw-play/ffplay/mpg123/mpv に
  # shell out して再生する。WSL2 には mp3 対応プレイヤーが1つも
  # 入っていないため無音になる。WSLg の PulseAudio ブリッジ
  # (PULSE_SERVER=unix:/mnt/wslg/PulseServer) は存在するので、
  # 軽量な mpg123 を入れれば pulse 出力で鳴るようになる。
  home.packages = [ pkgs.mpg123 ];

  # herdr は onboarding フラグ等をこのファイル自身に書き戻すことがあるため、
  # (読み取り専用な nix store への symlink ではなく) working copy を直接指す
  # mkOutOfStoreSymlink にして書き込み可能にする。ai-skills と同じ理由。
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/herdr/config.toml";
}
