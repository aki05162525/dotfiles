# ツール管理の役割分担

各レイヤーが下の層を管理する階層構造になっている。

## 全体像

```
Nix (Home Manager)
  └─ mise本体, 各種CLI(git, gh, direnv, starship, zellij, jq, ...) を管理
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
| **Nix (Home Manager)** | グローバルCLIツールの導入と設定の宣言的管理 | mise本体, git, gh, direnv, starship, zellij など | `~/dotfiles/home-manager/` |
| **mise** | 言語ランタイムのバージョン管理 | Node, Go, Python, Terraform など | グローバル: `~/.config/mise/config.toml` (Nix管理) / プロジェクト: `.tool-versions` |
| **corepack** | Node エコシステムのパッケージマネージャ管理 | pnpm, yarn のバージョン | プロジェクトの `package.json` の `packageManager` フィールド |
| **direnv** | プロジェクト別の環境変数 | DATABASE_URL, API_KEY など | プロジェクトの `.envrc` |
| **各パッケージマネージャ** (pnpm, npm, cargo, go等) | プロジェクト依存ライブラリ | npm パッケージ, crate など | プロジェクトの `package.json`, `Cargo.toml` など |

## なぜこの構造か

- **責務の分離**: 各ツールが得意分野に専念する
- **下位互換性**: 例えば pnpm を Nix で管理すると、プロジェクトごとに異なるバージョンの pnpm を使えなくなる。corepack に任せれば自動で切り替わる
- **再現性**: 上位レイヤーほど宣言的(Nix)、下位レイヤーほどプロジェクトローカル(`.tool-versions`, `package.json`)で、それぞれ最適なスコープで管理される

## よくある疑問

### Q. pnpm は Nix で入れるべき?

**A. 入れない。corepack に任せる。**

理由: pnpm はプロジェクトごとにバージョンを揃えたい(同じバージョンで `pnpm install` しないと lock file の差分が出る)。corepack は `package.json` の `packageManager` フィールドを読んで自動切替してくれる。Nix で固定バージョンを入れると、この自動切替を妨げる。

### Q. Node のバージョンを mise でなく Nix で管理するべき?

**A. mise が向いている。**

理由: プロジェクトごとに `.tool-versions` で「このプロジェクトは Node 18」「このプロジェクトは Node 22」のように切り替えたいケースが多い。Nix の devShell でも実現できるが書き方が独特で、チームで共有するときに摩擦がある。mise なら `.tool-versions` を git に入れるだけで済む。

### Q. グローバルツール(jq, fzf, ripgrep等)は mise と Nix どっち?

**A. Nix。**

理由: これらは「全マシンで同じバージョンが入っていればよい」もので、プロジェクト別の切替は不要。Nix で管理するとflake.lockで完全再現できる。mise だと各マシンで `mise install` が必要だが、Nix なら `home-manager switch` 1発。

### Q. AI CLI (claude, codex, gemini) は何で管理?

**A. 公式インストーラ(npm or curl)のまま。Nix で管理しない。**

理由: 自己更新する。Nix store は read-only なので auto-update が `EROFS` で失敗する。リリース頻度も高く nixpkgs が追いつかない。

### Q. Rust (cargo, rustc) は?

**A. rustup のまま。**

理由: rustup は Rust 公式のツールチェーン管理機構で、`stable`/`nightly` の切替や `rust-analyzer` 連携が rustup ベースで設計されている。Nix で代替できるが、エコシステムの恩恵を失う。
