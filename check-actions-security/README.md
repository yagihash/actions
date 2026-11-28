# check-actions-security

リポジトリの GitHub Actions のワークフローと action を検査する composite action。[ghalint](https://github.com/suzuki-shunsuke/ghalint)（`ghalint run` と `ghalint act`）と [jactionlint](https://github.com/jdx/jactionlint)（`--profile correctness`）を実行する。

各リポジトリの CI から、ツールのダウンロード・検証・実行の手順を書かずに呼べるようにするための action。検査に使うツールの入れ替えやバージョンの更新は、この action だけを直せば全リポジトリに反映される。

- 各ツールは GitHub Release からダウンロードし、`gh attestation verify` で、リリースのワークフローが署名したものだと確かめてから使う。
- 3 つの検査は、途中のものが失敗しても最後まで実行する（1 回の実行ですべての指摘が見える）。どれかが失敗したら、この action は失敗する。
- ランナーは Linux（X64 / ARM64）のみ。

## Inputs

| 名前 | 必須 | 説明 |
| --- | --- | --- |
| `token` | no | ツールの Release のダウンロードと attestation の検証に使うトークン。既定は `github.token` |

## Usage

先に `actions/checkout` で検査対象を取得しておく。attestation の検証に `attestations: read` が要る。

```yaml
jobs:
  check-actions-security:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
      attestations: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false

      - uses: yagihash/actions/check-actions-security@75a36e929a30f99149784465dcdf9d33ab01a120 # v0.0.4
```
