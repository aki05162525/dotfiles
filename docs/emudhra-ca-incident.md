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
| `2022-X0213` | `takagi@mac` | macOS / Apple Silicon | 完了 (2026-10-22)。2026-10-26 に Determinate Nix 3.24.1 へ更新し、Nix の TLS 拒否を確認。2026-10-29 に mise 2026.10.17 を適用し、要求バージョンに到達 |
| `minipc` | `akihiro@wsl` | WSL2 Ubuntu 24.04 | 2026-10-29 に mise 2026.10.17 を適用し、要求バージョンに到達。curl の TLS 拒否も再確認 |
| `aki-thinkpad` | `akihiro@wsl` | WSL2 Ubuntu 24.04 | 完了 (2026-10-22)。2026-10-26 に uv 更新と TLS 拒否を確認。mise はこのマシンでの更新待ち (修正版は lock に反映済み) |

各マシンで作業したら、自分の `hostname` を記入して状態を更新する。
行が足りなければ足す。

### 2022-X0213 (macOS) の mise 更新 (2026-10-29)

- `bec2c93` を pull し、`home-manager switch --flake .#takagi@mac` が成功した。
- `~/.nix-profile/bin/mise --version` は `2026.10.17` を返した。
- switch 前から開いていたシェルでは、mise のシェル関数が旧バイナリ (`2026.10.3`) のパスを保持したままだった。新しいシェルを開くか `exec zsh` で解消する。
- TLS 拒否の再確認と mise 自身による接続テストは実施していない。

### minipc の mise 更新 (2026-10-29)

- `flake.lock` の nixpkgs を `31ecbac`、home-manager を `095fef2` に更新した。
- `home-manager switch --flake .#akihiro@wsl` が成功し、`mise --version` は `2026.10.17` を返した。
- 公式リリースノートで、このバージョンに eMudhra CA の信頼削除が含まれることを確認した。
- `/usr/bin/curl` は検証用の 2 URL をいずれも証明書エラー (終了コード 60) で拒否した。これはシステムの TLS 検証であり、mise 自身による接続テストは実施していない。
- Linux の `nix flake check`、両 OS の構成評価 (`--all-systems --no-build`)、WezTerm activation の回帰テスト 8 件が成功した。macOS の実機適用は未実施。

### minipc の追加確認 (2026-10-26)

`ba08b7c` を pull し、`home-manager switch --flake '.#akihiro@wsl'` を実行した。

- uv は `0.13.4` に更新済み。
- Ubuntu の `ca-certificates` は `20260816ubuntu0.24.04.1` で、Nix の `ssl-cert-file` は `/etc/ssl/certs/ca-certificates.crt` を参照している。
- 下記「検証」の 2 URL は、どちらも curl が証明書エラー (終了コード 60) で拒否した。
- mise は `2026.10.3` で、要求バージョン `2026.10.17` には未達。

### aki-thinkpad の追加確認 (2026-10-26)

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

## Nix 管理ツールの対応状況

`uv` と `mise` は Nix 管理なので、修正版を含む nixpkgs に `flake.lock` を更新して反映する。
2026-10-29 に mise の修正版を含む nixos-unstable `31ecbac` へ更新した。
他のマシンでは pull 後に各構成で `home-manager switch` し、`mise --version` が 2026.10.17 以上であることを確認する。

