# actions

複数の GitHub Actions action をサブディレクトリ単位でホストするリポジトリ。

## リリース・バージョニングの方針

- タグ・バージョンはサブディレクトリ（action）ごとに分けず、**リポジトリ全体で1系統**（`vX.Y.Z`）にする。
- tagpr の `tagPrefix`（monorepo 向けの独立バージョニング機能。例: `foo` → `foo/v1.2.3` のようなタグを打てる）は**あえて使わない**。
  - 理由: `tagPrefix` を使うと `uses: yagihash/actions/foo@foo/v1.2.3` のようにタグ名にもパスと同じ文字列が登場し、`uses:` のパス指定とタグ指定が紛らわしくなる。利用者から見て `uses: yagihash/actions/foo@vX.Y.Z` とシンプルに参照できる方を優先する。
- action ごとの変更を区別したい場合は、タグを分けるのではなく **CHANGELOG.md / リリースノートの表示だけを action ごとに分ける**（後述）。
- `.tagpr` の `release = true` により、タグ付けと同時に GitHub Release も作成する。リリースノートの内容は CHANGELOG.md と同じ `.github/release.yml` のカテゴリ設定に従う。
- このリポジトリは [Immutable releases](https://github.blog/changelog/2025-10-28-immutable-releases-are-now-generally-available/) が有効（`repos/actions.yaml` の `release_immutability: true`）。Immutable releases は「実際に Release を作成したタグ」だけを削除・force-move 不可にする仕様なので、1バージョンにつき1回しかタグを打たない今の運用（tagpr の通常のフロー）とは相性が良く、特に問題は無い。
  - **注意**: 将来 `v1` のようなメジャーバージョンの rolling tag（最新の `v1.x.x` に force-move し続けるタグ、`ghat` の `release.yml` がやっている手法）を追加したくなった場合、その `v1` タグ自体には GitHub Release を紐付けてはいけない。Release を作った時点でそのタグが immutable になり、二度と force-move できなくなるため。

## CHANGELOG / リリースノートの生成

- `.tagpr` で `changelog = true` にしており、tagpr が `CHANGELOG.md` を生成する。
- 生成内容は `.github/release.yml` の `changelog.categories` で制御している。**catch-all の `"*"` カテゴリを意図的に入れていない**ため、カテゴリに一致しないラベルの PR（ラベルなしを含む）は CHANGELOG に一切表示されない。これは GitHub の自動生成リリースノートの仕様（`"*"` を入れない限り、未マッチの PR は単に出力されない）を利用した include-only 運用。
- 新しい action を追加したときは、その action の変更を CHANGELOG 上で区別できるように以下を行う:
  1. `.github/labeler.yml` に `action:<name>` ラベルを付与するパスルールを追加する（`.github/workflows/labeler.yml` が PR に自動でラベルを付ける）
  2. `.github/release.yml` に `action:<name>` ラベル用のカテゴリを追加する
  - これによりタグ・バージョンは1系統のまま、CHANGELOG のセクションだけ action ごとに分かれる。

## README の pin 自動更新

- 各 action の README には利用例として `uses: yagihash/actions/<name>@<SHA> # vX.Y.Z` の形式で pin した参照を載せる。
- リリースが作成されるたびに `.github/workflows/update-readme-pins.yml` が `pinact run -u` を各 action ディレクトリ（`.github/` 直下は対象外）の README に対して実行し、最新リリースへの pin に更新した上で PR を自動で立てる。
- この PR も `contents: write` が必要なので、`tagpr.yml` と同様 `ghmint-action`（`policy: writer`）でトークンを取得している。

## action ごとの動作確認（CI）

- 各 action に変更が入った際は、実際にその action を GitHub Actions 上で動かして PR 上で動作確認することを原則とする。
- 各 action 用の動作確認ワークフローは `.github/workflows/<action名>_ci.yml` という命名にする。
- トリガーは `paths: ["<action名>/**"]` で、その action のディレクトリが変更されたときだけ実行されるようにする。branch protection の required status check にはなっていないため、`ghalint.yml` のような `paths-filter` + `if` によるスキップ方式（required check がパス不一致で消えるのを防ぐための仕組み）は不要で、trigger レベルの `paths:` で十分。
- ワークフロー内では `uses: ./<action名>` でローカルの action を直接呼び出し、実際に実行して確認する（`ghmint-action` の `test.yml` と同じ発想）。

## ghmint 連携（tagpr の認証）

- `.github/workflows/tagpr.yml` は [yagihash/ghmint-action](https://github.com/yagihash/ghmint-action) 経由で `policy: writer` の GitHub App トークンを取得している。
- ghmint サーバーはこのリポジトリの `.github/ghmint/writer.rego` を読み、OIDC トークンの `sub` claim を評価して許可判定する。
- **注意**: このリポジトリは 2026-07-15 以降に作成されたため、OIDC の `sub` claim が新フォーマット（`repo:owner@<ownerID>/repo@<repoID>:ref:...`。owner/repo の recycling 対策で不変な数値IDが付与される）になる。旧フォーマット（`repo:owner/repo:ref:...`）を前提にした `input.sub == "repo:yagihash/actions:ref:refs/heads/main"` のような単純な文字列一致は**マッチしない**（`allow` が false になり、`ghmint returned 403: token issuance denied by policy` で失敗する）。
  - 参考: https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/
  - `writer.rego` では実際の owner ID (`yagihash` = `1553908`) / repo ID (`actions` = `1309947540`) を固定値として埋め込んでいる。`(@[0-9]+)?` のような任意の数値IDを許容する正規表現にしてはいけない — それは新フォーマットが対策しようとしている「名前の recycling」耐性を無効化してしまう。
  - ghmint サーバー側の実装は、「ポリシーファイルの取得失敗」と「`allow` が false」を同じ汎用エラー（`token issuance denied by policy`）にまとめてしまうため、実際の拒否理由は ghmint サーバー自身のログ（Cloud Logging、`yagihash-lab` プロジェクトの `sts` サービス）でしか確認できない。ghmint 由来のエラーで詰まったら、まずそちらのログを確認するのが早い。

## branch protection

- `yagihash/.github`（gh-infra 管理）の `repos/actions.yaml` に、このリポジトリの branch protection ruleset が定義されている。`main` への PR は `ghalint` / `actionlint` の required status check が必須（`.github/workflows/ghalint.yml` のジョブ名と一致させる必要がある）。
- code owner review は要求していない（個人運用のリポジトリのため、CODEOWNERS は置いていない）。
