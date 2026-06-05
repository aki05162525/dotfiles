# 新しいマシンでのセットアップ手順

Home Manager (flake構成) を前提とした手順。WSL2 (Windows) と macOS (Apple Silicon) の
両方に対応しており、`flake.nix` の `homeConfigurations` でホスト別の構成を切り替える。

- WSL2: `home-manager switch --flake .#akihiro@wsl`
- macOS: `home-manager switch --flake .#takagi@mac`

## 前提

- WSL2 (Ubuntu) または macOS (Apple Silicon)
- WSL2 の場合は Windows 側に WezTerm をインストール可能
- `sudo` 権限あり(WSL2 の場合)
- インターネット接続あり

## 1. Nix のインストール

Determinate Systems の installer を使う(flake が標準で有効化される):

> `curl` は Ubuntu WSL に標準で含まれている。入っていなければ `sudo apt install -y curl`。

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

インストール後、シェルを再起動:

```sh
exec $SHELL -l
```

確認:

```sh
nix --version
```

## 2. dotfiles をクローン

```sh
nix run nixpkgs#git -- clone https://github.com/aki05162525/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## 3. マシン固有の値を確認・修正

WSL2 / macOS (Apple Silicon) は `flake.nix` の `homeConfigurations` に定義済みなので、
通常は修正不要。新しいホストを足す場合だけ `flake.nix` を編集する。`mkHome` には
`system` と `username` を渡すだけでよく、homeDirectory は OS から自動で組み立てられる:

```nix
homeConfigurations = {
  "akihiro@wsl" = mkHome { system = "x86_64-linux";   username = "akihiro"; };
  "takagi@mac"  = mkHome { system = "aarch64-darwin"; username = "takagi"; };
  # 例: Intel Mac を足すなら
  # "takagi@mac-intel" = mkHome { system = "x86_64-darwin"; username = "takagi"; };
};
```

構成名は `<username>@<host>` の形にしておくと、どのマシン用か分かりやすい。

`home-manager/git/default.nix` で git の user 情報も必要なら修正:

```nix
user = {
  name = "aki05162525";
  email = "akihiro05162525@gmail.com";
};
```

## 4. Home Manager を初回適用

リポジトリルートで、マシンに対応する構成を指定する(以下は WSL2 の例。mac は `.#takagi@mac`):

```sh
nix run home-manager/master -- switch --flake .#akihiro@wsl
```

2回目以降は `home-manager` コマンドが PATH に入るので:

```sh
home-manager switch --flake .#akihiro@wsl
```

シェルを再起動:

```sh
exec zsh
```

## 5. ログインシェルを zsh に変更

```sh
chsh -s $(which zsh)
```

WSL を再起動して反映。

## 6. ポストセットアップ

### WezTerm の導入と設定反映

**WSL2 (Windows) の場合:** Windows 側で WezTerm をインストールし、WSL 側の dotfiles から設定をコピーする:

```powershell
winget install wez.wezterm
```

```sh
cd ~/dotfiles
scripts/install-wezterm-config.sh
```

**macOS の場合:** WezTerm をインストールし、同じスクリプトを実行する。mac では
`~/.config/wezterm` へ symlink を張るので、以降はリポジトリを編集すれば即反映される
(再実行不要)。

```sh
brew install --cask wezterm
cd ~/dotfiles
scripts/install-wezterm-config.sh
```

WezTerm を開き直して、WSL のホームに入ることを確認する:

```sh
pwd
```

期待値:

```text
/home/<WSLユーザー>
```

WSL ディストリビューション名が `Ubuntu` ではない場合は、Windows 側で確認し、必要に応じて `wezterm/platform.lua` の domain 名を合わせる:

```powershell
wsl -l -v
```

WezTerm 設定を変更したときは、WSL2 では毎回以下で Windows 側へ反映する(mac は symlink なので不要):

```sh
cd ~/dotfiles
scripts/install-wezterm-config.sh
```

PC ごとの workspace 一覧は `wezterm/workspace.local.lua` に書く。このファイルは git 管理しない。

### gh の認証

```sh
gh auth login
```

GitHub.com → HTTPS → Y(git の credential helper として gh を使う) → ブラウザ認証 の流れ。

### mise でランタイムをインストール

`home-manager/mise/default.nix` の `globalConfig.tools` に書いてあるバージョン(Node, Go等)を実際にダウンロード:

```sh
mise install
mise current   # 確認
```

### corepack で pnpm を有効化

```sh
corepack enable pnpm
pnpm --version
```


## 7. 動作確認

```sh
# 主要ツールが Nix 管理になっているか
which mise node git gh direnv starship zsh uv trufflehog jq

# mise のランタイム
mise current

# Home Manager 自身
home-manager --version
```

## トラブルシューティング

### `Existing file '~/.config/...' would be clobbered`

Home Manager が管理したいファイルが既にプレーンファイルとして存在しているとき。内容を確認し、不要なら削除して再実行:

```sh
rm ~/.config/<該当ファイル>
home-manager switch --flake .#akihiro@wsl   # mac は .#takagi@mac
```

### `error: Path '...' in the repository ... is not tracked by Git`

flake は git でトラッキングされたファイルしか見ない。新規追加した `.nix` ファイルを git に追加:

```sh
git add <file>
home-manager switch --flake .#akihiro@wsl   # mac は .#takagi@mac
```

### WezTerm のペイン分割時に現在ディレクトリを引き継がない

`home-manager/zsh/default.nix` で WezTerm に現在ディレクトリを通知する OSC 7 を出している。Home Manager を再反映して、WezTerm を開き直す:

```sh
home-manager switch --flake .#akihiro@wsl   # mac は .#takagi@mac
```


## 次のステップ

- [ツール管理の役割分担](./tool-management.md) を一読しておくと運用イメージが掴める
- 新しいツールを追加するときは `home-manager/<tool>/default.nix` を作って `home.nix` の `imports` に追加 → `git add` → `home-manager switch`