| 項目 | 状態 |
|---|---|
| uv 0.13.4 | 済。nixos-unstable `3ec6363` (2026-10-23) に到達し、2026-10-26 に `flake.lock` を更新 |
| mise 2026.10.17 | 到達済み。[nixpkgs#577218](https://github.com/NixOS/nixpkgs/pull/577218) を含む nixos-unstable `31ecbac` へ 2026-10-29 に lock を更新。マシン別の適用状況は上表を参照 |
| nixpkgs の `cacert` | 3.131.1 (3.126 から更新)。`emSign ECC Root CA - G3` / `- C3` / `Root CA - C1` が外れ、`emSign Root CA - G1` だけ残る。`AAA Certificate Services` (ラベルは `Comodo AAA Services root`) は残るが、TRUSTED CERTIFICATE 形式でサーバー認証の信頼を外されている |

channel 到達の確認方法 (2026-10-29 に `behind` を確認):

mise が channel に入ったかは、マージコミットと channel の比較で確認できる
(`behind` か `identical` なら到達済み)。

```sh
gh api repos/NixOS/nixpkgs/compare/nixos-unstable...7acaf38 --jq .status
```

今後も依存を更新するときは、次のコマンドで `flake.lock` を更新して各マシンで反映する。

```sh
cd ~/dotfiles && nix flake update nixpkgs home-manager && home-manager switch --flake .#<構成>
```

`herdr` を対象から外しているのは、2026-10-26 時点で `nix flake update` が herdr を
現行の lock より古いコミットへ戻してしまうため。GitHub API のレート制限で
「using cached version」と出たら、更新は古いキャッシュで行われている。その場合は
`NIX_CONFIG="access-tokens = github.com=$(gh auth token)"` を付けて実行し直す。

### macOS: Nix の CA バンドル (Determinate Nix 3.24.0 で修正済み)

macOS 機の Nix は、2 か所で古い CA バンドルを使っていた。

| 使う側 | 参照先 | 中身 (2026-10-26 時点) |
|---|---|---|
| Nix 本体 (クライアントとデーモン) | `/etc/nix/nix.conf` の `ssl-cert-file = /etc/nix/macos-keychain.crt` | Determinate Nix が macOS キーチェーンを PEM に書き出したもの。3.21.0 では G3 と AAA を含んでいた |
| シェルの `NIX_SSL_CERT_FILE` (nixpkgs 由来のツール) | `/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt` | Nix 本体付属の `nss-cacert-3.121`。emSign 4 枚がすべて残る。3.24.1 に上げても変わらない |

Determinate Nix 3.21.0 のままだと、Nix 自身の `builtins.fetchurl` が検証用の 2 URL を
**どちらも取得できてしまった**。macOS 標準の TLS (NSURLSession を使う `nscurl`) は
同じ URL を `-1202` / `-9807` で拒否する。

これは Determinate Nix **3.24.0 (2026-10-22) で修正済み**だった
([status ページ](https://status.determinate.systems/incidents/f7cd1dd4-f0d1-4960-b787-e8077e6d4885))。
3.24.1 (2026-10-25) には brotli の脆弱性 (CVE-2026-111497) の修正も入っているので、
macOS 機では必ず上げる。

```sh
sudo determinate-nixd upgrade
```

3.24.1 に上げると `macos-keychain.crt` が書き直され、G3 と AAA が含まれなくなった。
既定の設定のまま、2 URL とも `verify result: unable to get local issuer certificate (20)` で
拒否されることを確認した (2026-10-26)。

```sh
nix config show ssl-cert-file   # /etc/nix/macos-keychain.crt
# 失敗すること
nix eval --impure --refresh --expr 'builtins.fetchurl "https://dv-g3b-emudhra.we-have-a-problem.com/?x=1"'
nix eval --impure --refresh --expr 'builtins.fetchurl "https://dv-g3b-aaa-emudhra.we-have-a-problem.com/?x=1"'
```

シェルの `NIX_SSL_CERT_FILE` のほうはアップグレード後も古いままなので、
`home-manager/cacert/default.nix` (macOS 限定) で nixpkgs の `cacert` に向け直している。
`~/.local/share/nix-cacert/ca-bundle.crt` に置き、Home Manager の世代が GC root になる。

#### 経緯 (記録)

3.24.0 の修正に気付かないまま、次の回り道をした。

- `/etc/nix/nix.custom.conf` に `ssl-cert-file` を書いたが効かなかった。`/etc/nix/nix.conf` は
  `!include nix.custom.conf` より後ろで `ssl-cert-file` を設定しているため。この行は削除済み。
- 代わりにユーザー設定 `~/.config/nix/nix.conf` で `ssl-cert-file` を上書きしていた。
  3.24.1 で既定が直ったので外した。上書きしたままだと、キーチェーンにある MDM の証明書も
  Nix から外れてしまう。
- 2026-10-26 に `security@flakehub.com` へメールで報告し、「3.24.0 で修正済み」と返信をもらった。
  GitHub の issue / PR しか探しておらず、Determinate のリリースノートと status ページを
  確認していなかった。次からは、ベンダーのリリースノートと status ページを先に見る。

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
  を指していて、「Nix 管理ツールの対応状況」に書いた `nss-cacert` は使われていなかった。
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
  「Nix 管理ツールの対応状況」の `nss-cacert` は使われていなかった。
- 未達: `mise 2026.6.11` / `uv 0.11.25` (Nix 管理。nixpkgs 待ちの方針どおり手を付けていない)。
- Windows 側 (Windows Update、ブラウザの更新と再起動) は手作業で実施した。

## 参考

- [mise 2026.10.17 リリースノート (eMudhra CA の信頼削除)](https://github.com/jdx/mise/releases/tag/v2026.10.17)

- [発見者による一次情報・パッチ版一覧](https://emudhra.we-have-a-problem.com/)
- [Ubuntu: eMudhra CA compromise fixes available](https://ubuntu.com/blog/emudhra-ca-compromise-fixes-available)
- [Mozilla Security Blog](https://blog.mozilla.org/security/2026/10/20/protecting-firefox-users-following-the-compromise-of-emudhra-intermediate-certificates/)
- [Google Security Blog](https://blog.google/security/protecting-chrome-and-android-users-from-compromised-emudhra-intermediate-ca-certificates/)
- [Bugzilla 2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449)
