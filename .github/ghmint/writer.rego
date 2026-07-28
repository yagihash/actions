package ghmint

issuer := "https://token.actions.githubusercontent.com"

permissions := {
	"contents": "write",
	"pull_requests": "write",
}

default allow := false

# GitHub Actions appends immutable owner/repo IDs to the OIDC subject claim
# for repositories created after 2026-07-15 (repo:owner@<id>/repo@<id>:ref:...)
# instead of the old, recyclable repo:owner/repo:ref:... format. This repo was
# created after that date, so pin the actual owner ID (yagihash) and repo ID
# (actions) rather than accepting any numeric ID, otherwise a recycled
# name/ID pairing could satisfy the rule and defeat the point of the change.
# https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/

allow if {
	input.sub == "repo:yagihash@1553908/actions@1309947540:ref:refs/heads/main"
}

allow if {
	startswith(input.sub, "repo:yagihash@1553908/actions@1309947540:ref:refs/tags/v")
}
