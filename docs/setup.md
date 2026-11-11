# 新しいマシンでのセットアップ手順

Home Manager (flake構成) を使う。`flake.nix` の `homeConfigurations` に WSL2 (Ubuntu) 用の `akihiro@wsl` と macOS (Apple Silicon) 用の `takagi@mac` を定義している。

## 前提

- WSL2 (Ubuntu) または macOS (Apple Silicon)
- `sudo` 権限あり(WSL2 の場合)
- インターネット接続あり

## Nix が管理するもの

次のツールと設定は Home Manager で導入する。

- CLI: `git`, `gh`, `jq`, `ripgrep`, `uv`, `trufflehog`, `supabase`, `op`, `herdr`, `mpg123`
- Linux 専用: `net-tools`, `wsl-open`
- shell: `zsh`, `starship`, `fzf`, `direnv`
- 開発補助: `mise`, `lefthook`, `shellcheck`, `stylua`, `nixfmt`
- Git 設定: user 情報、credential helper、commit signing の共通設定

Nix のインストール、外部 GUI アプリ、認証、PC 固有の設定に加え、mise のランタイムと herdr の integration は以下の手順で導入する。

## 1. Nix をインストール

Determinate Systems の installer を使う。flake は標準で有効化される。

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
exec $SHELL -l
nix --version
```

`curl` がない Ubuntu WSL では先に入れる。

```sh
sudo apt install -y curl
```

## 2. dotfiles をクローン

```sh
nix run nixpkgs#git -- clone https://github.com/aki05162525/dotfiles.git ~/dotfiles
```

## 3. Home Manager を初回適用

```sh
cd ~/dotfiles

# WSL2
nix run --inputs-from . home-manager -- switch --flake .#akihiro@wsl

# macOS
nix run --inputs-from . home-manager -- switch --flake .#takagi@mac
```

`--inputs-from .` により、このリポジトリの `flake.lock` に固定したバージョンの Home Manager CLI で初回適用する。
CLI 自体の依存パッケージには Home Manager 側の lock が使われるが、適用する構成は `--flake .#…` で指定したこのリポジトリの lock に従う。

2回目以降は `home-manager` コマンドが PATH に入る。

```sh
home-manager switch --flake .#akihiro@wsl   # mac は .#takagi@mac
exec zsh
```

新しいホストを足す場合だけ `flake.nix` の `homeConfigurations` に追加する。

```nix
homeConfigurations = {
  "akihiro@wsl" = mkHome { system = "x86_64-linux"; username = "akihiro"; };
  "takagi@mac" = mkHome { system = "aarch64-darwin"; username = "takagi"; };
};
```

## 4. ログインシェルを zsh に変更

```sh
chsh -s "$(which zsh)"
```

WSL は再起動して反映する。

## 5. 初回だけ必要な設定

### WezTerm

WezTerm 本体は OS 側に入れる。
設定の編集後、macOS は WezTerm のリロード(Ctrl+Shift+R)で反映される。
WSL2 は `home-manager switch` で Windows 側のコピーを更新してからリロードする。

```powershell
# WSL2: Windows 側で実行
winget install wez.wezterm
```

```sh
# macOS
brew install --cask wezterm
```

macOS は `home-manager switch` で `~/.config/wezterm` に symlink を作る。
WSL2 は activation(`weztermWslConfig`)で `wezterm/*.lua` を Windows 側 `%USERPROFILE%\.config\wezterm` へコピーし、`~/.wezterm.lua` を生成する。WezTerm 本体の導入後に、もう一度 `home-manager switch` を実行する。

PC ごとの workspace 一覧は git 管理しない `wezterm/workspace.local.lua` に書く(これもコピー対象)。

`wezterm/platform.lua` は `WSL:Ubuntu` を優先し、なければ最初の WSL domain を使う。別の domain を優先する場合は、Windows 側でディストリビューション名を確認し、同ファイルの `preferred` を変更する。

```powershell
wsl -l -v
```

### 1Password SSH Agent

1Password アプリは OS 側に入れて、Settings → Developer → SSH Agent を有効化する。
SSH キーを 1Password に入れたら接続確認する。

```sh
# WSL2
ssh-add.exe -l
ssh.exe -T git@github.com

# macOS
ssh -T git@github.com
```

### Git commit signing

`gpg.format` と `commit.gpgsign` は Home Manager 設定済み。署名鍵などの PC 固有値だけ
`~/.gitconfig.local` に置く。

WSL2 は 1Password アプリで SSH キーを開き、`...` → Configure Commit Signing →
Configure for Windows Subsystem for Linux (WSL) → Copy Snippet で公開鍵を確認し、`signingkey` だけを書く。
`gpg.ssh.program` は Home Manager が `op-ssh-sign-wsl.exe` に設定するので、スニペットの絶対パスは追加しない。

