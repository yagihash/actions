#!/usr/bin/env bash
set -euo pipefail

if ! BASE_SHA=$(gh api "repos/${REPO}/git/ref/heads/${BRANCH}" --jq '.object.sha' 2>/dev/null); then
  DEFAULT_BRANCH=$(gh api "repos/${REPO}" --jq '.default_branch')
  BASE_SHA=$(gh api "repos/${REPO}/git/ref/heads/${DEFAULT_BRANCH}" --jq '.object.sha')
fi
BASE_TREE=$(gh api "repos/${REPO}/git/commits/${BASE_SHA}" --jq '.tree.sha')

TREE_ENTRIES=()
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  BLOB_SHA=$(gh api "repos/${REPO}/git/blobs" \
    --field encoding=base64 \
    --field content="$(base64 < "$file" | tr -d '\n')" \
    --jq '.sha')
  TREE_ENTRIES+=("$(jq -n \
    --arg path "$file" \
    --arg sha "$BLOB_SHA" \
    '{path: $path, mode: "100644", type: "blob", sha: $sha}')")
done <<< "$FILES"

if [[ ${#TREE_ENTRIES[@]} -eq 0 ]]; then
  echo "No files given in FILES input" >&2
  exit 1
fi

TREE_JSON=$(printf '%s\n' "${TREE_ENTRIES[@]}" | jq -s '.')

TREE_SHA=$(jq -n \
  --arg base_tree "$BASE_TREE" \
  --argjson tree "$TREE_JSON" \
  '{base_tree: $base_tree, tree: $tree}' | \
  gh api "repos/${REPO}/git/trees" --input - --jq '.sha')

COMMIT_SHA=$(jq -n \
  --arg message "$MESSAGE" \
  --arg tree "$TREE_SHA" \
  --arg parent "$BASE_SHA" \
  --arg name "$AUTHOR_NAME" \
  --arg email "$AUTHOR_EMAIL" \
  '{message: $message, tree: $tree, parents: [$parent]}
   + (if $name != "" and $email != "" then {author: {name: $name, email: $email}} else {} end)' | \
  gh api "repos/${REPO}/git/commits" --input - --jq '.sha')

if ! gh api "repos/${REPO}/git/refs" \
  --field ref="refs/heads/${BRANCH}" \
  --field sha="${COMMIT_SHA}" >/dev/null 2>&1; then
  gh api "repos/${REPO}/git/refs/heads/${BRANCH}" \
    --method PATCH \
    --field sha="${COMMIT_SHA}" \
    --field force=false
fi

echo "commit_sha=${COMMIT_SHA}" >> "$GITHUB_OUTPUT"
