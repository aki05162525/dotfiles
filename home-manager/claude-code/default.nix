{ config, ... }:

{
  # Claude Code の user settings。`attribution: false` で
  # Co-Authored-By / "Generated with Claude Code" を全リポジトリで止める
  # (旧 `includeCoAuthoredBy` は deprecated)。
  #
  # Claude Code 自身(/config)や herdr の integration install が
  # このファイルに書き戻すため、読み取り専用な nix store への symlink ではなく
  # working copy を直接指す mkOutOfStoreSymlink にする(herdr / ai-skills と同じ理由)。
  # 書き戻しは repo の git diff として見えるので、意図しない変更に気付ける。
  #
  # ~/.claude/settings.local.json はユーザー全体の設定としては読まれない
  # (~ で起動したときのプロジェクトローカル扱い)ので、
  # プラグイン等の常に効かせたい設定はこのファイルに書くこと。
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/claude-code/settings.json";
}
