{ config, ... }:

{
  # herdr は onboarding フラグ等をこのファイル自身に書き戻すことがあるため、
  # (読み取り専用な nix store への symlink ではなく) working copy を直接指す
  # mkOutOfStoreSymlink にして書き込み可能にする。ai-skills と同じ理由。
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/herdr/config.toml";
}
