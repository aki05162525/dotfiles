# eMudhra 中間CA 秘密鍵漏洩 (2026-10) の対応手順

eMudhra (emSign) の中間CA 8枚の秘密鍵が、2025-04-30 の鍵生成セレモニーの不備で
復元可能な値になっていた。P-384 のはずが実体は 256 未満の整数(公表例では `4`,
`56`, `115`)で、誰でも数ミリ秒で復元できる。この鍵で任意サイトの TLS 証明書を
偽造できるため、経路を乗っ取られている状況では盗聴・改ざんが成立する。

ブラウザは各ベンダが 10/17〜10/20 に遮断済み。**それ以外は明示的な更新が必要**で、
本書はその手順を記録する。

## 対応状況

WSL2 マシンは複数あり、同じ Home Manager 構成 (`akihiro@wsl`) を共有する。
構成名ではマシンを区別できないので、**`hostname` 単位で記録する**。

| ホスト名 | 構成 | OS | 状態 |
|---|---|---|---|
| (macOS機) | `takagi@mac` | macOS / Apple Silicon | 完了 (2026-10-22)。Nix の CA バンドルは 2026-10-26 に対応 |
| `minipc` | `akihiro@wsl` | WSL2 Ubuntu 24.04 | 初回対応済み (2026-10-22)。2026-10-26 に uv 更新と TLS 拒否を確認。mise は未達 (下記) |
| `aki-thinkpad` | `akihiro@wsl` | WSL2 Ubuntu 24.04 | 完了 (2026-10-22) |

各マシンで作業したら、自分の `hostname` を記入して状態を更新する。
行が足りなければ足す。

### minipc の追加確認 (2026-10-26)

`ba08b7c` を pull し、`home-manager switch --flake '.#akihiro@wsl'` を実行した。

- uv は `0.13.4` に更新済み。
- Ubuntu の `ca-certificates` は `20260816ubuntu0.24.04.1` で、Nix の `ssl-cert-file` は `/etc/ssl/certs/ca-certificates.crt` を参照している。
- 下記「検証」の 2 URL は、どちらも curl が証明書エラー (終了コード 60) で拒否した。
- mise は `2026.10.3` で、要求バージョン `2026.10.17` には未達。

## WSL2 / Windows 側の手順

### 1. Windows 側

- **Windows Update を適用する。** Microsoft は 10/20 に OS の信頼ストアで遮断した。
- **ブラウザを更新して再起動する。** Edge / Chrome / Firefox。遮断自体は配信済みだが、
  起動中のプロセスに反映させるため再起動する。

WezTerm は TLS 検証に関与しないので、この件での対応は不要。

### 2. WSL2 (Ubuntu) の信頼ストア

```sh
sudo apt update && sudo apt install -y --only-upgrade ca-certificates
dpkg -l ca-certificates | grep ^ii
```

修正版のバージョン(Ubuntu):

| リリース | 修正版 |
|---|---|
| 22.04 (jammy) | `20260816ubuntu0.22.04.1` |
| 24.04 (noble) | `20260816ubuntu0.24.04.1` |
| 26.04 | `20260816ubuntu0.26.04.1` |
| 26.10 | `20260816ubuntu0.26.10.1` |

この更新で `Comodo AAA Certificate Services` と emSign 系ルートが**両方**削除される。
macOS で必要だった手動のルート削除スクリプトは、Ubuntu では不要。

### 3. dotfiles を反映

`home-manager/mise/default.nix` に `python = "3.14"` が入っているので、pull して switch する。
構成名は `<ユーザー名>@wsl`。自分のユーザー名が違う場合は `flake.nix` の
`homeConfigurations` を確認する。

```sh
cd ~/dotfiles && git pull --rebase
home-manager switch --flake ".#$(whoami)@wsl"
```

複数の WSL マシンで作業するときは、**後から作業するマシンで必ず `git pull --rebase`
してから** 対応状況を追記する。先のマシンの記録を上書きしないため。

### 4. ランタイムの更新

```sh
mise install node@24 go@1.26 python@3.14
```

要求バージョン:

| ツール | 要求 | 管理 |
|---|---|---|
| Node.js | 24.22.1 (または 22.23.4 / 26.12.1) | mise |
| Go | 1.26.10 (または 1.27.3) | mise |
| pip | 26.2.2 | mise の Python に同梱 |
| Python certifi | 2026.10.19 | 同上 |
| rustup | 1.29.2 | rustup 自身 (`rustup self update`) |
| uv | 0.13.4 | Nix (下記参照) |
| mise | 2026.10.17 | Nix (下記参照) |

