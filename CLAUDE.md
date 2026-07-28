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
- **注意（実例で確認済み）**: 1つの PR が複数の `action:<name>` ラベルを持っていても、CHANGELOG 上では `.github/release.yml` の `changelog.categories` リストで**最初にマッチした1カテゴリにしか表示されない**（GitHub の自動生成リリースノートの仕様。複数カテゴリに重複表示はされない）。
  - 実例: PR #14 で `signed-commit` と `create-pull-request` を1つの PR にまとめて追加したところ、両方のラベルが付いたにもかかわらず CHANGELOG には（`release.yml` でリストの先に書いてあった）`signed-commit` セクションにしか載らなかった（`create-pull-request` セクションは空のまま）。
  - そのため、**複数の action を新規追加するときは、CHANGELOG 上でそれぞれ独立して見せたいなら PR を action ごとに分ける**こと。1つの PR にまとめる場合は、どれか1カテゴリにしか表示されないことを許容した上で行う。
  - **Renovate にも同じ注意が必要**: `renovate.json` の `packageRules` には `matchManagers: ["github-actions"]` を対象にリポジトリ全体で1グループにまとめて `automerge: true` するルールがある。現時点ではどの action の `action.yml` も外部 action の `uses:` を参照していない（`.github/workflows/*_ci.yml` 側の `actions/checkout` bump は `<name>/` 配下ではないので `action:<name>` ラベルが付かず、単に `Dependencies` カテゴリに入るだけで問題ない）。ただし将来複数の action の `action.yml` が外部 action を参照するようになると、Renovate が1つの PR に複数 `action:<name>` ラベルをまとめて自動マージし、人間のチェックなしに同じ CHANGELOG 欠落が起きうる。そうなったタイミングで `renovate.json` の該当 `packageRules` を action ディレクトリ単位（`matchFileNames` 等）でグループ分けし直すことを検討する。

## README の pin 自動更新

- 各 action の README には利用例として `uses: yagihash/actions/<name>@<SHA> # vX.Y.Z` の形式で pin した参照を載せる。
- リリースが作成されるたびに `.github/workflows/update-readme-pins.yml` が `pinact run -u` を各 action ディレクトリ（`.github/` 直下は対象外）の README に対して実行し、最新リリースへの pin に更新した上で PR を自動で立てる。
- この PR も `contents: write` が必要なので、`tagpr.yml` と同様 `ghmint-action`（`policy: writer`）でトークンを取得している。
- **新しい action を追加するときの README 利用例のバージョン指定**: 追加時点でその action はまだどのタグにも含まれていない（タグ・バージョンはリポジトリ全体で1系統なので、新規 action 用の専用タグは存在しない）。このとき example の `uses:` に書くべきなのは「まだ存在しない将来のバージョンの予想値」ではなく、**その時点で実際に存在している最新タグ**（例: `v0.0.2`）。
  - 実例: `dump-oidc-token/README.md` は当初 `@v1.0.0`（存在しないタグ）を参照しており、これは pinact による解決に失敗する状態だった。実際に自動ワークフローがこれを検知して失敗する前に手動で `v0.0.2`（当時実在した最新タグ）に修正した（`Pin the README usage example to a real tag/SHA` コミット）。**存在しないタグを書くと pinact が失敗する、というのは実例で確認済み**。
  - 「実在する古いタグを書いておけば、次のリリース時に `pinact run -u` が自動的に最新版へ向け直してくれる」という点も**実例で確認済み**: v0.0.3 リリース後の `update-readme-pins.yml` 実行（PR #19）で `dump-oidc-token/README.md` の pin が `v0.0.2` の SHA から `v0.0.3` の SHA に自動更新された。新規追加した `signed-commit`/`create-pull-request` の未 pin な参照（`@v0.0.2` や `actions/checkout@v5` など）も、このタイミングで正しく最新版に pin された。
- **`update-readme-pins.yml` が作る PR には意図的にラベルを一切付けない**: この PR は毎回すべての action の README を一括で書き換えるため、`.github/labeler.yml` のパスベースの自動ラベリングをそのまま適用すると存在する `action:<name>` ラベルが全部付いてしまい、CHANGELOG 上「特定の1 action の変更」であるかのように誤って分類されてしまう（しかも「最初にマッチした1カテゴリにしか表示されない」仕様と組み合わさるとどの action のセクションに出るか予測できない）。また中身は pin コメントの書き換えだけで実際の依存関係バンプでもないので `dependencies` ラベルも意味的に不適切。そのため:
  - `.github/workflows/labeler.yml` は `head.ref` が `update-readme-pins-` で始まる PR をジョブレベルの `if:` でスキップし、そもそも `action:<name>` ラベルを付けさせない。
  - `update-readme-pins.yml` 自身も `create-pull-request` 呼び出しに `labels:` を指定しない。
  - 結果としてこの PR にはラベルが一切付かず、CHANGELOG の include-only 運用により自動的に非表示になる（これは意図した挙動）。

## action ごとの動作確認（CI）

- 各 action に変更が入った際は、実際にその action を GitHub Actions 上で動かして PR 上で動作確認することを原則とする。
- 各 action 用の動作確認ワークフローは `.github/workflows/<action名>_ci.yml` という命名にする。
- トリガーは `paths: ["<action名>/**"]` で、その action のディレクトリが変更されたときだけ実行されるようにする。branch protection の required status check にはなっていないため、`ghalint.yml` のような `paths-filter` + `if` によるスキップ方式（required check がパス不一致で消えるのを防ぐための仕組み）は不要で、trigger レベルの `paths:` で十分。
- ワークフロー内では `uses: ./<action名>` でローカルの action を直接呼び出し、実際に実行して確認する（`ghmint-action` の `test.yml` と同じ発想）。
- **例外**: action を実際に呼び出すこと自体が外部への副作用（コミット作成・PR作成など、GitHub 上の実データを変更する操作）を伴う場合（例: `signed-commit`, `create-pull-request`）は、PR のたびに使い捨てのコミット・PR が自動生成されてしまい冗長なので、`uses: ./<action名>` による実行確認は行わない。代わりにシェルスクリプトへの `shellcheck` など静的チェックのみを `<action名>_ci.yml` で実行する。実際の動作確認は、その action を実運用で呼び出しているワークフロー（例: `update-readme-pins.yml`）が実際に走った際の結果で行う。

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
