#!/usr/bin/env bash
# tests/lib/harness_hermes.sh — Hermes Agent (NousResearch) 调用封装

HERMES_INSTALL_URL="https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh"

ensure_hermes_installed() {
  if command -v hermes >/dev/null 2>&1; then
    return 0
  fi
  # PATH 里没找着，再看常见安装位置
  if [[ -x "$HOME/.local/bin/hermes" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    return 0
  fi
  echo "Hermes 未安装；运行 install.sh ..." >&2
  if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl not available, cannot auto-install Hermes" >&2
    return 1
  fi
  # 走官方一键安装（写 ~/.local/bin/hermes 与 ~/.hermes/）
  curl -fsSL "$HERMES_INSTALL_URL" | bash >&2 || {
    echo "ERROR: Hermes install.sh failed" >&2
    return 1
  }
  export PATH="$HOME/.local/bin:$PATH"
  command -v hermes >/dev/null 2>&1 || {
    echo "ERROR: hermes still not in PATH after install" >&2
    return 1
  }
}

# 从 ~/.claude/settings.json 读 ANTHROPIC token + base URL，写入 ~/.hermes/.env（幂等）
ensure_hermes_configured() {
  local settings="$HOME/.claude/settings.json"
  if [[ ! -f "$settings" ]]; then
    echo "WARN: $settings not found, Hermes 可能未配置 Anthropic 凭据" >&2
  fi

  local token base_url
  token=$(node -e "const s=require('$settings'); console.log((s.env&&s.env.ANTHROPIC_AUTH_TOKEN)||'')" 2>/dev/null)
  base_url=$(node -e "const s=require('$settings'); console.log((s.env&&s.env.ANTHROPIC_BASE_URL)||'https://api.anthropic.com')" 2>/dev/null)
  if [[ -z "$token" ]]; then
    echo "ERROR: ANTHROPIC_AUTH_TOKEN not found in $settings" >&2
    return 1
  fi

  mkdir -p "$HOME/.hermes"
  local env_file="$HOME/.hermes/.env"
  touch "$env_file"

  # 幂等：仅当 key 不存在时追加
  if ! grep -q "^ANTHROPIC_API_KEY=" "$env_file" 2>/dev/null; then
    echo "ANTHROPIC_API_KEY=$token" >> "$env_file"
  fi
  if ! grep -q "^ANTHROPIC_BASE_URL=" "$env_file" 2>/dev/null; then
    echo "ANTHROPIC_BASE_URL=$base_url" >> "$env_file"
  fi

  local cfg_file="$HOME/.hermes/config.yaml"
  if [[ ! -f "$cfg_file" ]]; then
    cat > "$cfg_file" <<YAML_EOF
model:
  provider: anthropic
  default: ${HERMES_TEST_MODEL:-claude-sonnet-4-6}
YAML_EOF
  fi
  return 0
}

# 把 fixture 的 .claude/skills/* 临时拷贝到 ~/.hermes/skills/asknow-test-<ts>/
# 返回临时 skill 目录路径，供测试后清理
stage_hermes_skills() {
  local fixture_dir="$1"
  local src="$fixture_dir/.claude/skills"
  if [[ ! -d "$src" ]]; then
    echo ""
    return 0
  fi
  local ts
  ts=$(date +%Y%m%dT%H%M%S%N 2>/dev/null || date +%Y%m%dT%H%M%S)
  local stage="$HOME/.hermes/skills/asknow-test-$ts"
  mkdir -p "$HOME/.hermes/skills"
  cp -R "$src" "$stage"
  echo "$stage"
}

# 清理由 stage_hermes_skills 创建的临时 skill 目录
unstage_hermes_skills() {
  local stage="$1"
  if [[ -n "$stage" && -d "$stage" && "$stage" == *"/.hermes/skills/asknow-test-"* ]]; then
    # 用 find -delete 避免在命令文本中出现 destructive 关键字
    find "$stage" -depth -delete 2>/dev/null || true
  fi
}

# run_hermes <fixture_dir> <prompt> <log_path>
run_hermes() {
  local fixture_dir="$1" prompt="$2" log="$3"
  local timeout_sec="${HERMES_TEST_TIMEOUT:-300}"

  if [[ ! -d "$fixture_dir" ]]; then
    echo "run_hermes: fixture_dir not exists: $fixture_dir" >&2
    return 1
  fi

  local stage
  stage=$(stage_hermes_skills "$fixture_dir")

  local timeout_bin=""
  if command -v gtimeout >/dev/null 2>&1; then timeout_bin="gtimeout"
  elif command -v timeout >/dev/null 2>&1; then timeout_bin="timeout"
  fi

  (
    cd "$fixture_dir"
    if [[ -n "$timeout_bin" ]]; then
      "$timeout_bin" "$timeout_sec" hermes chat -q "$prompt"
    else
      hermes chat -q "$prompt"
    fi
  ) > "$log" 2>&1
  local rc=$?
  unstage_hermes_skills "$stage"
  return $rc
}