```ini
[user]
  signingkey = ssh-ed25519 <公開鍵>
```

macOS は 1Password の公開鍵を確認して、署名鍵だけを書く。`gpg.ssh.program` は Home Manager
設定済み。

```sh
SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -L
```

```ini
[user]
  signingkey = ssh-ed25519 <公開鍵>
```

### AI エージェントの commit signing

AI エージェントは 1Password の承認ダイアログを通せないため、マシンごとに署名専用の鍵を作る。
GitHub には Signing Key としてだけ登録し、Authentication Key には登録しない。

```sh
ssh-keygen -t ed25519 -N '' -C "agent-signing@$(hostname)" -f ~/.ssh/agent_signing
gh ssh-key add ~/.ssh/agent_signing.pub --type signing --title "agent-signing@$(hostname)"
```

Claude Code は `home-manager/claude-code/settings.json` の `env` でこの鍵を使う。
Codex の `~/.codex/config.toml` は dotfiles 管理外なので、マシンごとに次を追記する。

```toml
[shell_environment_policy.set]
GIT_CONFIG_COUNT = "2"
GIT_CONFIG_KEY_0 = "gpg.ssh.program"
GIT_CONFIG_VALUE_0 = "ssh-keygen"
GIT_CONFIG_KEY_1 = "user.signingkey"
GIT_CONFIG_VALUE_1 = "~/.ssh/agent_signing.pub"
```

### gh

```sh
gh auth login
```

GitHub.com → HTTPS → Y(git の credential helper として gh を使う) → ブラウザ認証。

### mise / corepack

`mise` 本体と設定は Nix 管理。Node / Go などの実体は `mise install` で入れる。
`pnpm` は Nix では固定せず、Node 同梱の corepack に任せる。

```sh
mise install
mise current

pnpm --version
```

mise の `settings.node.corepack = true` で Node のインストール時に corepack を有効化するため、通常は手動の `corepack enable pnpm` は不要。
既存の Node で pnpm が見つからない場合は `corepack enable pnpm` を実行する。

詳しい役割分担は [ツール管理の役割分担](./tool-management.md) を参照。

### T3 Code CLI

