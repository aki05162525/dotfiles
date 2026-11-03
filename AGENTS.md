# dotfiles

WSL2 (Ubuntu) と macOS (Apple Silicon) 両対応の Home Manager (flake構成) で管理する個人 dotfiles。

## ディレクトリ構成

```
dotfiles/
├─ flake.nix              # ルートに配置(エントリポイント)
├─ flake.lock
├─ README.md
├─ AGENTS.md
├─ memo.md                # 作業中のTODOメモ(git 管理外、任意)
├─ lefthook.yml           # ローカル git hook(pre-commit)
├─ stylua.toml            # Lua フォーマッタ設定(2スペース字下げ)
├─ tests/
│  └─ test_wezterm_activation.py # Windows 側に書き込まない activation の回帰テスト
├─ docs/
│  ├─ setup.md            # 別マシンでのセットアップ手順
│  ├─ tool-management.md  # Nix / mise / corepack 等のレイヤー構造
│  └─ emudhra-ca-incident.md # eMudhra 中間CA 漏洩(2026-10)の対応手順
├─ agents/                # 全プロジェクト共通の AI CLI 指示(実体)
│  ├─ AGENTS.md           # 正本(~/.codex/AGENTS.md)
│  └─ CLAUDE.md           # @~/.codex/AGENTS.md を import(~/.claude/CLAUDE.md)
├─ apm/                   # 全プロジェクト共通スキルの導入設定
│  ├─ apm.yml
│  └─ apm.lock.yaml
├─ home-manager/
│  ├─ home.nix            # エントリ。ツール別モジュールを imports
│  ├─ ai-instructions/default.nix  # agents/ を ~/.codex/AGENTS.md と ~/.claude/CLAUDE.md へ symlink
│  ├─ claude-code/        # ~/.claude/settings.json の実体
│  ├─ herdr/
│  ├─ cacert/
│  ├─ direnv/default.nix
│  ├─ fzf/default.nix
│  ├─ git/default.nix
│  ├─ mise/default.nix
│  ├─ zsh/default.nix
│  ├─ starship/
│  │  ├─ default.nix
│  │  └─ starship.toml
│  ├─ wezterm/default.nix # WezTerm 反映(macOS symlink / WSL2 コピー activation)
│  └─ ...
├─ wezterm/               # WezTerm 設定の実体(switch で各 OS へ反映)
│  ├─ wezterm.lua
│  ├─ appearance.lua
│  ├─ keys.lua
│  ├─ platform.lua
│  ├─ workspace.lua
│  ├─ workspace.local.lua.example
│  └─ loader.lua
└─ (scripts なし: WezTerm の Windows 側反映は home-manager switch に統合済み)
```

## 設定ファイル分割の方針

**ツールごとに `home-manager/<tool>/default.nix` のフォルダ構成**で分割し、`home.nix` の `imports` で取り込む。フォルダ名だけで `default.nix` が自動的に読まれる。

```nix
# home.nix
{ pkgs, ... }:
{
  imports = [
    ./mise
    ./direnv
    ./fzf
    ./starship
    ./git
    ./zsh
  ];

  # 共通設定はここに残す(home.username, home.stateVersion, home.packages 等)
}
```

各モジュールは独立した Nix モジュールとして書く:

```nix
# mise/default.nix
{ ... }:    # pkgs を使わないモジュールは { ... }: でOK
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig.tools = {
      node = "24";
      go = "1.26";
    };
  };
}
```

`pkgs` を参照する場合は `{ pkgs, ... }:` と明示する。**未使用引数は書かない**(例: `config` を使わないなら `{ pkgs, ... }:`)。

設定ファイル(`.toml` 等)を持つツールはフォルダ内に同居させ、`./<filename>` で参照する。

## 適用コマンド

リポジトリルートで、マシンに対応する構成を指定する:

```sh
home-manager switch --flake .#akihiro@wsl   # WSL2 (Windows)
home-manager switch --flake .#takagi@mac   # macOS (Apple Silicon)
```

