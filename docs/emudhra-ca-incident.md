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
| (macOS機) | `takagi@mac` | macOS / Apple Silicon | 完了 (2026-10-22) |
| `minipc` | `akihiro@wsl` | WSL2 Ubuntu 24.04 | WSL 内は完了 (2026-10-22)。Windows 側は手作業で実施 |
| | `akihiro@wsl` | WSL2 Ubuntu | **未対応** |

各マシンで作業したら、自分の `hostname` を記入して状態を更新する。
行が足りなければ足す。

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

`uv` と `mise` は Nix 管理だが、nixpkgs がまだ要求バージョンに追いついていない
(2026-10-22 時点で `uv 0.13.1` / `mise 2026.10.3` / `cacert 3.126`)。
`NIX_SSL_CERT_FILE` が指す `nss-cacert` にも `emSign ECC Root CA - G3` が残る。

追いついたら両マシンで一度に解決する。

```sh
cd ~/dotfiles && nix flake update && home-manager switch --flake .#<構成>
```

実リスクは限定的で、このバンドルを使うのは主に `nix` 自身(接続先は
cache.nixos.org と github.com)。成立には経路の乗っ取りが前提になる。

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
- Windows 側 (Windows Update、ブラウザの更新と再起動) は手作業で実施する。

## 参考

- [発見者による一次情報・パッチ版一覧](https://emudhra.we-have-a-problem.com/)
- [Ubuntu: eMudhra CA compromise fixes available](https://ubuntu.com/blog/emudhra-ca-compromise-fixes-available)
- [Mozilla Security Blog](https://blog.mozilla.org/security/2026/10/20/protecting-firefox-users-following-the-compromise-of-emudhra-intermediate-certificates/)
- [Google Security Blog](https://blog.google/security/protecting-chrome-and-android-users-from-compromised-emudhra-intermediate-ca-certificates/)
- [Bugzilla 2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449)
