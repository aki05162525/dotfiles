{ lib, config, ... }:

let
  # repo の skills/ が source of truth。Claude Code / Codex は同じ
  # Agent Skills 形式(<name>/SKILL.md)なので、1つの実体を両方へ見せる。
  #
  # ディレクトリ丸ごとではなく skill 単位で symlink する:
  #   - ~/.codex/skills/ には公式同梱の .system が同居している
  #   - マシンローカルの skill を直置きする余地を残す
  #
  # mkOutOfStoreSymlink で working copy を直接指すため、SKILL.md の編集は
  # switch 不要で即反映される。switch が必要なのは skill の追加・削除時のみ
  # (新規追加時は git add を忘れずに。flake は git tracked なファイルしか見ない)。
  skillsRepoDir = "${config.home.homeDirectory}/dotfiles/skills";
  skillNames = lib.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../skills)
  );
  mkLinks =
    base:
    lib.listToAttrs (
      map (name: {
        name = "${base}/${name}";
        value.source = config.lib.file.mkOutOfStoreSymlink "${skillsRepoDir}/${name}";
      }) skillNames
    );
in
{
  home.file = mkLinks ".claude/skills" // mkLinks ".codex/skills";
}
