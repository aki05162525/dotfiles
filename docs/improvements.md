# 改善点まとめ

レビュー日: 2026-06-16

この dotfiles リポジトリを、Nix/Home Manager、WezTerm、セットアップ手順、日常運用の観点で確認した改善候補。
優先度は「効果」「事故防止」「対応コスト」を見て付けている。

検証方針: 個人用の単独運用リポジトリのため、CI(GitHub Actions)は導入せず、検査は lefthook によるローカル git hook に寄せる。

## 確認したこと

- `homeConfigurations.akihiro@wsl` の activation package は現環境で評価可能だった(drvPath 生成を確認)。
- `homeConfigurations.takagi@mac` は Linux 上では incompatible system として評価対象外。
- `nix fmt` は `formatter.x86_64-linux` が未定義のため失敗した。
- `shellcheck` と `stylua` は現在の PATH には無かった。
- `.github/workflows/` と `LICENSE` は存在しなかった(CI は今回は入れない方針)。

## 優先度: 高

> 高優先度の #1〜#3 は 2026-06-16 に対応済み(コミット `6608c07`)。各項目末尾の「対応済み」を参照。

### 1. `nix fmt` を使えるようにする

対象: `flake.nix`, `README.md`, `CLAUDE.md`

現状は `flake.nix` に `formatter.<system>` が無いため、`nix fmt` が失敗する。
手動で `nixfmt flake.nix home-manager/home.nix home-manager/*/default.nix` を実行する運用になっているが、対象ファイルが増えると漏れやすい。

対応案:

```nix
formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
```

あわせて README/CLAUDE のフォーマット手順を `nix fmt` に寄せる。

**対応済み (2026-06-16):** `flake.nix` に `formatter.x86_64-linux` / `formatter.aarch64-darwin` を追加し `nix fmt` を有効化した。`nixfmt-rfc-style` は「`pkgs.nixfmt` と同一なので後者を使え」という警告が出たため、`home.packages` と揃えて `nixfmt` を指定した。

### 2. README のフォーマットコマンドがサブディレクトリを取りこぼす

対象: `README.md`

README の例は次の形になっている。

```sh
nixfmt flake.nix home-manager/*.nix
```

実際の Nix モジュールは `home-manager/<tool>/default.nix` に分かれているため、このコマンドでは `home-manager/direnv/default.nix` などが整形対象から漏れる。

対応案:

```sh
nixfmt flake.nix home-manager/home.nix home-manager/*/default.nix
```

ただし #1 を入れるなら、最終的には `nix fmt` だけを案内するのがよい。

**対応済み (2026-06-16):** #1 とあわせて README / CLAUDE の手順を `nix fmt` に統一した(特定ファイルのみ整形したい場合の `nixfmt <file>...` も併記)。

### 3. lefthook でローカルの検査を回す

対象: `home-manager/home.nix`, `lefthook.yml`(新規), `docs/setup.md`

CI は導入しない方針のため、フォーマット・静的解析を lefthook の git hook に集約する。
個人用 dotfiles では常設のシークレットスキャンは重くなりやすいため、trufflehog は hook には入れず、必要なときだけ手動実行する方針にする。

導入手順:

- `home.packages` に `lefthook`, `shellcheck`, `stylua` を追加する。
- リポジトリ root に `lefthook.yml` を置く。
- 初回だけ `lefthook install` で `.git/hooks` に注入する(`docs/setup.md` のポストセットアップに1行追加)。

速い検査と重い検査を段階で分けるのが要点:

```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    nixfmt:
      glob: "*.nix"
      run: nixfmt --check {staged_files}
    shellcheck:
      glob: "*.sh"
      run: shellcheck {staged_files}
    stylua:
      glob: "*.lua"
      run: stylua --check {staged_files}

pre-push:
  commands:
    flake-check:
      run: nix flake check
```

- **pre-commit**: nixfmt / shellcheck / stylua(差分ファイル対象で速い検査)。
- **pre-push**: `nix flake check`(重いので push 時だけ)。

秘密情報対策は、常設 hook ではなく `.gitignore` と運用ルールで守る。
必要になったときだけ手動で `trufflehog filesystem --no-update .` を実行する。

`install-wezterm-config.sh` は WSL/macOS 分岐や Windows パス変換を担い壊れると初回セットアップで詰まるため、shellcheck の対象に含める価値が高い。WezTerm Lua も分割が進んでいるので stylua でフォーマットを揃える。

**対応済み (2026-06-16):**

- `home.packages` に `lefthook` / `shellcheck` / `stylua` を追加。
- repo root に `lefthook.yml`(pre-commit: nixfmt/shellcheck/stylua、pre-push: `nix flake check`)を作成。
- stylua のデフォルトはタブ字下げで既存 Lua(2スペース)と衝突するため、`stylua.toml`(Spaces / width 2)を追加し、追跡対象の Lua を一度フォーマットしてベースラインを揃えた。
- `docs/setup.md` のポストセットアップに `lefthook install`(初回のみ)を追記。
- `home-manager switch` と `lefthook install` を実行済み。コミット `6608c07` の pre-commit / pre-push フックが実際に発火することも確認した。

## 優先度: 中

### 4. macOS 構成の検証経路を作る

対象: `flake.nix`, `docs/setup.md`

`takagi@mac` は `aarch64-darwin` として定義されているが、Linux 環境では評価対象外になる。
CI は入れない方針なので、検証は実機に依存する。

対応案:

- setup 手順に「macOS で実際に検証したコマンド/日付」を明記する。
- mac 実機で `home-manager switch --flake .#takagi@mac` が通ることを一度確認し、結果を残す。
- OS 差分が増えたら `home-manager/home.nix` から host/platform 別モジュールへ分ける。

### 5. Git の日常設定をもう少し宣言的にする

対象: `home-manager/git/default.nix`

現在は user、credential、autocrlf、defaultBranch が中心。
日常的に効く設定を Home Manager 側へ寄せると、新しいマシンでも挙動が揃う。

候補:

```nix
pull.rebase = true;
push.autoSetupRemote = true;
push.default = "simple";
fetch.prune = true;
rerere.enabled = true;
```

必要なら `programs.git.aliases` で頻出コマンドもまとめる。

### 6. 共通環境変数を定義する

対象: `home-manager/home.nix` または `home-manager/zsh/default.nix`

`EDITOR` / `VISUAL` / `PAGER` などが未定義で、git commit や各種 CLI の挙動が環境依存になりやすい。

対応案:

```nix
home.sessionVariables = {
  EDITOR = "vim";
  VISUAL = "vim";
  PAGER = "less";
};
```

※ エディタは実際にインストール済み・PATH にあるコマンドを指定すること(未導入の `nvim` 等を指すと逆に壊れる)。
Nix 管理したいなら `home.packages` への追加とセットにする。

### 7. CLI 体験を強化するツールを追加する(任意・好みの領域)

対象: `home-manager/home.nix`, `home-manager/zsh/default.nix`

`ripgrep`, `fzf`, `jq` は入っているが、よく一緒に使われるモダン CLI はまだ少ない。改善というより好みの範囲。

候補:

- `zoxide`: `cd` 強化。Home Manager の zsh integration あり。
- `fd`: `find` 代替。`fzf` と相性がよい。
- `bat`: `cat`/preview 用。
- `eza`: `ls` 代替。

追加する場合は、`shellAliases` もセットで整理すると使いやすい。

## 優先度: 低

### 8. CLAUDE.md の内容を現状に合わせる

対象: `CLAUDE.md`

以下に軽いドリフトがある。

- mise の例が `node = "22"` だが、実際は `home-manager/mise/default.nix` で `node = "24"` と `go = "1.26"`。
- ディレクトリ構成図で `wezterm/` と `scripts/` が `home-manager/` の配下に見えるインデントになっている。
- WezTerm の説明に「Windows側へコピー」とあるが、現在は直接参照または symlink 運用。

対応案: 自動化より先に、今の実装に合わせて記述だけ直す。

**対応済み (2026-06-16):** 上記3点を修正(mise の例を `node = "24"` / `go = "1.26"` に、ディレクトリ構成図のインデントを修正し `wezterm/` `scripts/` を `home-manager/` と同階層に、WezTerm の説明を「各 OS から直接参照(コピーはしない)」に)。あわせて構成図に `lefthook.yml` / `stylua.toml` を追記した。

### 9. `.gitignore` の意図を整理する

対象: `.gitignore`, `home-manager/git/default.nix`

`setting.json` は `settings.json` の typo か、特定ツールのファイル名かが判断しづらい。
また、`.claude/settings.local.json` はリポジトリの `.gitignore` と git global ignore(`programs.git.ignores`)の両方に出てくる。

対応案:

- `setting.json` の意図を確認し、不要なら削除する。
- VS Code 用なら `.vscode/` だけで足りるか確認する。
- プロジェクト固有 ignore とグローバル ignore の役割を分ける。

### 10. WezTerm workspace 読み込みエラーをログに出す

対象: `wezterm/workspace.lua`

`workspace.local.lua` の読み込みは `pcall(dofile, ...)` で落ちないようになっている。
ただし `pcall` 失敗時(`workspace.lua` の `if not ok then return {}`)はログを出さずに `{}` を返すため、構文エラーやパス間違いも「workspace 一覧が出ない」だけに見える。

対応案:

- `pcall` 失敗時に `wezterm.log_warn` でエラー内容を出す。
- table ではない場合だけでなく、workspace entry の `name`/`cwd` 不備も警告できるようにする。

### 11. LICENSE を追加する

対象: `LICENSE`

公開 GitHub リポジトリとして使うなら、再利用可否が明確になる。
完全な個人用途なら必須ではない。

候補:

- MIT: 再利用を広く許可する。
- Unlicense: 権利主張をほぼしない。
- ライセンス無し: 個人用として明示的に再利用を許可しない。

## 着手順の提案

1. ~~`formatter` を flake に追加して `nix fmt` を有効化する(#1)。~~ ✅ 2026-06-16 対応済み
2. README/CLAUDE の古い手順と実装差分を直す(#2 ✅ / #8 ✅、いずれも 2026-06-16 対応済み)。
3. ~~lefthook を導入し、nixfmt / shellcheck / stylua / flake check をローカル hook に集約する(#3)。~~ ✅ 2026-06-16 対応済み
4. Git、環境変数、CLI 追加などの日常設定を整える(#5, #6, #7)。← 次はここから

## 対応履歴

- 2026-06-16: 高優先度 #1〜#3 を対応(コミット `6608c07`)。`nix fmt` 有効化、ドキュメントの手順統一、lefthook + shellcheck/stylua のローカル hook 集約。
- 2026-06-16: #8(CLAUDE.md のドリフト)を対応。mise バージョン例・ディレクトリ構成図・WezTerm の運用説明を現状に合わせ、構成図に `lefthook.yml` / `stylua.toml` を追記。
