# ツール管理の役割分担

Nix は共通 CLI、mise は言語ランタイム、corepack は pnpm / yarn を管理する。

## 全体像

```
Nix (Home Manager)
  └─ mise本体, 各種CLI(git, gh, direnv, starship, jq, ...) を管理
      └─ mise
          └─ Node, Go など言語ランタイムのバージョンを管理
              └─ corepack (Nodeに同梱)
                  └─ pnpm, yarn のバージョンを管理
                      └─ pnpm install / npm install
                          └─ プロジェクト依存パッケージ
```

## レイヤー別役割

| レイヤー | 役割 | 何を管理するか | 設定場所 |
|---|---|---|---|
| Nix (Home Manager) | グローバルCLIツールの導入と設定の宣言的管理 | mise本体, git, gh, direnv, starship など | `~/dotfiles/home-manager/` |
| mise | 言語ランタイムのバージョン管理 | Node, Go, Python, Terraform など | グローバル: `~/.config/mise/config.toml` (Nix管理) / プロジェクト: `.tool-versions` |
| corepack | pnpm / yarn のバージョン管理 | pnpm, yarn のバージョン | プロジェクトの `package.json` の `packageManager` フィールド |
| direnv | プロジェクト別の環境変数 | DATABASE_URL, API_KEY など | プロジェクトの `.envrc` |
| 各パッケージマネージャ (pnpm, npm, cargo, go等) | プロジェクト依存ライブラリ | npm パッケージ, crate など | プロジェクトの `package.json`, `Cargo.toml` など |

## なぜこの構造か

共通 CLI は Nix で揃え、プロジェクトごとに異なるランタイムとパッケージマネージャのバージョンは `.tool-versions` と `package.json` で指定する。

## よくある疑問

### pnpm

corepack に任せる。`package.json` の `packageManager` でバージョンを揃え、lock file の不要な差分を防ぐ。Nix で固定すると、この自動切替を妨げる。

### Node

mise で管理し、プロジェクトごとの `.tool-versions` を git で共有する。Nix の devShell でも切り替えられるが、この構成では `.tool-versions` を使う。

### グローバル CLI

jq / fzf / ripgrep などは Nix で管理する。プロジェクト別の切替は不要で、`flake.lock` と `home-manager switch` で各マシンに同じバージョンを導入できる。

### AI CLI

claude / codex / gemini は公式インストーラで管理する。Nix store は読み取り専用で自己更新が `EROFS` で失敗するため、Nix には入れない。

### T3 Code CLI

公式インストーラで `~/.local/bin/t3` に導入し、`t3 update` で更新する。

Home Manager は `~/.local/bin` の PATH 設定を管理する。
自己更新できるよう CLI 本体は Nix store に置かず、Desktop が配置する WSL runtime のハッシュ付きパスも固定しない。
導入手順は [セットアップの T3 Code CLI](./setup.md#t3-code-cli) を参照。

### Rust

cargo / rustc は Rust 公式の rustup で管理する。`stable` / `nightly` の切替や `rust-analyzer` との連携も rustup に任せる。
