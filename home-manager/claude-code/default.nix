{ config, ... }:

{
  # attribution.commit / attribution.pr を空にし、コミットと PR の生成元表記を止める。
  # /config や herdr が書き戻すため working copy にリンクし、git diff で確認する。
  # ~/.claude/settings.local.json はユーザー全体には適用されないため、
  # 常に使うプラグイン等は settings.json に設定する。
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/claude-code/settings.json";
}
