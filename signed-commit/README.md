# signed-commit

A GitHub Action that creates a signed (Verified) commit via the [GitHub Git Data API](https://docs.github.com/en/rest/git), using a provided GitHub App token.

Pass a GitHub App installation token (e.g. minted via [yagihash/ghmint-action](https://github.com/yagihash/ghmint-action)), not the built-in `GITHUB_TOKEN`, so that the commit appears under the App's identity with the "Verified" badge. GitHub signs commits created via the API when using a valid App token.

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
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false

      - name: Create GitHub App Token
        id: token
        uses: yagihash/ghmint-action@be57533eef7f69550d06f0c93eede5589158281a # v1.0.0
        with:
          scope: ${{ github.repository }}
          policy: writer

      - uses: yagihash/actions/signed-commit@77c439ab7748fa80819f2b4e578daabcb9a680f8 # v0.0.3
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
| `author-name`  | No       | `github-actions[bot]`                                        | Commit author name                                                |
| `author-email` | No       | `41898282+github-actions[bot]@users.noreply.github.com`      | Commit author email                                                |

## Outputs

| Name         | Description                |
|--------------|-----------------------------|
| `commit-sha` | SHA of the created commit   |
