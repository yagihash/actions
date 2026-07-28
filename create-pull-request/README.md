# create-pull-request

A GitHub Action that creates a pull request using a provided GitHub App token.

Pass a GitHub App installation token (e.g. minted via [yagihash/ghmint-action](https://github.com/yagihash/ghmint-action)), not the built-in `GITHUB_TOKEN`, so that the pull request appears under the App's identity.

If an open pull request for the same `head`/`base` already exists, this action returns its URL/number and exits successfully without creating a duplicate.

## Usage

```yaml
permissions:
  contents: read
  pull-requests: read
  id-token: write # required to obtain the GitHub App token via ghmint-action

jobs:
  example:
    runs-on: ubuntu-latest
    steps:
      - name: Create GitHub App Token
        id: token
        uses: yagihash/ghmint-action@be57533eef7f69550d06f0c93eede5589158281a # v1.0.0
        with:
          scope: ${{ github.repository }}
          policy: writer

      - uses: yagihash/actions/create-pull-request@75a36e929a30f99149784465dcdf9d33ab01a120 # v0.0.4
        id: pr
        with:
          token: ${{ steps.token.outputs.token }}
          title: "Update generated files"
          body: "Automated update."
          head: my-branch
          base: main

      - run: echo '${{ steps.pr.outputs.pull-request-url }}'
```

## Inputs

| Name         | Required | Default | Description                                     |
|--------------|----------|---------|--------------------------------------------------|
| `token`      | Yes      | —       | GitHub App token with `pull-requests:write` permission |
| `repository` | No       | `${{ github.repository }}` | Target repository (`owner/repo`)   |
| `title`      | Yes      | —       | Pull request title                               |
| `body`       | No       | `""`    | Pull request body (Markdown)                     |
| `head`       | Yes      | —       | Head branch name                                 |
| `base`       | No       | `main`  | Base branch name                                 |
| `reviewers`  | No       | `""`    | Comma-separated list of reviewer logins (optional) |
| `labels`     | No       | `""`    | Comma-separated list of labels (optional)        |
| `draft`      | No       | `"false"` | Create as draft PR                             |

## Outputs

| Name                   | Description                                  |
|------------------------|-----------------------------------------------|
| `pull-request-url`     | URL of the created or existing pull request   |
| `pull-request-number`  | Number of the created or existing pull request |
