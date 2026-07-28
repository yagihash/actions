package ghmint

issuer := "https://token.actions.githubusercontent.com"

permissions := {
	"contents": "write",
	"pull_requests": "write",
}

default allow := false

allow if {
	input.sub == "repo:yagihash/actions:environment:main"
}

allow if {
	input.sub == "repo:yagihash/actions:ref:refs/heads/main"
}

allow if {
	startswith(input.sub, "repo:yagihash/actions:ref:refs/tags/v")
}
