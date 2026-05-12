#!/usr/bin/env bash
# tests/run_one.sh <harness> <case-id-or-file>
#
# Exit codes:
#   0  = PASS
#   1  = FAIL (assertion failed or unexpected harness error)
#   77 = BLOCKED (harness reached but external dependency unavailable, e.g. proxy rejection)
#   78 = SKIP   (SKIP_HARNESS declared in case file)
#   2  = USAGE error

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
WORK_ROOT="$SCRIPT_DIR/.work"
REPORT_ROOT="$SCRIPT_DIR/reports"

# shellcheck source=lib/assert.sh
source "$SCRIPT_DIR/lib/assert.sh"
# shellcheck source=lib/setup_fixture.sh
source "$SCRIPT_DIR/lib/setup_fixture.sh"
# shellcheck source=lib/harness_claude.sh
source "$SCRIPT_DIR/lib/harness_claude.sh"
# shellcheck source=lib/harness_hermes.sh
source "$SCRIPT_DIR/lib/harness_hermes.sh"

usage() {
  cat <<EOM >&2
Usage: $0 <claude|hermes> <case-id-or-path>

Examples:
  $0 claude 02-concepts-write
  $0 hermes cases/02-concepts-write.case

Env vars:
  CLAUDE_TEST_MODEL=<model>   default: claude-sonnet-4-6
  HERMES_TEST_MODEL=<model>   default: claude-sonnet-4-6
  CLAUDE_TEST_TIMEOUT=<sec>   default: 300
  HERMES_TEST_TIMEOUT=<sec>   default: 300
  REPORT_DIR=<path>           override report directory
EOM
  exit 2
}

resolve_case_file() {
  local arg="$1"
  if [[ -f "$arg" ]]; then echo "$arg"; return; fi
  if [[ -f "$SCRIPT_DIR/$arg" ]]; then echo "$SCRIPT_DIR/$arg"; return; fi
  if [[ -f "$SCRIPT_DIR/cases/${arg}.case" ]]; then echo "$SCRIPT_DIR/cases/${arg}.case"; return; fi
  if [[ -f "$SCRIPT_DIR/cases/$arg" ]]; then echo "$SCRIPT_DIR/cases/$arg"; return; fi
  echo "ERROR: case file not found: $arg" >&2
  exit 2
}

# Detect known external blockers in harness output that should map to BLOCKED, not FAIL.
detect_blocker() {
  local log="$1"
  if [[ ! -f "$log" ]]; then return 1; fi
  if grep -qE "HTTP 503.*only allows Claude Code clients" "$log" 2>/dev/null; then
    echo "proxy_rejects_non_claude_code_clients"
    return 0
  fi
  if grep -qE "HTTP 40[13]|invalid_api_key|authentication_error" "$log" 2>/dev/null; then
    echo "auth_error"
    return 0
  fi
  if grep -qiE "rate.?limit|429" "$log" 2>/dev/null; then
    echo "rate_limited"
    return 0
  fi
  if grep -qiE "no available accounts" "$log" 2>/dev/null; then
    echo "proxy_no_accounts"
    return 0
  fi
  return 1
}

run_assertions() {
  local fixture_dir="$1" assertions="$2"
  local failed=0
  (
    cd "$fixture_dir"
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if ! eval "$line"; then
        failed=$((failed + 1))
      fi
    done <<< "$assertions"
    exit $failed
  )
  return $?
}

main() {
  [[ $# -lt 2 ]] && usage
  local harness="$1" case_arg="$2"
  case "$harness" in
    claude|hermes) ;;
    *) echo "ERROR: harness must be 'claude' or 'hermes', got '$harness'" >&2; exit 2 ;;
  esac

  local case_file
  case_file=$(resolve_case_file "$case_arg")

  # shellcheck source=/dev/null
  source "$case_file"
  : "${ID:?ID not set in $case_file}"

  if [[ ",${SKIP_HARNESS:-}," == *",${harness},"* ]]; then
    echo "SKIP: $ID [$harness] — declared SKIP_HARNESS=$SKIP_HARNESS"
    exit 78
  fi

  local report_dir="${REPORT_DIR:-$REPORT_ROOT/$(date +%Y-%m-%dT%H-%M-%S)}"
  mkdir -p "$report_dir"
  local log="$report_dir/${harness}-${ID}.log"

  echo ">>> case: $ID [$harness]"
  echo "    desc: ${DESC:-(none)}"
  echo "    log : $log"

  if [[ "$harness" == "claude" ]]; then
    ensure_claude_installed || exit 1
  else
    ensure_hermes_installed || { echo "FAIL: hermes install failed"; exit 1; }
    ensure_hermes_configured || { echo "FAIL: hermes config failed"; exit 1; }
  fi

  local work_root="$WORK_ROOT/$harness"
  local fixture_dir
  fixture_dir=$(setup_fixture "$PROJECT_ROOT" "$work_root" "$ID" "${PRE_BOOTSTRAP:-true}") || {
    echo "FAIL: fixture setup failed for $ID"
    exit 1
  }
  echo "    fixture: $fixture_dir"

  local rc=0
  if [[ "${NO_LLM:-false}" == "true" ]]; then
    echo "    (NO_LLM=true, skipping LLM call)"
    : > "$log"
  else
    if [[ -z "${PROMPT:-}" ]]; then
      echo "FAIL: PROMPT empty but NO_LLM != true"
      exit 1
    fi
    if [[ "$harness" == "claude" ]]; then
      run_claude "$fixture_dir" "$PROMPT" "$log" || rc=$?
    else
      run_hermes "$fixture_dir" "$PROMPT" "$log" || rc=$?
    fi
  fi

  # If LLM call failed AND log shows a known external blocker → BLOCKED (exit 77)
  if [[ $rc -ne 0 ]]; then
    local blocker
    if blocker=$(detect_blocker "$log"); then
      echo "BLOCKED: $ID [$harness] — $blocker (harness exit $rc; see log)"
      exit 77
    fi
    echo "WARN: harness exit $rc (log: $log) — running assertions anyway"
  fi
  # Even if harness exit 0 but blocker pattern present, still BLOCKED
  if blocker=$(detect_blocker "$log"); then
    echo "BLOCKED: $ID [$harness] — $blocker (see log)"
    exit 77
  fi

  if [[ -z "${ASSERTIONS:-}" ]]; then
    echo "FAIL: ASSERTIONS empty in $case_file"
    exit 1
  fi

  if run_assertions "$fixture_dir" "$ASSERTIONS"; then
    echo "PASS: $ID [$harness]"
    exit 0
  else
    local failed=$?
    echo "FAIL: $ID [$harness] — $failed assertion(s) failed"
    exit 1
  fi
}

main "$@"
