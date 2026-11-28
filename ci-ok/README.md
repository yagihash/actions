# ci-ok

CI の各ジョブの結果をまとめて、**branch protection / ruleset の required status check に 1 つだけ登録すれば済む**ようにする composite action。

paths-filter などで一部のジョブが `skipped` になる構成では、個々のジョブを required check にすると「スキップされたまま永遠に待つ」問題が起きる。この action を持つ集約ジョブ（`if: always()`）だけを必須にすれば、スキップは成功として扱いつつ、失敗・キャンセルや、フィルターの書き間違いによる「黙ってスキップ」を検出できる。

## Inputs

| 名前 | 必須 | 説明 |
| --- | --- | --- |
| `needs` | yes | 呼び出し元ジョブの `${{ toJSON(needs) }}` |
| `filter-job` | no | 変更されたパスを判定するジョブの名前（例: `changes`） |
| `filter-outputs` | no | `filter-job` の出力のうち、答えが必要なものの名前。空白区切り（例: `workflows go adr`）。指定する場合は `filter-job` も必須 |

## 判定

次のどれかに当てはまると失敗する（`::error::` の注釈が付く）。

- `needs` のどれかのジョブの結果が `failure` か `cancelled`
- `filter-job` を指定したのに、`needs` にそのジョブがない、または結果が `success` でない（`skipped` も失敗）
- `filter-outputs` のどれかが `true` でも `false` でもない（空や未定義を含む。フィルター名の書き間違いで出力が空になり、ジョブが黙って飛ばされるのを防ぐ）
- `filter-outputs` を指定したのに `filter-job` がない

上記以外では、結果が `skipped` のジョブは成功として扱う。各ジョブの名前と結果は 1 行ずつログに出る。

## Usage

```yaml
ci-ok:
  if: always() # 失敗・スキップされた needs があっても必ず実行する
  needs: [changes, lint, test]
  runs-on: ubuntu-latest
  permissions: {}
  steps:
    - uses: yagihash/actions/ci-ok@9f208d1c7c8bdccc9fb897307a18b15375ee5000 # v0.2.0
      with:
        needs: ${{ toJSON(needs) }}
        filter-job: changes
        filter-outputs: workflows go
```

`needs` に列挙していないジョブは判定されないので、ジョブを追加したらここにも追加すること。

入力は `env:` 経由でスクリプトに渡しており、`jq` 以外の外部コマンドには依存しない。`bash` と `jq` が使えるランナー（GitHub-hosted のランナーなら最初から入っている）が必要。
