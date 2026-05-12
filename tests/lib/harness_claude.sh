#!/usr/bin/env bash
# tests/lib/harness_claude.sh — Claude Code 调用封装

ensure_claude_installed() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: claude CLI not found in PATH" >&2
    return 1
  fi
}

# run_claude <fixture_dir> <prompt> <log_path>
run_claude() {
  local fixture_dir="$1" prompt="$2" log="$3"
  local model="${CLAUDE_TEST_MODEL:-claude-sonnet-4-6}"
  local timeout_sec="${CLAUDE_TEST_TIMEOUT:-300}"

  if [[ ! -d "$fixture_dir" ]]; then
    echo "run_claude: fixture_dir not exists: $fixture_dir" >&2
    return 1
  fi

  local timeout_bin=""
  if command -v gtimeout >/dev/null 2>&1; then timeout_bin="gtimeout"
  elif command -v timeout >/dev/null 2>&1; then timeout_bin="timeout"
  fi

  (
    cd "$fixture_dir"
    local cmd=(claude -p "$prompt"
      --output-format text
      --setting-sources project
      --dangerously-skip-permissions
      --permission-mode bypassPermissions
      --model "$model"
      --add-dir "$(pwd)")
    if [[ -n "$timeout_bin" ]]; then
      "$timeout_bin" "$timeout_sec" "${cmd[@]}"
    else
      "${cmd[@]}"
    fi
  ) > "$log" 2>&1
  return $?
}