ホスト別の構成は `flake.nix` の `homeConfigurations` で定義している。
新しいマシンを足すときは `"<username>@<host>" = mkHome { system = ...; username = ...; };` を1行追加する(homeDirectory は OS から自動導出)。

**新規 `.nix` ファイルを追加した場合は必ず `git add` してから switch する**こと(Nix flake は git tracked なファイルしか見ない)。

## WezTerm 設定の更新手順

WezTerm は Windows 側アプリだが、設定実体はこのリポジトリの `wezterm/` で管理し、**`home-manager switch` で各 OS へ反映**する(専用スクリプトは廃止)。リポジトリが常に source of truth で、Windows 側に古いコピーが置き去りになるドリフトを防ぐ。

- **WSL2 (Windows)**: `home-manager/wezterm/default.nix` の `weztermWslConfig` activation が、`switch` のたびに `wezterm/*.lua` を Windows 側 `%USERPROFILE%\.config\wezterm` へミラーコピーし、エントリ `~/.wezterm.lua` をそこへ向ける(`\\wsl.localhost` 越しの直接参照は遅い・たまに不安定なためコピー方式)。
- **macOS**: `~/.config/wezterm` をリポジトリの `wezterm/` へ symlink する(`home-manager/wezterm/default.nix` の `home.file`。symlink なので常に同期)。

どちらも `switch` 後に追加作業は不要で、`wezterm/*.lua` を編集したら **WSL は `home-manager switch` でコピーを更新 → WezTerm をリロード(Ctrl+Shift+R)、macOS はリロードのみ**で反映される。

`wezterm/` の役割:

- `wezterm.lua`: エントリポイント。各設定モジュールを読み込む
- `appearance.lua`: 配色、透過、フォントなど見た目の設定
- `keys.lua`: キーバインド
- `platform.lua`: Windows / WSL など環境依存の設定
- `workspace.lua`: workspace 切り替えの共通ロジック
- `workspace.local.lua`: PC ごとの workspace 一覧。git 管理しない
- `workspace.local.lua.example`: `workspace.local.lua` のサンプル
- `loader.lua`: Windows 側 `~/.wezterm.lua` の本体。WSL2 で activation が先頭に `WEZTERM_DOTFILES_CONFIG_DIR`(コピー先 `%USERPROFILE%/.config/wezterm`)を書き足して生成する

WSL2 の `weztermWslConfig` activation の挙動と安全策:

- WSL ランタイム判定(`/proc/version`)でガードし、非 WSL の Linux と macOS では何もしない。
- Windows ホームは取得と変換の成功を確認し、空文字や相対パス、存在しないディレクトリならコピーをスキップする。
- dry-run ではコピー先の作成、更新、削除と bootstrap の生成を行わない。
- `wezterm/*.lua`(`loader.lua` と `*.example` は除く)を `%USERPROFILE%\.config\wezterm` へコピーし、内容が同じファイルは書き込まない(`cmp` で冪等)。
- `~/.wezterm.lua` は dotfiles 生成物(`WEZTERM_DOTFILES_CONFIG_DIR` 署名を含むファイル)のときだけ更新し、手書きの無関係なファイルは上書きしない。
- activation は最小 PATH で走るため、`wslpath` / `cmd.exe` は絶対パスで呼ぶ。

`workspace.local.lua`(PC ごとの workspace、git 管理外)も `wezterm/` に置けばコピー対象になる。`switch` のたびにコピーが最新化されるので、Windows 側を直接いじる必要はない。

## Claude Code の設定

`~/.claude/settings.json` は `home-manager/claude-code/settings.json` を source of truth にして `mkOutOfStoreSymlink` で貼る(herdr と同じく、ツール自身が書き戻すため working copy を直接指す)。

