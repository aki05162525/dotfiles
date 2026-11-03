{ config, ... }:

let
  # 共通指示は agents/AGENTS.md で管理し、Codex へリンクする。
  # Claude Code は agents/CLAUDE.md の @~/.codex/AGENTS.md から読む。
  # Claude 固有の指示は import 行の下に追加する。
  # working copy へのリンクなので編集後の switch は不要。
  agentsDir = "${config.home.homeDirectory}/dotfiles/agents";
in
{
  home.file.".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/AGENTS.md";
  home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/CLAUDE.md";
}
