{ config, ... }:

let
  # repo の agents/ が全プロジェクト共通の指示の source of truth。
  # 正本は AGENTS.md の1ファイルで、Codex はそれを ~/.codex/AGENTS.md として直接読む。
  # Claude Code は AGENTS.md を読まないため、~/.claude/CLAUDE.md から
  # `@~/.codex/AGENTS.md` で import する(リポジトリの CLAUDE.md → @AGENTS.md と同じ形)。
  # Claude 固有の指示が要るときは agents/CLAUDE.md の import 行の下に足す。
  #
  # mkOutOfStoreSymlink で working copy を直接指すため、中身の編集は switch 不要で即反映される。
  agentsDir = "${config.home.homeDirectory}/dotfiles/agents";
in
{
  home.file.".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/AGENTS.md";
  home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/CLAUDE.md";
}