Rust を使っているマシンでは `rustup self update && rustup update` も実行する。

### 5. 検証

次の2つが**いずれも TLS エラーになること**を確認する。

```sh
curl https://dv-g3b-emudhra.we-have-a-problem.com/
curl https://dv-g3b-aaa-emudhra.we-have-a-problem.com/
```

成功してしまう場合は、該当ルートがまだ残っている。確認と無効化:

```sh
# どのルートが残っているか
openssl crl2pkcs7 -nocrl -certfile /etc/ssl/certs/ca-certificates.crt \
  | openssl pkcs7 -print_certs -noout \
  | grep -E 'emSign|AAA Certificate Services'

# 残っていたら /etc/ca-certificates.conf の該当行の先頭に "!" を付けて無効化
sudo sed -i 's#^mozilla/emSign_ECC_Root_CA_-_G3.crt#!&#' /etc/ca-certificates.conf
sudo update-ca-certificates --fresh
```

`/etc/ca-certificates.conf` は `!` 始まりの行を「選択解除」として扱う。
`sudo dpkg-reconfigure ca-certificates` でも対話的に選択できる。

## Nix 管理で未達の項目

`uv` と `mise` は Nix 管理なので、nixpkgs が要求バージョンに追いつくのを待って
`flake.lock` を更新する。

