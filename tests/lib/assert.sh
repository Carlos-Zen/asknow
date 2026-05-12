#!/usr/bin/env bash
# tests/lib/assert.sh — 通用断言库
# 所有断言：成功 return 0；失败 echo "FAIL: ..." 并 return 1。
#
# 关键设计：项目内部对知识库根路径存在不一致（CLAUDE.md 的 ASCII 树用 wiki/，
# 而 bootstrap.sh 与 asknow SKILL.md 用 ./）。为不让本项目缺陷污染测试信号，
# 大多数路径断言对 ./<p> 与 ./wiki/<p> 都接受；具体被采用的根会在日志里显式标注。

# 返回当前 fixture 的知识库实际根（"." 或 "wiki"），凭目录内容判断
_kb_root() {
  # 优先级：wiki/ 目录里有任何 md 或子目录中有 md → wiki；否则 .
  if [[ -d wiki ]] && find wiki -maxdepth 2 -name "*.md" -type f 2>/dev/null | grep -q .; then
    echo "wiki"
    return 0
  fi
  echo "."
}

# 把 "concepts" 解析成 "./concepts" 或 "./wiki/concepts"（取存在且较丰满者）
_resolve_path() {
  local rel="$1"
  if [[ -e "$rel" ]] && [[ -d "$rel" ]] && find "$rel" -maxdepth 1 -name "*.md" -type f 2>/dev/null | grep -q .; then
    echo "$rel"
    return 0
  fi
  if [[ -e "wiki/$rel" ]] && [[ -d "wiki/$rel" ]] && find "wiki/$rel" -maxdepth 1 -name "*.md" -type f 2>/dev/null | grep -q .; then
    echo "wiki/$rel"
    return 0
  fi
  # 都没 md 就回退到 ./<rel> 看是否存在
  if [[ -e "$rel" ]]; then echo "$rel"; return 0; fi
  if [[ -e "wiki/$rel" ]]; then echo "wiki/$rel"; return 0; fi
  # 都不存在
  echo "$rel"
  return 1
}

assert_file_exists() {
  local path="$1"
  if [[ -f "$path" ]]; then return 0; fi
  if [[ -f "wiki/$path" ]]; then return 0; fi
  echo "FAIL: file not exists: ./$path (also tried ./wiki/$path)"
  return 1
}

assert_dir_exists() {
  local path="$1"
  if [[ -d "$path" ]]; then return 0; fi
  if [[ -d "wiki/$path" ]]; then return 0; fi
  echo "FAIL: dir not exists: ./$path (also tried ./wiki/$path)"
  return 1
}

