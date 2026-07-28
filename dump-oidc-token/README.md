# dump-oidc-token

A GitHub Action that fetches the [GitHub Actions OIDC ID token](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect) and prints its claims — useful for quickly inspecting what's actually inside the token while developing OIDC-based workflows (e.g. checking the exact `sub` claim format).

**This action does not verify the token's signature.** It's for inspection/debugging only — never use its output to make authorization decisions.

## Usage

```yaml
permissions:
  id-token: write  # required to obtain the OIDC token

jobs:
  example:
    runs-on: ubuntu-latest
    steps:
      - uses: yagihash/actions/dump-oidc-token@75a36e929a30f99149784465dcdf9d33ab01a120 # v0.0.4
        id: claims

      - run: echo '${{ steps.claims.outputs.claims }}'
```

## Inputs

| Name       | Required | Default | Description                             |
|------------|----------|---------|------------------------------------------|
| `audience` | No       | —       | Audience to request the OIDC token for  |

## Outputs

| Name     | Description                    |
|----------|--------------------------------|
| `claims` | JSON-encoded OIDC token claims |