| 項目 | 状態 |
|---|---|
| uv 0.13.4 | 済。nixos-unstable `3ec6363` (2026-10-23) に到達し、2026-10-26 に `flake.lock` を更新 |
| mise 2026.10.17 | 未達。[nixpkgs#577218](https://github.com/NixOS/nixpkgs/pull/577218) は 10/24 に master へマージ済みで、nixos-unstable への到達待ち |
| nixpkgs の `cacert` | 3.131.1 (3.126 から更新)。`emSign ECC Root CA - G3` / `- C3` / `Root CA - C1` が外れ、`emSign Root CA - G1` だけ残る。`AAA Certificate Services` (ラベルは `Comodo AAA Services root`) は残るが、TRUSTED CERTIFICATE 形式でサーバー認証の信頼を外されている |

mise が channel に入ったかは、マージコミットと channel の比較で確認できる
(`behind` か `identical` なら到達済み)。

```sh
gh api repos/NixOS/nixpkgs/compare/nixos-unstable...7acaf38 --jq .status
```

到達したら、`flake.lock` を更新して各マシンで反映する。

```sh
cd ~/dotfiles && nix flake update nixpkgs home-manager && home-manager switch --flake .#<構成>
```

`herdr` を対象から外しているのは、2026-10-26 時点で `nix flake update` が herdr を
現行の lock より古いコミットへ戻してしまうため。GitHub API のレート制限で
「using cached version」と出たら、更新は古いキャッシュで行われている。その場合は
`NIX_CONFIG="access-tokens = github.com=$(gh auth token)"` を付けて実行し直す。

### macOS では Nix 自身が漏洩 CA を信頼していた

macOS 機の Nix は、2 か所で古い CA バンドルを使っていた。どちらも Home Manager の外にあるので、
`flake.lock` を更新しても変わらない。

| 使う側 | 参照先 | 中身 |
|---|---|---|
| Nix 本体 (クライアントとデーモン) | `/etc/nix/nix.conf` の `ssl-cert-file = /etc/nix/macos-keychain.crt` | Determinate Nix が macOS キーチェーンを PEM に書き出したもの。G3 と AAA を含む |
| シェルの `NIX_SSL_CERT_FILE` (nixpkgs 由来のツール) | `/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt` | Nix 本体付属の `nss-cacert-3.121`。emSign 4 枚がすべて残る |

macOS 自体はこの中間 CA を拒否する (NSURLSession を使う `nscurl` で検証用の 2 URL が
どちらも `-1202` / `-9807` で失敗する)。ただ、証明書だけを並べた PEM バンドルには、
macOS が拒否に使っている情報が載らないらしい。拒否の仕組み (失効か信頼設定か) は
確認できていない。nixpkgs の curl (OpenSSL) で検証用の 2 URL を
`--cacert /etc/nix/macos-keychain.crt` 付きで叩くと、**どちらも 200 で接続できた**
(2026-10-26)。Nix 自身の `builtins.fetchurl` でも同じく取得できた。Determinate Nix を
更新しても、キーチェーンから書き出す方式は変わらないので直らない。

主な影響は `nix flake update` で nixpkgs などを取得する経路。経路を乗っ取られると、
改ざんされた入力がそのまま `flake.lock` に固定される。cache.nixos.org のバイナリは
公開鍵署名で検証されるので、TLS が破られても改ざんは通らない。

対応として `home-manager/cacert/default.nix` (macOS 限定) を追加した。

- nixpkgs の `cacert` を `~/.local/share/nix-cacert/ca-bundle.crt` に置く。switch のたびに
  追従し、Home Manager の世代が GC root になる。このバンドルでは検証用の 2 URL がどちらも失敗する。
- `NIX_SSL_CERT_FILE` をそこへ向ける。`nix-daemon.sh` は設定済みの値を上書きしない。
- Nix の `ssl-cert-file` もそこへ向ける。書く場所はユーザー設定の `~/.config/nix/nix.conf`。

`/etc/nix/nix.custom.conf` に書く方法は効かなかった。`/etc/nix/nix.conf` は
`!include nix.custom.conf` より**後ろ**で `ssl-cert-file = /etc/nix/macos-keychain.crt` を
設定していて、custom 側の値はこれに上書きされる。`nix.conf` 自体は Determinate Nix が
置き換えるので編集できず、`macos-keychain.crt` もデーモンが起動するたびに書き直される。
ユーザー設定は `/etc/nix/nix.conf` の後に読まれるので、こちらは効く。

ユーザー設定が効くのはクライアント側の取得 (flake 入力、`builtins.fetchurl` など) で、
本題の危険はここで塞がる。デーモン側は `macos-keychain.crt` のまま残る。ただ、デーモンが
取得するのは署名を検証するバイナリキャッシュと、ハッシュ固定の fixed-output derivation
だけなので、TLS が破られても改ざんは通らない。

`nix.custom.conf` に一度書き足した `ssl-cert-file` の行は、効かないと分かった時点で
削除した。`nix.custom.conf` はインストール時の状態に戻っている。

#### Determinate Systems への報告

2026-10-26 に `security@flakehub.com` (Determinate Systems のセキュリティ窓口) へ
メールで非公開報告した。同じ内容の既存 issue は DeterminateSystems org と NixOS/nix には
なかった。公開する場合の報告先は、公式の振り分けどおり `DeterminateSystems/nix-src`。

報告した内容は、既定のバンドルで `builtins.fetchurl` が偽造証明書を受け入れること、
macOS 標準の TLS は拒否すること、`ssl-cert-file` は Determinate の管理項目でシステム全体の
回避策がないこと。flake 入力の取得経路は未検証として伝えた。返信があったら、ここに追記する。

確認方法 (2026-10-26 に実施し、期待どおりになった):

```sh
nix config show ssl-cert-file   # ~/.local/share/nix-cacert/ca-bundle.crt
# 失敗すること (verify result: unable to get local issuer certificate)
nix eval --impure --refresh --expr 'builtins.fetchurl "https://dv-g3b-emudhra.we-have-a-problem.com/?x=1"'
```

対応前は、同じ `builtins.fetchurl` が両 URL とも成功していた。

WSL2 の 2 台はシステムストア (`/etc/ssl/certs/ca-certificates.crt`) を指していて、
apt の `ca-certificates` 更新で修正済みなので、この対応は不要。

## macOS 側で行ったこと (記録)

- `CURL_SSL_BACKEND=secure-transport` を `.zshenv` に追加(`home-manager/zsh/default.nix`)。
  macOS 同梱 curl は MultiSSL ビルドで既定バックエンドが LibreSSL のため、失効を見ない
  `/etc/ssl/cert.pem` を参照していた。SecureTransport なら Apple 側の失効判定が効く。
- `brew upgrade ca-certificates` (2026-10-20)。
- `/etc/ssl/cert.pem` から `emSign ECC Root CA - G3` と `AAA Certificate Services` を削除
  (128 → 126 本)。バックアップは `/etc/ssl/cert.pem.orig` と `.bak.<timestamp>`。
- Python を mise 管理へ移した。macOS 同梱 Python は 3.9 系で、pip 26.2.2 が要求する
  3.10 以上に届かないため。

## `minipc` (WSL2) で行ったこと (記録)

2026-10-22 に実施。

- `ca-certificates` は作業前から修正版 `20260816ubuntu0.24.04.1` だった
  (`apt-cache policy` の Candidate も同じ)。apt の再実行は不要だったので省いた。
- `home-manager switch --flake .#akihiro@wsl` で mise の `python = "3.14"` を反映した。
- `mise install node@24 go@1.26 python@3.14` の到達バージョン:

  | ツール | 到達 |
  |---|---|
  | Node.js | 24.22.1 |
  | Go | 1.26.10 |
  | Python | 3.14.8 |
  | pip | 26.2.2 |
  | certifi | 2026.10.19 (pip 同梱の `pip._vendor.certifi`。単体の certifi パッケージは未導入) |

- `rustup self update && rustup update`: rustup 1.29.0 → 1.29.2、stable は rustc 1.92.0 → 1.99.1。
  rustup の本体は `~/.cargo/bin/rustup` にあるが、PATH では mise の `rustup` shim が先に
  見つかって `No version is set for shim: rustup` で失敗する。本体を絶対パスで呼んで実行した。
- 検証: 2つの URL とも `curl: (60) unable to get local issuer certificate` で失敗した (期待どおり)。
  ここでの curl は `/usr/bin/curl`。
- この WSL では `NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt` (修正済みのシステムストア)
  を指していて、「Nix 管理で未達の項目」に書いた `nss-cacert` は使われていなかった。
- 未達: `mise 2026.6.11` / `uv 0.11.25` (Nix 管理。nixpkgs が追いつくのを待つ方針どおり手を付けていない)。
- Windows 側 (Windows Update、ブラウザの更新と再起動) は手作業で実施した。

## `aki-thinkpad` (WSL2) で行ったこと (記録)

2026-10-22 に実施。Ubuntu 24.04.4 LTS。

- `ca-certificates` は作業前が `20260601~24.04.1` で**修正版に達していなかった**。
  さらに `apt-cache policy` の Candidate も同じ古いバージョンを指していて、apt の
  インデックスが古かった。`minipc` と違い **`sudo apt update` が必須**で、これを省くと
  `apt install --only-upgrade` は何もせず終わる。update 後に Candidate が
  `20260816ubuntu0.24.04.1` に変わり、install で `4 added, 5 removed` となった。
- この更新で削除されたのは `emSign ECC Root CA - G3` のみだった (121 → 120 本)。
  `AAA Certificate Services` はこのマシンには作業前から存在しなかった。
  `emSign ECC Root CA - C3` / `emSign Root CA - C1` / `emSign Root CA - G1` は更新後も
  信頼ストアに残る。つまり本書の「emSign 系ルートが**両方**削除される」(手順 2) は
  正確ではなく、Ubuntu の修正版が外すのは G3 だけだった。残る 3 枚を手で消すべきかは
  未確認。少なくとも手順 5 の検証は両 URL とも失敗するので、追加のルート無効化は
  行わなかった。
- `home-manager switch --flake .#akihiro@wsl` で mise の `python = "3.14"` を反映した。
  このとき `~/.claude/settings.json` が実ファイル (9/20 付) として残っていて
  `mkOutOfStoreSymlink` と衝突し、switch が `would be clobbered` で失敗した。
  中身は repo 版にない `model` / `effortLevel` / `modelSettings` を持ち、逆に repo 側の
  `attribution` / `language` / marketplace 設定を欠く古いコピーだったので、repo を
  source of truth として `-b backup` で `~/.claude/settings.json.backup` へ退避させた。
- `mise install node@24 go@1.26 python@3.14` の到達バージョン:

  | ツール | 到達 |
  |---|---|
  | Node.js | 24.22.1 |
  | Go | 1.26.10 |
  | Python | 3.14.8 |
  | pip | 26.2.2 |
  | certifi | 2026.10.19 (pip 同梱の `pip._vendor.certifi`) |

- rustup は**このマシンには未導入**だったので手順 4 は該当なし (新規導入もしていない)。
- 検証: 2つの URL とも `curl: (60) unable to get local issuer certificate` で失敗した
  (期待どおり)。ここでの curl は `/usr/bin/curl` (OpenSSL 3.0.13)。
- `NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt` を指していて、`minipc` と同じく
  「Nix 管理で未達の項目」の `nss-cacert` は使われていなかった。
- 未達: `mise 2026.6.11` / `uv 0.11.25` (Nix 管理。nixpkgs 待ちの方針どおり手を付けていない)。
- Windows 側 (Windows Update、ブラウザの更新と再起動) は手作業で実施した。

## 参考

- [発見者による一次情報・パッチ版一覧](https://emudhra.we-have-a-problem.com/)
- [Ubuntu: eMudhra CA compromise fixes available](https://ubuntu.com/blog/emudhra-ca-compromise-fixes-available)
- [Mozilla Security Blog](https://blog.mozilla.org/security/2026/10/20/protecting-firefox-users-following-the-compromise-of-emudhra-intermediate-certificates/)
- [Google Security Blog](https://blog.google/security/protecting-chrome-and-android-users-from-compromised-emudhra-intermediate-ca-certificates/)
- [Bugzilla 2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449)
