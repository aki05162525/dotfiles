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

- CLI: `git`, `gh`, `jq`, `ripgrep`, `uv`, `trufflehog`
- shell: `zsh`, `starship`, `fzf`, `direnv`
- 開発補助: `mise`, `lefthook`, `shellcheck`, `stylua`, `nixfmt`
- Git 設定: user 情報、credential helper、commit signing の共通設定

手作業が必要なのは、Nix のインストール、外部 GUI アプリ、認証、PC 固有の秘密情報だけ。

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
nix run github:nix-community/home-manager -- switch --flake .#akihiro@wsl

# macOS
nix run github:nix-community/home-manager -- switch --flake .#takagi@mac
```

> **初回ブートストラップの注意**: `nix run github:nix-community/home-manager` は flake.lock の
> pinned バージョンを使わず、GitHub から最新 master を取得する。これは `home-manager` コマンドが
> まだ PATH にないための回避策。2回目以降は `home-manager` コマンドが PATH に入るため、
> flake.lock が参照されて再現性が保たれる。

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

WezTerm 本体は OS 側に入れる。設定は `wezterm/` を直接参照するため、編集後は WezTerm をリロード
(Ctrl+Shift+R)するだけで反映される。

```powershell
# WSL2: Windows 側で実行
winget install wez.wezterm
```

```sh
# macOS
brew install --cask wezterm
```

**macOS** は `home-manager switch` で `~/.config/wezterm` に symlink が作られるので追加作業は不要。

**WSL2** は初回だけスクリプトを実行して Windows 側 `~/.wezterm.lua` を生成する。

```sh
cd ~/dotfiles
scripts/install-wezterm-config.sh
```

PC ごとの workspace 一覧は git 管理しない `wezterm/workspace.local.lua` に書く。

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
Configure for Windows Subsystem for Linux (WSL) → Copy Snippet で取得した値を書く。

```ini
[user]
  signingkey = ssh-ed25519 <公開鍵>

[gpg "ssh"]
  program = "/mnt/c/Users/<Windowsユーザー名>/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe"
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

corepack enable pnpm
pnpm --version
```

詳しい役割分担は [ツール管理の役割分担](./tool-management.md) を参照。

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

### WezTerm 設定(macOS のみ)

```sh
ls -la ~/.config/wezterm
```

`~/dotfiles/wezterm` への symlink になっていれば OK。

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
