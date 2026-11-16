{ config, ... }:

{
  # Zed は UI の設定変更を settings.json に書き戻すため working copy にリンクし、git diff で確認する。
  xdg.configFile."zed/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/zed/settings.json";
}
