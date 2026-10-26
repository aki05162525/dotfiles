# 新しいマシンでのセットアップ手順

Home Manager (flake構成) を前提にする。WSL2 (Ubuntu) と macOS (Apple Silicon) は
`flake.nix` の `homeConfigurations` に定義済み。

使う構成名は WSL2 が `akihiro@wsl`、macOS が `takagi@mac`。

## 前提

- WSL2 (Ubuntu) または macOS (Apple Silicon)
- `sudo` 権限あり(WSL2 の場合)
- インターネット接続あり

## Nix が管理するもの

Home Manager 適用後、以下は Nix 管理になる。個別インストールは不要。

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

`--inputs-from .` により、このリポジトリの `flake.lock` に固定した版の Home Manager CLI で初回適用する。
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

**macOS** は `home-manager switch` で `~/.config/wezterm` に symlink が作られるので追加作業は不要。

**WSL2** も `home-manager switch` の activation(`weztermWslConfig`)が、`wezterm/*.lua` を Windows 側 `%USERPROFILE%\.config\wezterm` へコピーし、エントリ `~/.wezterm.lua` を生成する。WezTerm 本体を入れたら、もう一度 `home-manager switch` を実行すれば反映される(手動スクリプトは不要)。以降 `wezterm/` を編集したら `switch` でコピーが更新される。

PC ごとの workspace 一覧は git 管理しない `wezterm/workspace.local.lua` に書く(これもコピー対象)。

WSL ディストリビューション名が `Ubuntu` ではない場合は、Windows 側で確認して
`wezterm/platform.lua` の domain 名を合わせる。

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

### AI CLI の skills(サードパーティ)

自作 skill は `skills/` を home-manager が symlink するので追加作業は不要。
サードパーティ配布の skill は dotfiles に取り込まず、各マシンで公式 installer から入れる
(実体は `~/.agents/skills/` に置かれ、Claude Code へは symlink、Codex 等は直接読む)。

現在使っているもの。いずれも**ホームディレクトリで実行する**(リポジトリ内で実行すると
プロジェクトレベルに入ってしまう)。

```sh
cd ~

# modern-web-guidance: フロントエンド実装の最新プラクティス
npx modern-web-guidance@latest install

# grill-me: 計画・設計を質問攻めで検証する(skills.sh 経由)
npx skills add https://github.com/mattpocock/skills --skill grill-me
```

更新は modern-web-guidance が `npx modern-web-guidance@latest update`、
skills.sh 経由のものが `npx skills update`。
テレメトリを止めたい場合は `DISABLE_TELEMETRY=1` を環境変数に設定する。

## 動作確認

### Nix 管理のツール

```sh
command -v git gh direnv starship zsh uv trufflehog jq
```

全て `~/.nix-profile/bin/` 以下のパスが返れば OK。

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

**macOS**:

```sh
ls -la ~/.config/wezterm
```

`~/dotfiles/wezterm` への symlink になっていれば OK。

**WSL2**: Windows 側 `~/.wezterm.lua` が生成され、先頭に `WEZTERM_DOTFILES_CONFIG_DIR` が書かれていれば OK。

```sh
win_home="$(wslpath -u "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')")"
head -n1 "$win_home/.wezterm.lua"
ls "$win_home/.config/wezterm"   # wezterm/ の lua がコピーされていれば OK
```

生成されない場合はリポジトリが `~/dotfiles` 以外に置かれている可能性があるので確認する。

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