WSL2 (Ubuntu) と macOS (Apple Silicon) では、[公式インストーラ](https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md#command-line)で `t3` を導入する。
WSL2 では Ubuntu 側のターミナルで実行する。

```sh
curl -fsSL https://t3.codes/install.sh | sh
command -v t3
t3 --version
```

`command -v t3` が `~/.local/bin/t3` を指せば導入できている。
このディレクトリは `home-manager/home.nix` の `home.sessionPath` に登録済みなので、PATH の追加は不要。
見つからない場合は Home Manager を適用してログインし直す。

CLI 本体は公式インストーラで管理し、更新には `t3 update` を使う。
Desktop が WSL 内に配置する `~/.t3/wsl-runtime/<hash>/t3` はアプリ管理の実行ファイルなので、dotfiles から特定のハッシュを PATH や symlink に固定しない。
この手順は CLI の導入のみを扱う。T3 Connect の認証・サーバー起動・接続設定は含まない。
接続の調査には [公式のトラブルシューティング](https://github.com/pingdotgg/t3code/blob/main/docs/user/t3-connect-troubleshooting.md)を参照する。

### herdr と Claude Code の integration

Claude Code を公式インストーラで導入した後、herdr の integration を各マシンでインストールする。
`settings.json` の SessionStart hook が参照する `~/.claude/hooks/herdr-agent-state.sh` は、この操作で配置される。

```sh
herdr integration install claude
herdr integration status
test -f ~/.claude/hooks/herdr-agent-state.sh
```

installer は共有設定の `~/.claude/settings.json` にも書き戻すため、実行後に `git -C ~/dotfiles diff -- home-manager/claude-code/settings.json` を確認する。
マシン固有の絶対パスが書かれた場合は、既存の `$HOME` を使う記述に戻す。

### 全プロジェクト共通の Agent Skills

全プロジェクトで使うスキルは APM で管理する。
宣言は `apm/apm.yml` に置き、[skills リポジトリ](https://github.com/aki05162525/skills) のパッケージ(`aki05162525/skills/packages/<名前>`)を ref なしで参照する。
Claude Code と Codex 向けに `yomiyasu`、explainer 系の5スキル、`eli5` を導入する。
upstream の固定コミットと導入するスキルは skills リポジトリの `packages/<名前>/apm.yml` で管理する。
用途・追加方法・更新手順は同リポジトリの README を参照する。
lockfile はマシンごとに `~/.apm/apm.lock.yaml` へ生成され、dotfiles にはコミットしない。

新しいマシンでは、uv が利用可能になった後に以下を実行する。
`~/.apm/` に既存の設定がある場合は、コピーする前に差分を確認して必要な依存を統合する。
ホームディレクトリを信頼済みプロジェクトにする必要はない。

```sh
uv tool install apm-cli==0.35.0
mkdir -p ~/.apm
cp ~/dotfiles/apm/apm.yml ~/.apm/
apm install -g
```

その時点の skills リポジトリの `main` が導入される。
APM は `~/.claude/skills/<名前>/` と `~/.agents/skills/<名前>/` に配置する。
`~/.apm/apm_modules/` は APM のキャッシュであり、dotfiles にはコピーしない。
Home Manager はスキルのリンクを生成しない。
`apm install` の「dependencies unpinned」の警告は、`main` を参照する方針どおりなので無視してよい。

スキルを更新するときは、skills リポジトリで固定コミットを上げて push したあと、各マシンで以下を実行する。
dotfiles の変更は不要。

```sh
apm update -g --dry-run   # 更新計画の確認
apm update -g --yes
```

パッケージを追加・削除するときだけ `apm/apm.yml` を変更する。
`~/.apm/apm.yml` で `apm install -g` か `apm uninstall -g aki05162525/skills/packages/<名前>` を実行し、`cp ~/.apm/apm.yml ~/dotfiles/apm/` で保存してコミットする。
APM 自体は `uv tool install --upgrade apm-cli==<更新先の版>` で更新し、初期導入手順のバージョンも変更する。
スキルの配置先は直接編集しない。

使うときは「yomiyasu でこの文章を推敲して」と明示する。
付属の検査には Python を使い、任意のフックは今回設定していない。
explainer 系と eli5 は名前を指定して使う。指定されたスキルの手順で必要な関連スキルも利用できる。起動条件は `agents/AGENTS.md` で定める。
explainer は `explainer-book`、`first-reader`、`d2-diagram`、`d2-slides` とまとめて導入する。資料作成・検証には Node 24 以上と用途別の依存を別途用意する。
実行中のエージェントには設定変更前のスキル一覧が残る場合があるため、切り替え後は新しいセッションで確認する。

## 動作確認

### Nix 管理のツール

```sh
command -v git gh direnv starship zsh uv trufflehog jq
```

全て `~/.nix-profile/bin/` 以下のパスになっていることを確認する。

### ログインシェル

```sh
echo $SHELL
```

`~/.nix-profile/bin/zsh` が返れば OK。`/bin/bash` などが返る場合は `chsh` が未反映なのでシェルを再起動する。

### mise のランタイム

```sh
mise current
```

`home-manager/mise/default.nix` に書いたバージョンが表示されれば OK。表示されない場合は `mise install` を実行する。

### GitHub SSH 接続

```sh
# WSL2
ssh.exe -T git@github.com

# macOS
ssh -T git@github.com
```

`Hi <username>! You've successfully authenticated` が返れば OK。失敗する場合は 1Password SSH Agent の設定を確認する。

### gh 認証

```sh
gh auth status
```

`Logged in to github.com` が返れば OK。

### Git commit signing

```sh
git config user.signingkey
```

1Password に登録した公開鍵(`ssh-ed25519 ...`)が返れば OK。空の場合は `~/.gitconfig.local` の設定を確認する。

### lefthook の git hook

```sh
ls .git/hooks/pre-commit
```

ファイルが存在すれば OK。存在しない場合は `home-manager switch` を再実行する。

### WezTerm 設定

macOS ではリンク先を確認する。

```sh
ls -la ~/.config/wezterm
```

`~/dotfiles/wezterm` への symlink になっていれば OK。

WSL2: Windows 側 `~/.wezterm.lua` が生成され、先頭に `WEZTERM_DOTFILES_CONFIG_DIR` が書かれていれば OK。

```sh
win_home="$(wslpath -u "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')")"
head -n1 "$win_home/.wezterm.lua"
ls "$win_home/.config/wezterm"   # wezterm/ の lua がコピーされていれば OK
```

生成されない場合は、リポジトリが `~/dotfiles` にあるか確認する。

## トラブルシューティング

### `Existing file '~/.config/...' would be clobbered`

Home Manager が管理したいファイルが既に存在している。内容を確認し、不要なら削除して再実行する。

```sh
rm ~/.config/<該当ファイル>
home-manager switch --flake .#akihiro@wsl   # mac は .#takagi@mac
```

## 次のステップ

新しい CLI を追加するときは `home-manager/<tool>/default.nix` を作って `home.nix` の `imports`
に追加し、`git add` してから `home-manager switch` する。
