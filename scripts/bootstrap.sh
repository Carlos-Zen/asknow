#!/usr/bin/env bash
# asknow bootstrap — 幂等地创建 wiki 目录骨架与占位元文件
#
# 使用：
#   scripts/bootstrap.sh                # 在当前目录初始化
#   scripts/bootstrap.sh /path/to/root  # 在指定目录初始化
#
# 重跑安全：已存在的文件 / 目录一律跳过，绝不覆盖。

set -euo pipefail

ROOT="${1:-$(pwd)}"

if [[ ! -d "$ROOT" ]]; then
  echo "错误：目录不存在 — $ROOT" >&2
  exit 1
fi

cd "$ROOT"

created=()
skipped=()

# ---- 目录骨架 ----
for d in concepts howto insights references decisions cases journal journal/archive; do
  if [[ -d "$d" ]]; then
    skipped+=("$d/")
  else
    mkdir -p "$d"
    created+=("$d/")
  fi
done

# ---- 占位元文件 ----
maybe_write() {
  local path="$1"
  if [[ -f "$path" ]]; then
    skipped+=("$path")
    return 0
  fi
  cat > "$path"   # 从 stdin（heredoc）写入
  created+=("$path")
}

maybe_write INDEX.md <<'EOF'
# Knowledge Index

> 全局索引（按分类 + 标签）。由 `knowledge-write` / `knowledge-maintenance` 自动维护。
> 暂无条目 — 开始问答后会自动填充。

## concepts (是什么)

## howto (怎么做)

## insights (为什么)

## references (速查)

## decisions (选什么)

## cases (案例)
EOF

maybe_write GRAPH.md <<'EOF'
# Knowledge Graph

> 知识关联图（按领域可拆子图）。由 `knowledge-maintenance` 自动重建。

```mermaid
graph LR
  %% 暂无节点，等待笔记积累
```
EOF

maybe_write TAGS.md <<'EOF'
# Tags Registry

> 受控词表。新笔记的 `tags` 应优先从本列表选择；引入新标签前先在此登记并写一行说明。

## 暂无登记标签

第一次写笔记时，`knowledge-write` 会把新标签自动登记到这里。
EOF

maybe_write STATUS.md <<'EOF'
# Knowledge Base Status

> 跨会话状态，由 `knowledge-write` / `knowledge-maintenance` 自动维护。请勿手动编辑数值字段。

- total_files: 0
- files_since_last_index: 0
- relations_since_last_graph: 0
- last_full_maintenance: null
- last_journal_archive: null
- pending: []
EOF

maybe_write FEISHU_MAP.md <<'EOF'
<!--
asknow-sync:
  # target 在首次同步时由 feishu-sync skill 的"步骤 5"填充。
  # 不要手动编辑；按对话引导走（例："同步到飞书"会启动初始化向导）。
  target: null
  options:
    auto-sync-on-end: true        # 默认开启；用对话"关闭自动同步"或 /syncoff 暂停
  configured-at: null
-->
# 飞书同步映射

> 自动维护，勿手动编辑表格。
> 配置可通过对话调整："切换同步目标""关闭自动同步""开启自动同步"。
> 首次同步前 target 为 null；用户说"同步到飞书"会启动初始化（feishu-sync 步骤 5：选 wiki/docs + 解析地址）。

| 本地路径 | 飞书 token | 飞书 URL | 最后同步时间 | 本地 updated |
|---------|----------|----------|------------|-------------|
EOF

# ---- 输出报告 ----
echo "=== asknow bootstrap 完成 ==="
echo "目录：$ROOT"
if [[ ${#created[@]} -gt 0 ]]; then
  echo "创建 ${#created[@]} 项："
  for x in "${created[@]}"; do echo "  + $x"; done
fi
if [[ ${#skipped[@]} -gt 0 ]]; then
  echo "跳过 ${#skipped[@]} 项（已存在）："
  for x in "${skipped[@]}"; do echo "  · $x"; done
fi

# ---- Harness 检测提示 ----
if [[ -n "${OPENCLAW_HOME:-}" || -n "${HERMES_HOME:-}" ]]; then
  echo ""
  echo "🔍 检测到 Agent harness 环境（OPENCLAW_HOME / HERMES_HOME 已设置）"
  echo "  如需启用飞书同步，先问用户身份偏好，然后跑："
  echo "    lark-cli config bind --identity user-default   # 默认（同步到个人 wiki）"
  echo "    lark-cli config bind --identity bot-only       # 只同步到团队空间"
  echo "  完整说明：.claude/skills/feishu-sync/SKILL.md 步骤 2"
elif command -v lark-cli >/dev/null 2>&1; then
  echo ""
  echo "✓ 检测到 lark-cli 已安装。如需启用飞书同步，跑："
  echo "    lark-cli auth status  # 检查登录态"
  echo "  未登录则按 .claude/skills/feishu-sync/SKILL.md 步骤 2–3 引导用户完成"
else
  echo ""
  echo "ℹ 未检测到 lark-cli（飞书同步可选，跳过即可）"
  echo "  需启用：npm install -g @larksuite/cli"
fi

echo ""
echo "下一步：进入 $ROOT 用 Claude Code 启动问答。"
