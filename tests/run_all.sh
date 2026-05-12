#!/usr/bin/env bash
# tests/run_all.sh — 跑全部 case × 配置的 harness，输出汇总报告
# bash 3.2 兼容（macOS 默认）

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
REPORT_ROOT="$SCRIPT_DIR/reports"

REPORT_DIR="$REPORT_ROOT/$(date +%Y-%m-%dT%H-%M-%S)"
mkdir -p "$REPORT_DIR"
export REPORT_DIR

SUMMARY="$REPORT_DIR/summary.md"
HARNESSES_STR="${HARNESSES:-claude hermes}"

# bash 3.2: 把 cases 收集到普通索引数组
CASES=()
while IFS= read -r line; do
  [[ -n "$line" ]] && CASES+=("$line")
done < <(ls "$SCRIPT_DIR/cases/"*.case 2>/dev/null | sort)

if [[ ${#CASES[@]} -eq 0 ]]; then
  echo "ERROR: no .case files in $SCRIPT_DIR/cases/" >&2
  exit 1
fi

# bash 3.2 没有 declare -A —— 用结果文件替代
RESULTS_FILE="$REPORT_DIR/results.tsv"
: > "$RESULTS_FILE"

# HARNESSES 数组（兼容写法）
HARNESSES=()
for h in $HARNESSES_STR; do HARNESSES+=("$h"); done

start_ts=$(date +%s)
total_pass=0 total_fail=0 total_skip=0 total_blocked=0

for case_file in "${CASES[@]}"; do
  case_id=$(grep -m1 '^ID=' "$case_file" | sed -E 's/^ID="?([^"]+)"?$/\1/')
  [[ -z "$case_id" ]] && { echo "WARN: skip case file (no ID): $case_file"; continue; }

  for harness in "${HARNESSES[@]}"; do
    echo "============================================================"
    echo "Running: $case_id [$harness]"
    echo "============================================================"
    bash "$SCRIPT_DIR/run_one.sh" "$harness" "$case_file"
    rc=$?
    case $rc in
      0)
        printf "%s\t%s\t%s\t%s\n" "$case_id" "$harness" "PASS" "" >> "$RESULTS_FILE"
        total_pass=$((total_pass + 1))
        ;;
      77)
        log_file="$REPORT_DIR/${harness}-${case_id}.log"
        reason="external blocker"
        if grep -qE "HTTP 503.*only allows Claude Code clients" "$log_file" 2>/dev/null; then
          reason="proxy only allows Claude Code clients (User-Agent gate)"
        elif grep -qE "no available accounts" "$log_file" 2>/dev/null; then
          reason="proxy: no available accounts"
        elif grep -qE "HTTP 40[13]" "$log_file" 2>/dev/null; then
          reason="auth error"
        fi
        printf "%s\t%s\t%s\t%s\n" "$case_id" "$harness" "BLOCKED" "$reason" >> "$RESULTS_FILE"
        total_blocked=$((total_blocked + 1))
        ;;
      78)
        printf "%s\t%s\t%s\t%s\n" "$case_id" "$harness" "SKIP" "SKIP_HARNESS declared" >> "$RESULTS_FILE"
        total_skip=$((total_skip + 1))
        ;;
      *)
        printf "%s\t%s\t%s\t%s\n" "$case_id" "$harness" "FAIL" "exit $rc" >> "$RESULTS_FILE"
        total_fail=$((total_fail + 1))
        ;;
    esac
  done
done

end_ts=$(date +%s)
elapsed=$((end_ts - start_ts))

{
  echo "# Test Summary — $(date)"
  echo ""
  echo "- Project: $PROJECT_ROOT"
  echo "- Report: $REPORT_DIR"
  echo "- Harnesses: ${HARNESSES[*]}"
  echo "- Total cases: ${#CASES[@]}"
  echo "- PASS: $total_pass | FAIL: $total_fail | BLOCKED: $total_blocked | SKIP: $total_skip"
  echo "- Elapsed: ${elapsed}s"
  echo ""
  echo "## Results"
  echo ""
  printf "| case | "
  for harness in "${HARNESSES[@]}"; do printf "%s | " "$harness"; done
  printf "note |\n"
  printf "%s" "|------|"
  for harness in "${HARNESSES[@]}"; do printf "%s" "------|"; done
  printf "------|\n"
  for case_file in "${CASES[@]}"; do
    case_id=$(grep -m1 '^ID=' "$case_file" | sed -E 's/^ID="?([^"]+)"?$/\1/')
    [[ -z "$case_id" ]] && continue
    printf "| %s | " "$case_id"
    note=""
    for harness in "${HARNESSES[@]}"; do
      row=$(grep -P "^${case_id}\t${harness}\t" "$RESULTS_FILE" 2>/dev/null \
            || awk -v cid="$case_id" -v h="$harness" -F'\t' '$1==cid && $2==h' "$RESULTS_FILE")
      r=$(printf "%s" "$row" | awk -F'\t' '{print $3}')
      n=$(printf "%s" "$row" | awk -F'\t' '{print $4}')
      [[ -z "$r" ]] && r="???"
      printf "%s | " "$r"
      if [[ "$r" == "BLOCKED" || "$r" == "SKIP" ]] && [[ -n "$n" ]]; then
        note="$n"
      fi
    done
    printf "%s |\n" "$note"
  done
  echo ""
  echo "## Status Legend"
  echo ""
  echo "- **PASS**: harness ran successfully and all assertions passed"
  echo "- **FAIL**: harness ran but assertions failed (or unexpected harness error)"
  echo "- **BLOCKED**: harness could not complete due to external dependency (proxy, network, quota); not a project-level failure"
  echo "- **SKIP**: case file declared SKIP_HARNESS=<this harness> by design"
  echo ""
  echo "## Logs"
  echo ""
  find "$REPORT_DIR" -name "*.log" -maxdepth 1 | sort | sed 's|^|- |'
} > "$SUMMARY"

echo ""
echo "============================================================"
echo "Summary written to: $SUMMARY"
echo "============================================================"
cat "$SUMMARY"

[[ $total_fail -gt 0 ]] && exit 1 || exit 0
