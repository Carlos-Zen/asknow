# asknow 自动化测试

真实端到端测试本项目在 **Claude Code** 与 **Hermes Agent** 两个 harness 下的行为是否符合 `CLAUDE.md` + `.claude/skills/*/SKILL.md` 的契约。

## 设计

- **断言只看文件副作用**，不解析 LLM 输出文本。LLM 输出有随机性，文件树/frontmatter/计数器是确定性的。
- **每个 case 一个独立 fixture 目录**（`tests/.work/<harness>/<case-id>-<ts>-XXXX/`），跑前 `mktemp` 新建，互不污染真实项目。
- **测试隔离**：Claude 用 `--setting-sources project` 屏蔽全局 hooks；Hermes 走 `~/.hermes/.env` 独立配置。
- **不依赖 mock**。LLM 真实调用、真实文件写入。代价是每次跑全套有 LLM 费用与 5–15 分钟时长。

## 跑

```bash
# 全套（两个 harness、所有 case）
bash tests/run_all.sh

# 只跑 claude
HARNESSES="claude" bash tests/run_all.sh

# 只跑 hermes
HARNESSES="hermes" bash tests/run_all.sh

# 单 case 调试
bash tests/run_one.sh claude 02-concepts-write
bash tests/run_one.sh hermes 04-norecord
```

报告在 `tests/reports/<ISO-timestamp>/`：
- `summary.md` — PASS/FAIL/SKIP 汇总表
- `<harness>-<case-id>.log` — 单个 case 在该 harness 下的完整 stdout/stderr

## 环境变量

| 变量 | 默认 | 说明 |
|------|------|------|
| `CLAUDE_TEST_MODEL` | `claude-sonnet-4-6` | claude -p 的 --model |
| `HERMES_TEST_MODEL` | `claude-sonnet-4-6` | 写入 ~/.hermes/config.yaml |
| `CLAUDE_TEST_TIMEOUT` | `300` | 秒 |
| `HERMES_TEST_TIMEOUT` | `300` | 秒 |
| `HARNESSES` | `"claude hermes"` | 空格分隔的 harness 列表 |
| `REPORT_DIR` | 自动生成 | 强制指定报告输出目录 |

## 前置依赖

- `claude` CLI（已假定安装并登录；本测试不验证登录态）
- `hermes` CLI（缺则 `run_hermes` 会自动 `curl install.sh | bash` 装上）
- `~/.claude/settings.json` 含 `env.ANTHROPIC_AUTH_TOKEN` 与 `env.ANTHROPIC_BASE_URL` — Hermes 测试会读取并写入 `~/.hermes/.env`
- `node` / `bash` / `awk` / `find` / `sed`（macOS 自带或常见 Linux 默认）

## 新增 case

在 `tests/cases/` 下加一个 `.case` 文件：

```bash
ID="09-my-test"                         # 唯一标识
DESC="一句话说明"
PROMPT="问 LLM 的话"                    # 空且 NO_LLM=true 时跳过 LLM 调用
NO_LLM=""                               # "true" = 纯结构测试（如 bootstrap）
SKIP_HARNESS=""                         # "hermes" 表示该 case 在 hermes 下跳过
PRE_BOOTSTRAP="true"                    # 跑前是否先 bootstrap.sh
ASSERTIONS="assert_dir_has_md concepts
assert_status_field_gt STATUS.md total_files 0"
```

ASSERTIONS 多行字符串，每行一个断言；可用函数见 `lib/assert.sh`：

- `assert_file_exists <path>`
- `assert_dir_exists <path>`
- `assert_dir_has_md <dir>`
- `assert_dir_md_frontmatter <dir> <field> <expected>`
- `assert_status_field_gt <file> <field> <min>`
- `assert_status_field_ge <file> <field> <min>`
- `assert_feishu_option <file> <key> <expected>`
- `assert_md_added_count <marker> <expected_count>`

行内可用 `$(...)` 子命令（如 `journal/$(date +%Y-%m-%d).md`），在断言时展开。

## 清理 `.work/`

测试 fixture 不会自动清理（避免 destructive 操作）。手动：

```bash
find tests/.work -mindepth 1 -maxdepth 2 -mtime +1 -print
```

确认后用你信任的方式删除。

## 已知 harness 差异

| 差异 | Claude Code | Hermes |
|------|-------------|--------|
| Skill 激活 | 按 SKILL.md description 自动匹配 | 需 slash 命令显式调用 |
| 项目 CLAUDE.md | 自动加进系统上下文 | 无等效机制 |
| "始终在线"4 步流程 | ✅ 工作 | ❌ 不工作 |

因此 case `05-syncoff-persistence` 和 `06-syncoff-natural-lang` 在 Hermes 下被 `SKIP_HARNESS="hermes"` 显式跳过。这不是 bug，是 harness 设计选择。

## 状态码

| 状态 | 含义 | 触发 |
|------|------|------|
| **PASS** | harness 正常运行，所有断言通过 | 退出 0 |
| **FAIL** | harness 跑了但断言失败（或 harness 异常退出） | 退出 1 |
| **BLOCKED** | harness 被外部依赖挡住（代理、配额、认证），**不算项目层面失败** | 退出 77 |
| **SKIP** | case 显式声明 `SKIP_HARNESS=<本 harness>`（设计上的兼容差异） | 退出 78 |

### 已知 BLOCKED 场景

如果 `~/.claude/settings.json` 里的 `ANTHROPIC_BASE_URL` 指向一个**只接受 Claude Code 客户端**的代理（典型表现：HTTP 503 + 「No available accounts: this group only allows Claude Code clients」），那么 Hermes 走的 Anthropic Python SDK 由于 User-Agent 不匹配会被代理拒绝。

- 我们检测到这种 503 并把对应 case 标为 **BLOCKED**，不当 FAIL 处理。
- 修复方案：把 `~/.hermes/.env` 里的 `ANTHROPIC_API_KEY` 和 `ANTHROPIC_BASE_URL` 换成接受任意客户端的端点（如 `https://api.anthropic.com` + 一把真实 Anthropic key），重跑 `bash tests/run_all.sh`。
- 也可以临时只跑 Claude：`HARNESSES="claude" bash tests/run_all.sh`。

`run_one.sh` 的 `detect_blocker` 还会捕捉：
- HTTP 401/403 / `invalid_api_key` / `authentication_error` → BLOCKED（auth_error）
- HTTP 429 / `rate limit` → BLOCKED（rate_limited）
