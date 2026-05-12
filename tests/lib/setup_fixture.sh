#!/usr/bin/env bash
# tests/lib/setup_fixture.sh — 准备 fixture 工作目录（每次跑生成新临时目录）
#
# 用法：fixture_path=$(setup_fixture <project_root> <work_root> <case_id> [pre_bootstrap])
#   - 在 <work_root>/<case_id>-<ts>-XXXX/ 下创建新目录
#   - 复制 project_root 下：CLAUDE.md / skills.json / FEISHU_MAP.md / .claude / scripts
#   - pre_bootstrap=true 则跑 scripts/bootstrap.sh
#   - 创建 .test_started_at marker
#   - 把 fixture 路径 echo 到 stdout，供调用方接收

setup_fixture() {
  local project_root="$1" work_root="$2" case_id="$3" pre_bootstrap="${4:-false}"

  if [[ -z "$project_root" || -z "$work_root" || -z "$case_id" ]]; then
    echo "setup_fixture: usage <project_root> <work_root> <case_id> [pre_bootstrap]" >&2
    return 1
  fi
  if [[ ! -d "$project_root" ]]; then
    echo "setup_fixture: project_root not exists: $project_root" >&2
    return 1
  fi

  mkdir -p "$work_root"
  local ts
  ts=$(date +%Y%m%dT%H%M%S)
  local fixture_dir
  fixture_dir=$(mktemp -d "$work_root/${case_id}-${ts}-XXXXXX") || {
    echo "setup_fixture: mktemp failed" >&2
    return 1
  }

  for item in CLAUDE.md skills.json FEISHU_MAP.md .claude scripts; do
    if [[ -e "$project_root/$item" ]]; then
      cp -R "$project_root/$item" "$fixture_dir/"
    fi
  done

  if [[ "$pre_bootstrap" == "true" ]]; then
    ( cd "$fixture_dir" && bash scripts/bootstrap.sh >/dev/null 2>&1 ) || {
      echo "setup_fixture: bootstrap.sh failed in $fixture_dir" >&2
      return 1
    }
  fi

  sleep 1
  touch "$fixture_dir/.test_started_at"
  echo "$fixture_dir"
  return 0
}
