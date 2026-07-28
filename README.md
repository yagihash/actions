# actions

複数の GitHub Actions action をサブディレクトリ単位でホストするリポジトリ。

## 構成

各 action は自身のディレクトリに `action.yml`・README・(必要なら) テストワークフローを持つ。

リポジトリ全体に対して以下のワークフローが共通で動く:

- `.github/workflows/ghalint.yml` — 全 action 共通のセキュリティチェック（[ghalint](https://github.com/suzuki-shunsuke/ghalint) / [actionlint](https://github.com/rhysd/actionlint)）
- `.github/workflows/tagpr.yml` — [tagpr](https://github.com/Songmu/tagpr) によるリリース（タグ付け）自動化