#!/usr/bin/env bash
set -euo pipefail

OWNER="${REPO%%/*}"
EXISTING=$(gh api \
  "repos/${REPO}/pulls?head=${OWNER}:${HEAD}&base=${BASE}&state=open" \
  --jq '.[0] | {url: .html_url, number: .number} | select(.url != null)')

if [[ -n "$EXISTING" ]]; then
  echo "pull_request_url=$(echo "$EXISTING" | jq -r '.url')" >> "$GITHUB_OUTPUT"
  echo "pull_request_number=$(echo "$EXISTING" | jq -r '.number')" >> "$GITHUB_OUTPUT"
  exit 0
fi

DRAFT_BOOL=$([[ "$DRAFT" == "true" ]] && echo true || echo false)
RESULT=$(jq -n \
  --arg title "$TITLE" \
  --arg body "$BODY" \
  --arg head "$HEAD" \
  --arg base "$BASE" \
  --argjson draft "$DRAFT_BOOL" \
  '{title: $title, body: $body, head: $head, base: $base, draft: $draft}' | \
  gh api "repos/${REPO}/pulls" --input - \
    --jq '{url: .html_url, number: .number}')
PR_URL=$(echo "$RESULT" | jq -r '.url')
PR_NUMBER=$(echo "$RESULT" | jq -r '.number')

if [[ -n "$REVIEWERS" ]]; then
  jq -Rn '[splits(",") | select(length > 0)]' <<< "$REVIEWERS" | \
  jq '{reviewers: .}' | \
  gh api "repos/${REPO}/pulls/${PR_NUMBER}/requested_reviewers" \
    --method POST --input -
fi

if [[ -n "$LABELS" ]]; then
  jq -Rn '[splits(",") | select(length > 0)]' <<< "$LABELS" | \
  jq '{labels: .}' | \
  gh api "repos/${REPO}/issues/${PR_NUMBER}/labels" \
    --method POST --input -
fi

echo "pull_request_url=${PR_URL}" >> "$GITHUB_OUTPUT"
echo "pull_request_number=${PR_NUMBER}" >> "$GITHUB_OUTPUT"
