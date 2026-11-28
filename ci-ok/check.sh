#!/usr/bin/env bash
# Inputs (environment variables):
#   NEEDS           JSON of the `needs` context (required)
#   FILTER_JOB      name of the job that decides which paths changed (optional)
#   FILTER_OUTPUTS  whitespace-separated outputs of FILTER_JOB that must be true/false (optional)
set -euo pipefail

failed=0

fail() {
  echo "::error::$1"
  echo "FAIL: $1"
  failed=1
}

if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq is required but not found on this runner"
  exit 1
fi

NEEDS="${NEEDS:-}"
FILTER_JOB="${FILTER_JOB:-}"
FILTER_OUTPUTS="${FILTER_OUTPUTS:-}"

if ! jq -e 'type == "object"' <<<"$NEEDS" >/dev/null 2>&1; then
  echo "::error::input 'needs' must be a JSON object (use \${{ toJSON(needs) }})"
  exit 1
fi

outputs=()
read -r -a outputs <<<"$FILTER_OUTPUTS" || true

if [[ -z "$FILTER_JOB" && ${#outputs[@]} -gt 0 ]]; then
  echo "::error::input 'filter-outputs' requires 'filter-job'"
  exit 1
fi

# Every job and its result, one per line.
jq -r 'to_entries[] | "\(.key): \(.value.result)"' <<<"$NEEDS"

# A failed or cancelled job fails the check. A skipped one is fine.
while IFS= read -r job; do
  [[ -z "$job" ]] && continue
  result=$(jq -r --arg j "$job" '.[$j].result' <<<"$NEEDS")
  fail "job '${job}' ${result}"
done < <(jq -r 'to_entries[] | select(.value.result == "failure" or .value.result == "cancelled") | .key' <<<"$NEEDS")

if [[ -n "$FILTER_JOB" ]]; then
  if ! jq -e --arg j "$FILTER_JOB" 'has($j)' <<<"$NEEDS" >/dev/null; then
    fail "filter job '${FILTER_JOB}' is not in needs"
  else
    result=$(jq -r --arg j "$FILTER_JOB" '.[$j].result' <<<"$NEEDS")
    # failure / cancelled were already reported above
    if [[ "$result" != "success" && "$result" != "failure" && "$result" != "cancelled" ]]; then
      fail "filter job '${FILTER_JOB}' is ${result}, expected success"
    fi

    # A misspelled filter name yields an empty output, and the job guarded by it is skipped silently.
    for name in ${outputs[@]+"${outputs[@]}"}; do
      value=$(jq -r --arg j "$FILTER_JOB" --arg o "$name" '.[$j].outputs[$o] // ""' <<<"$NEEDS")
      echo "output ${FILTER_JOB}.${name}: ${value}"
      if [[ "$value" != "true" && "$value" != "false" ]]; then
        fail "output '${name}' of filter job '${FILTER_JOB}' is '${value}', expected true or false"
      fi
    done
  fi
fi

exit "$failed"
