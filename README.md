# actions

複数の GitHub Actions action をサブディレクトリ単位でホストするリポジトリ。

## 構成

各 action は自身のディレクトリに `action.yml`・README・(必要なら) テストワークフローを持つ。

リポジトリ全体に対して以下のワークフローが共通で動く:

- `.github/workflows/ghalint.yml` — 全 action 共通のセキュリティチェック（[ghalint](https://github.com/suzuki-shunsuke/ghalint) / [actionlint](https://github.com/rhysd/actionlint)）
- `.github/workflows/tagpr.yml` — [tagpr](https://github.com/Songmu/tagpr) によるリリース（タグ付け）自動化。バージョン・タグはリポジトリ全体で1系統（`vX.Y.Z`）
- `.github/workflows/labeler.yml` — 変更されたディレクトリに応じて PR に `action:<name>` ラベルを自動付与

## 現在ホストしている action

- [`dump-oidc-token`](./dump-oidc-token) — GitHub Actions の OIDC トークンを取得してその claims を表示する

## 新しい action を追加するとき

1. `<name>/` ディレクトリに action 本体（`action.yml` など）を追加する
2. `.github/workflows/<name>_ci.yml` として、その action を実際に Actions 上で動かして動作確認するワークフローを追加する（PR で対象 action に変更が入ったときに実行されるようにする。パスのフィルタは trigger レベルの `paths:` でよい — required status check ではないため）
3. `.github/labeler.yml` に `action:<name>` ラベルのルールを追加する
4. `.github/release.yml` に `action:<name>` ラベル用のカテゴリを追加する（CHANGELOG.md でその action の変更が独立したセクションに表示されるようにするため）

タグ・バージョンは分割せずリポジトリ全体で1系統のままにする。詳細は [CLAUDE.md](./CLAUDE.md) を参照。