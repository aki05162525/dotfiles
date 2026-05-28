# 新しいマシンでのセットアップ手順

WSL (Ubuntu) + Home Manager (flake構成) を前提とした手順。
他ディストリビューションや macOS で使う場合は適宜読み替え + `home.nix` のシステム名修正が必要。

## 前提

- WSL 2 (Ubuntu) がインストール済み
- Windows 側に WezTerm をインストール可能
- `sudo` 権限あり
- インターネット接続あり

## 1. 必須コマンドの導入

```sh
sudo apt update
sudo apt install -y curl git
```

## 2. Nix のインストール

Determinate Systems の installer を使う(flake が標準で有効化される):

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

## 3. dotfiles をクローン

```sh
git clone https://github.com/aki05162525/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## 4. マシン固有の値を確認・修正

`flake.nix` を開いて、コメント `===== マシンごとに変わる値はここ =====` のブロック内を確認:

```nix
let
  # ===== マシンごとに変わる値はここ =====
  username = "akihiro";                 # ← 新マシンのWSLユーザー名に合わせる
  homeDirectory = "/home/${username}";  # ← Mac なら "/Users/${username}"
  system = "x86_64-linux";              # ← Mac なら "aarch64-darwin"
  # ====================================
```

`home-manager/git/default.nix` で git の user 情報も必要なら修正:

```nix
user = {
  name = "aki05162525";
  email = "akihiro05162525@gmail.com";
};
```

## 5. Home Manager を初回適用

リポジトリルートで(ユーザー名が違う場合は `.#<username>` を読み替え):

```sh
nix run home-manager/master -- switch --flake .#akihiro
```

2回目以降は `home-manager` コマンドが PATH に入るので:

```sh
home-manager switch --flake .#akihiro
```

シェルを再起動:

```sh
exec zsh
```

## 6. ログインシェルを zsh に変更

```sh
chsh -s $(which zsh)
```

WSL を再起動して反映。

## 7. ポストセットアップ

### WezTerm の導入と設定反映

Windows 側で WezTerm をインストールし、WSL 側の dotfiles から設定をコピーする:

```powershell
winget install wez.wezterm
```

```sh
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

WezTerm 設定を変更したときは、毎回以下で Windows 側へ反映する:

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

### Claude Code (任意)

公式インストーラで導入(Nix管理しない方針):

```sh
curl -fsSL https://claude.ai/install.sh | sh
```

インストール後 `claude` コマンドが `~/.local/bin/claude` に配置される。

## 8. 動作確認

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
home-manager switch --flake .#akihiro
```

### `error: Path '...' in the repository ... is not tracked by Git`

flake は git でトラッキングされたファイルしか見ない。新規追加した `.nix` ファイルを git に追加:

```sh
git add <file>
home-manager switch --flake .#akihiro
```

### WezTerm が `cmd.exe` で起動してしまう

Windows 側に WezTerm 設定が未反映。WSL 側で反映スクリプトを実行し、WezTerm をウィンドウごと閉じて開き直す:

```sh
cd ~/dotfiles
scripts/install-wezterm-config.sh
```

### WezTerm のペイン分割時に現在ディレクトリを引き継がない

`home-manager/zsh/default.nix` で WezTerm に現在ディレクトリを通知する OSC 7 を出している。Home Manager を再反映して、WezTerm を開き直す:

```sh
home-manager switch --flake .#akihiro
```

### Windows Terminal + Zellij で `Ctrl+Shift+C` が中断になる

この dotfiles は現在、常用端末を Windows Terminal + Zellij ではなく WezTerm 主役に寄せている。Windows Terminal では `Ctrl+Shift+C` がアプリ側へ `Ctrl+C` として流れる環境があり、Zellij 側では区別できない。

確認:

```sh
showkey -a
```

`Ctrl+Shift+C` が以下になる場合は、端末アプリ側ですでに `Ctrl+C` に潰れている:

```text
^C        3 0003 0x03
```

この場合は WezTerm を使うか、Windows Terminal のコピーキーを `Ctrl+Insert` などへ変更する。

### `USER: unbound variable`

シェルが `env -i` 等で環境変数を消した状態で起動されたとき。新しいターミナルを開き直すか手動で設定:

```sh
export USER=$(whoami)
```

## 次のステップ

- [ツール管理の役割分担](./tool-management.md) を一読しておくと運用イメージが掴める
- 新しいツールを追加するときは `home-manager/<tool>/default.nix` を作って `home.nix` の `imports` に追加 → `git add` → `home-manager switch`
