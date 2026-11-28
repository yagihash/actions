#!/usr/bin/env bash
# Unit tests for check.sh. Usage: ci-ok/test.sh
set -uo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
passed=0
failures=0

# run_case <name> <expected exit code> <needs JSON> <filter-job> <filter-outputs> [expected output substring]
run_case() {
  local name=$1 want=$2 needs=$3 fjob=$4 fouts=$5 grep_for=${6:-}
  local out got
  out=$(NEEDS="$needs" FILTER_JOB="$fjob" FILTER_OUTPUTS="$fouts" "$dir/check.sh" 2>&1)
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    echo "not ok - ${name}: exit ${got}, want ${want}"
    printf '    %s\n' "${out//$'\n'/$'\n'    }"
    failures=$((failures + 1))
  elif [[ -n "$grep_for" && "$out" != *"$grep_for"* ]]; then
    echo "not ok - ${name}: output lacks '${grep_for}'"
    printf '    %s\n' "${out//$'\n'/$'\n'    }"
    failures=$((failures + 1))
  else
    echo "ok - ${name}"
    passed=$((passed + 1))
  fi
}

ok_changes='"changes":{"result":"success","outputs":{"workflows":"true","go":"false"}}'

run_case "all succeed" 0 \
  "{${ok_changes},\"lint\":{\"result\":\"success\",\"outputs\":{}}}" "" ""
run_case "some skipped" 0 \
  "{${ok_changes},\"lint\":{\"result\":\"skipped\",\"outputs\":{}},\"test\":{\"result\":\"success\",\"outputs\":{}}}" \
  changes "workflows go"
run_case "failure" 1 \
  "{${ok_changes},\"lint\":{\"result\":\"failure\",\"outputs\":{}}}" changes "workflows" "job 'lint' failure"
run_case "cancelled" 1 \
  "{${ok_changes},\"lint\":{\"result\":\"cancelled\",\"outputs\":{}}}" changes "workflows" "job 'lint' cancelled"
run_case "filter-job skipped" 1 \
  '{"changes":{"result":"skipped","outputs":{}}}' changes "" "filter job 'changes' is skipped"
run_case "filter-job failure" 1 \
  '{"changes":{"result":"failure","outputs":{}}}' changes "" "job 'changes' failure"
run_case "filter-job not in needs" 1 \
  '{"lint":{"result":"success","outputs":{}}}' changes "" "filter job 'changes' is not in needs"
run_case "filter-outputs empty" 1 \
  '{"changes":{"result":"success","outputs":{"workflows":"true","go":""}}}' changes "workflows go" "output 'go'"
run_case "filter-outputs undefined" 1 \
  '{"changes":{"result":"success","outputs":{"workflows":"true"}}}' changes "workflows go" "output 'go'"
run_case "filter-job without outputs" 1 \
  '{"changes":{"result":"success"}}' changes "workflows" "output 'workflows'"
run_case "filter-outputs without filter-job" 1 \
  "{${ok_changes}}" "" "workflows" "requires 'filter-job'"
run_case "outputs with extra whitespace" 0 \
  "{${ok_changes}}" changes "  workflows   go " ""
run_case "invalid needs JSON" 1 "not json" "" "" "must be a JSON object"

echo "${passed} passed, ${failures} failed"
[[ "$failures" -eq 0 ]]