- Claude Code 自身(`/config`)や herdr の integration install がこのファイルへ書き戻すので、変更は repo の `git diff` として現れる。意図しない書き戻しに気付けるのが利点。
- `attribution.commit` と `attribution.pr` を空文字にしてコミットの `Co-Authored-By` と PR の "Generated with Claude Code" を全リポジトリで止めている(旧 `includeCoAuthoredBy` は deprecated)。
- hook のコマンドはマシン間で共有するため絶対パスを書かず `$HOME` 経由にする。
- `model` / `effortLevel` / `autoCompactWindow` / `modelSettings` は書かず、公式の既定値に任せる。未設定ならプランの推奨モデルに追従し、effort と自動圧縮の閾値もモデルごとに調整された値になる。固定するとモデル更新時に推奨から外れる。コンテキストは公式ベストプラクティスどおり `/clear`(タスクの切り替え時)と `/compact <指示>` で管理する。
- `/effort` や `/autocompact` はセッション中の調整用。これらは `modelSettings` にモデル名単位で書き戻すが、共有設定には取り込まない(差分が出たら破棄する)。
- `~/.claude/settings.local.json` はユーザー全体の設定としては読まれない(`~` で起動したときのプロジェクトローカル扱い)。`enabledPlugins` など常に効かせたい設定は `settings.json` 側に書く。
- 全プロジェクト共通スキルについては下の「AI CLI skills の管理」を参照。

## AI CLI の信頼ディレクトリ

Claude Code / Codex に信頼(trust)させるのは **自分が管理するリポジトリだけ**にし、リポジトリ単位で付ける。リポジトリの置き場所(`~/personal` や `~/Developer` など)はマシンごとに違うので、ここでは特定のディレクトリ構成を前提にしない。信頼すると第三者の `AGENTS.md` / `CLAUDE.md` が指示として読まれるだけでなく、`.claude/settings.json` の hooks や `.mcp.json` の MCP サーバーも実行されうるため、範囲を絞る。

- 信頼してよい: `~/dotfiles`、`~/life`、自分が作成・管理するリポジトリ。
- 信頼しない:
  - `~`、`~/Downloads`、リポジトリをまとめて置く親ディレクトリ(例: `~/personal`)のような広いディレクトリ。
  - `~/.claude`。第三者のプラグインや skill の置き場なので、設定の変更は dotfiles 側で行う。
  - 他人のリポジトリの clone(OSS への contribution や教材など)。必要なら `AGENTS.md` / `CLAUDE.md`、`.claude/`、`.mcp.json`、`.codex/` を読んでから付ける。
- 信頼は初回起動時の確認ダイアログから付ける。上の範囲外では承認しない。
- 設定先は dotfiles 管理外のマシンローカルファイル。Codex は `~/.codex/config.toml` の `[projects."<path>"] trust_level = "trusted"`、Claude Code は `~/.claude.json` の `projects["<path>"].hasTrustDialogAccepted`。どちらもツール自身が書き込み、パスや MCP 設定がマシンごとに違い、秘密情報も混ざりうるため repo には入れない。
- 範囲外のエントリが増えていないか、ときどき確認する:
  ```sh
  grep '^\[projects\.' ~/.codex/config.toml
  jq -r '.projects | to_entries[] | select(.value.hasTrustDialogAccepted) | .key' ~/.claude.json
  ```

## AI CLI 共通指示の管理

全プロジェクトに効かせる指示は **`agents/AGENTS.md` を正本**にする。リポジトリ直下の `AGENTS.md`(このファイル)はこのリポジトリにしか効かない。

- `home-manager/ai-instructions/default.nix` が `agents/AGENTS.md` を `~/.codex/AGENTS.md` へ、`agents/CLAUDE.md` を `~/.claude/CLAUDE.md` へ `mkOutOfStoreSymlink` で貼る。中身の編集は switch 不要で即反映される。
- Claude Code は `AGENTS.md` を読まないため、`agents/CLAUDE.md` は `@~/.codex/AGENTS.md` で正本を import するだけにする(リポジトリの `CLAUDE.md` → `@AGENTS.md` と同じ形)。Claude 固有の指示が要るときは import 行の下に足す。
- 毎セッションのコンテキストに入るので、言語やツールに依存しない作業姿勢だけを短く書く。技術スタック固有の話は各リポジトリの `AGENTS.md` に書く。秘密情報やマシン固有のパスは書かない。

## AI CLI skills の管理