assert_dir_has_md() {
  local dir="$1"
  for candidate in "$dir" "wiki/$dir"; do
    if [[ -d "$candidate" ]]; then
      local count
      count=$(find "$candidate" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$count" -gt 0 ]]; then return 0; fi
    fi
  done
  echo "FAIL: neither ./$dir nor ./wiki/$dir has .md files"
  return 1
}

_get_frontmatter_field() {
  local file="$1" field="$2"
  awk -v field="$field" '
    BEGIN { in_fm = 0 }
    /^---[[:space:]]*$/ { if (in_fm) exit; else { in_fm = 1; next } }
    in_fm {
      pat = "^[[:space:]]*" field ":[[:space:]]*"
      if ($0 ~ pat) {
        sub(pat, "")
        gsub(/^["\047]|["\047]$/, "")
        sub(/[[:space:]]+$/, "")
        print
        exit
      }
    }
  ' "$file" 2>/dev/null
}

assert_dir_md_frontmatter() {
  local dir="$1" field="$2" expected="$3"
  local matched=0 f actual checked=()
  for candidate in "$dir" "wiki/$dir"; do
    if [[ ! -d "$candidate" ]]; then continue; fi
    checked+=("$candidate")
    while IFS= read -r -d '' f; do
      actual=$(_get_frontmatter_field "$f" "$field")
      if [[ "$actual" == "$expected" ]]; then matched=1; break 2; fi
    done < <(find "$candidate" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
  done
  if [[ "$matched" -eq 1 ]]; then return 0; fi
  echo "FAIL: no .md in [${checked[*]:-./<missing>}] has frontmatter.$field=$expected"
  return 1
}

_find_status_file() {
  for p in STATUS.md wiki/STATUS.md; do
    [[ -f "$p" ]] && { echo "$p"; return 0; }
  done
  return 1
}

assert_status_field_gt() {
  local file="$1" field="$2" min="$3"
  # 接受 "STATUS.md" 字面或自动找
  local target=""
  if [[ -f "$file" ]]; then target="$file"
  elif [[ -f "wiki/$file" ]]; then target="wiki/$file"
  fi
  if [[ -z "$target" ]]; then echo "FAIL: $file not exists (also tried wiki/)"; return 1; fi
  local val
  val=$(awk -v field="$field" '
    $0 ~ "^[-*][[:space:]]*"field":[[:space:]]*" {
      n = $NF; gsub(/[^0-9-]/, "", n); print n; exit
    }
  ' "$target")
  if [[ -z "$val" ]]; then echo "FAIL: $target: field '$field' not found"; return 1; fi
  if [[ "$val" =~ ^-?[0-9]+$ ]] && [[ "$val" -gt "$min" ]]; then return 0; fi
  echo "FAIL: $target: $field=$val, expected > $min"
  return 1
}

assert_status_field_ge() {
  local file="$1" field="$2" min="$3"
  local target=""
  if [[ -f "$file" ]]; then target="$file"
  elif [[ -f "wiki/$file" ]]; then target="wiki/$file"
  fi
  if [[ -z "$target" ]]; then echo "FAIL: $file not exists (also tried wiki/)"; return 1; fi
  local val
  val=$(awk -v field="$field" '
    $0 ~ "^[-*][[:space:]]*"field":[[:space:]]*" {
      n = $NF; gsub(/[^0-9-]/, "", n); print n; exit
    }
  ' "$target")
  if [[ -z "$val" ]]; then echo "FAIL: $target: field '$field' not found"; return 1; fi
  if [[ "$val" =~ ^-?[0-9]+$ ]] && [[ "$val" -ge "$min" ]]; then return 0; fi
  echo "FAIL: $target: $field=$val, expected >= $min"
  return 1
}

assert_feishu_option() {
  local file="$1" key="$2" expected="$3"
  local target=""
  if [[ -f "$file" ]]; then target="$file"
  elif [[ -f "wiki/$file" ]]; then target="wiki/$file"
  fi
  if [[ -z "$target" ]]; then echo "FAIL: $file not exists (also tried wiki/)"; return 1; fi
  local val
  val=$(awk -v key="$key" '
    /^<!--/ { in_block = 1; next }
    /-->/   { in_block = 0; next }
    in_block && $0 ~ "^[[:space:]]*"key":[[:space:]]*" {
      sub("^[[:space:]]*"key":[[:space:]]*", "")
      sub(/[[:space:]]+#.*$/, "")
      sub(/^[[:space:]]+/, ""); sub(/[[:space:]]+$/, "")
      print; exit
    }
  ' "$target")
  if [[ "$val" == "$expected" ]]; then return 0; fi
  echo "FAIL: $target: $key=$val, expected $expected"
  return 1
}

assert_md_added_count() {
  local marker="$1" expected_count="$2"
  if [[ ! -e "$marker" ]]; then echo "FAIL: marker not exists: $marker"; return 1; fi
  # 计算两种根下的新增 md 总数（去掉脚手架与测试自身路径）
  local count
  count=$(find . -name "*.md" -type f -newer "$marker" \
    -not -path "./.claude/*" -not -path "./scripts/*" \
    -not -path "./tests/*" -not -path "./docs/*" \
    2>/dev/null | wc -l | tr -d ' ')
  if [[ "$count" -eq "$expected_count" ]]; then return 0; fi
  echo "FAIL: md_added=$count, expected $expected_count"
  find . -name "*.md" -type f -newer "$marker" \
    -not -path "./.claude/*" -not -path "./scripts/*" \
    -not -path "./tests/*" -not -path "./docs/*" \
    2>/dev/null | sed 's/^/    + /'
  return 1
}
