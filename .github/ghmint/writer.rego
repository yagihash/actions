package ghmint

issuer := "https://token.actions.githubusercontent.com"

permissions := {
	"contents": "write",
	"pull_requests": "write",
}

default allow := false

# GitHub Actions started appending immutable owner/repo IDs to the OIDC
# subject claim for repositories created after 2026-07-15
# (repo:owner@<id>/repo@<id>:ref:...) instead of the old repo:owner/repo:ref:...
# format. This repo was created after that date, so match both the owner and
# repo name with an optional "@<id>" suffix.
# https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/

allow if {
	regex.match(`^repo:yagihash(@[0-9]+)?/actions(@[0-9]+)?:ref:refs/heads/main$`, input.sub)
}

allow if {
	regex.match(`^repo:yagihash(@[0-9]+)?/actions(@[0-9]+)?:ref:refs/tags/v`, input.sub)
}
