# signed-commit

A GitHub Action that creates a signed (Verified) commit via the [GitHub Git Data API](https://docs.github.com/en/rest/git), using a provided GitHub App token.

Pass a GitHub App installation token (e.g. minted via [yagihash/ghmint-action](https://github.com/yagihash/ghmint-action)), not the built-in `GITHUB_TOKEN`, so that the commit appears under the App's identity with the "Verified" badge. GitHub only auto-verifies API-created commits that have **no custom author/committer info**, so leave `author-name`/`author-email` unset (the default) to get the Verified badge — GitHub then attributes the commit to the authenticated App and signs it automatically.

This action can be called multiple times on the same branch to stack commits — each call reads the current HEAD of the branch, so commits are correctly chained.

## Usage

```yaml
permissions:
  contents: read
  id-token: write # required to obtain the GitHub App token via ghmint-action

jobs:
  example:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
        with:
          persist-credentials: false

      - name: Create GitHub App Token
        id: token
        uses: yagihash/ghmint-action@v1.0.0
        with:
          scope: ${{ github.repository }}
          policy: writer

      - uses: yagihash/actions/signed-commit@v0.0.2
        id: commit
        with:
          token: ${{ steps.token.outputs.token }}
          branch: my-branch
          message: "Update generated files"
          files: |
            path/to/file-a.txt
            path/to/file-b.txt

      - run: echo '${{ steps.commit.outputs.commit-sha }}'
```

## Inputs

| Name           | Required | Default                                                     | Description                                                     |
|----------------|----------|--------------------------------------------------------------|-------------------------------------------------------------------|
| `token`        | Yes      | —                                                            | GitHub App token with `contents:write` permission                 |
| `repository`   | No       | `${{ github.repository }}`                                   | Target repository (`owner/repo`)                                  |
| `branch`       | Yes      | —                                                            | Branch to commit to (created if it does not exist)                |
| `message`      | Yes      | —                                                            | Commit message                                                    |
| `files`        | Yes      | —                                                            | Newline-separated list of file paths to commit (relative to workspace) |
| `author-name`  | No       | `""` (unset)                                                  | Commit author name. Leave unset to keep the Verified badge — see above |
| `author-email` | No       | `""` (unset)                                                  | Commit author email. Leave unset to keep the Verified badge — see above |

## Outputs

| Name         | Description                |
|--------------|-----------------------------|
| `commit-sha` | SHA of the created commit   |