全プロジェクト共通のスキルは APM で導入し、宣言と lockfile を `apm/apm.yml` と `apm/apm.lock.yaml` で管理する。
実行時のファイルは `~/.apm/` にコピーする。APM が更新するため、読み取り専用の Nix store へのリンクにしない。
設定の復元と更新後の保存手順は [docs/setup.md](docs/setup.md) を参照。

- 現在は `nanaism/yomiyasu` の `yomiyasu` を Claude Code と Codex 向けに導入する。
- スキルの配置先は `~/.claude/skills/yomiyasu/` と `~/.agents/skills/yomiyasu/`。本体とキャッシュは dotfiles にコミットしない。
- Home Manager はスキルのリンクを作らない。
- 自作スキルの正本と外部スキルの配布用依存セットは [aki05162525/skills](https://github.com/aki05162525/skills) で管理する。用途と導入方法は同リポジトリの README を参照し、dotfiles に重複して記録しない。
- プロジェクト固有の依存は各プロジェクトの `apm.yml` と `apm.lock.yaml` に置く。
- yomiyasu は明示して依頼するときに使う。全プロジェクトへの配置を、全応答での自動適用とは扱わない。

## フォーマット

`flake.nix` の `formatter` に nixfmt(公式フォーマッタ)を定義済み。変更後はリポジトリルートで:

```sh
nix fmt
```

特定ファイルだけ整形したいときは `nixfmt <file>...` を直接呼んでもよい。

## ツール管理の棲み分け

詳細は [docs/tool-management.md](docs/tool-management.md) 参照。要約:

- **Nix (Home Manager)**: グローバルCLI(git, gh, mise, direnv, starship, jq, ripgrep など)
- **WezTerm**: Windows / macOS のターミナルアプリ。設定実体は `wezterm/` で管理し、`home-manager switch` の activation で各 OS へ反映する(WSL2 は Windows 側へコピー、macOS は symlink)
- **mise**: Node, Go など言語ランタイムのバージョン管理(プロジェクト別の `.tool-versions` 対応)
- **corepack** (Node 同梱): pnpm, yarn のバージョン管理(`package.json` の `packageManager` フィールド)
- **direnv**: プロジェクト別の環境変数(`.envrc`)

Claude Code / codex / gemini などの AI CLI は **自己更新する**ため Nix 管理しない(read-only な Nix store と相性が悪い)。`~/.local/bin/claude` のような形で公式インストーラに任せる。

Rust の cargo/rustc は **rustup のまま**(rustup 自体が公式のバージョン管理機構なので)。

## SSH キー / コミット署名

SSH キーは **1Password で管理**し、ディスク上に秘密鍵(`~/.ssh/id_*`)を置かない。**1台 = 1キー**の方針で、マシンごとに別々のキーを割り当てる(マシン間で共有しない)。

- **認証 (git push/pull)**:
  - WSL2: `git/default.nix` の `core.sshCommand = "ssh.exe"` で Windows 側 1Password SSH Agent を使う。
  - macOS: 1Password アプリの SSH Agent(1Password 側で有効化)を使う。
- **コミット署名**: `gpg.format = ssh` + `commit.gpgsign = true`。署名バイナリは OS 別に `git/default.nix` で分岐:
  - WSL2: `op-ssh-sign-wsl.exe`(WindowsApps が WSL の PATH に乗るため、ユーザー名を含む絶対パスにせず素の名前で解決させる)
  - macOS: `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`
- **`user.signingkey`(= 公開鍵)はマシン固有**なので nix には書かず、`~/.gitconfig.local`(`programs.git.includes` で取り込み・git 管理外)に置く。

新しいマシンを足すときの手順:

1. 1Password で SSH キー(ed25519)を新規作成する。
2. GitHub の SSH keys に公開鍵を **Authentication Key と Signing Key の両方**で登録する(同じ鍵でよい。署名用も登録しないとコミットに "Verified" が付かない)。
3. その公開鍵を `~/.gitconfig.local` の `[user] signingkey` に書く。
4. WSL2 の場合、Windows 側 1Password の 設定 → 開発者 で「SSH エージェントを使用」を ON にする。

## 別マシンへの展開

[docs/setup.md](docs/setup.md) 参照。
