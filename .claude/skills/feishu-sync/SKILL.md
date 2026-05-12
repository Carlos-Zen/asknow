---
name: feishu-sync
description: "把本地知识库 Markdown 同步到飞书。ALWAYS invoke this skill when the user 用以下任一自然语言短语表达同步意图：同步到飞书、推到飞书、推到 wiki、推到飞书文档、发布到飞书、立即同步、现在同步一下、关闭自动同步、暂停自动同步、停止自动同步、开启自动同步、恢复自动同步、切换同步目标、换个空间、换个文件夹、本次跳过同步、本次不要同步。支持两种目标：飞书知识库 wiki（嵌套节点）或飞书云文档（folder 下的 docx / markdown）。首次初始化时由用户选择目标类型并指定知识空间 / 文件夹（或贴飞书链接自动解析），之后默认同步到既定目标；每次对话有更新默认自动推送，可对话切换关闭。"
metadata:
  requires:
    bins: ["lark-cli"]
    upstream: "https://github.com/larksuite/cli"
    node: ">=18"
  harness:
    supports: ["openclaw", "hermes"]
    detect-env: ["OPENCLAW_HOME", "HERMES_HOME"]
    bind-command: "lark-cli config bind --identity user-default"
    recommended-identity: "user-default"
    identity-rationale: "本 skill 同步本地知识库到个人 wiki（my_library），写入个人资源需要 user 身份；若只同步到团队空间则回退 bot-only。"
    fallback-identity: "bot-only"
    skip-auth-login-when-bound: true
---

# Feishu Sync

把 `./` 下的 Markdown 同步到飞书。首次初始化时由用户选目标类型，配置写入 `FEISHU_MAP.md` 顶部 frontmatter；之后默认按既定目标增量同步，对话结束有更新自动推送（可对话关闭）。

| 类型 | 目标 | 适合 |
|------|------|------|
| `wiki` | 飞书知识库，嵌套节点 | 团队共享、分类深 |
| `docs` | 云空间 folder 下 docx / .md 文件列表 | 个人速记、扁平结构 |

## 依赖

- [lark-cli](https://github.com/larksuite/cli)（Node.js ≥ 18）
- 飞书账号 + 自建应用凭证（步骤 2 自动建）
- （可选）如果你已经从 lark-cli skill 包里装了 `lark-shared` skill（同样落到 `.claude/skills/lark-shared/` 下），可读 [`../lark-shared/SKILL.md`](../../lark-shared/SKILL.md) 了解 scope / 权限处理细节；未装时本 skill 自包含全部必要步骤，可直接跳过此条

## 首次使用：自动安装与初始化

> **总原则：** 破坏性 / 登录操作先告知用户并等确认。完成步骤 0–5 后才进入"核心流程"。

### 步骤 0 — 环境探测（只读）

```bash
command -v lark-cli && lark-cli --version
command -v node && node --version
echo "OPENCLAW_HOME=${OPENCLAW_HOME:-} HERMES_HOME=${HERMES_HOME:-}"
lark-cli auth status 2>&1 || true
test -f ~/.config/lark-cli/config.toml && echo config:exists || echo config:missing
```

| 状态 | 走哪几步 |
|------|---------|
| Node < 18 | 中断，先升级 Node |
| lark-cli 不存在 | 1 → 2 → 3 → 4 → 5 |
| lark-cli 在、config 缺失 | 2 → 3 → 4 → 5 |
| lark-cli 在、未登录 | 3 → 4 → 5 |
| 已登录 | 4 → 5 |
| `OPENCLAW_HOME` / `HERMES_HOME` 已设置 | 步骤 2 改走 `config bind` |

### 步骤 1 — 装 lark-cli

```bash
npm install -g @larksuite/cli
```

失败：EACCES → 改 nvm 或 `npm config set prefix ~/.npm-global`（不要 sudo）；网络 → 切 `npm config set registry https://registry.npmmirror.com`；PATH 未生效 → `source ~/.zshrc`。装完 `lark-cli --version` 校验。

### 步骤 2 — 配置应用凭证

**普通环境** — 一键建应用，用户全程不复制凭证：

```bash
lark-cli config init --new --brand feishu --lang zh
```

Claude Code 后台跑（`run_in_background: true`），`TaskOutput` 轮询 stdout 抓 verification URL → 发给用户在浏览器完成 → `TaskOutput block: true` 等命令退出 → `lark-cli config show` 校验。

**Agent 环境**（`OPENCLAW_HOME` / `HERMES_HOME` 已设置）— 一键绑定 harness 现有应用：

1. **必问用户身份**（不静默默认）：
   > "默认 `user-default`（能写个人知识库 `my_library`）；只同步团队空间回 `bot-only`。"
2. ```bash
   lark-cli config bind --identity user-default   # 或 bot-only
   ```
   绑定即生效，**步骤 3 跳过**。`--source` 不用写，lark-cli 看环境变量自动识别。
3. `lark-cli config show` 校验后进步骤 4。

特殊：用户在 Agent 环境想建独立应用 → 加 `--force-init`；只换身份策略（不换底层应用） → `lark-cli config strict-mode`，**不要**重 bind；多账号 OpenClaw → `config bind --app-id <id> --identity user-default`。

用户说"我已有凭证"：`printf '%s' "$SECRET" | lark-cli config init --app-id "$APPID" --app-secret-stdin --brand feishu`。

### 步骤 3 — OAuth 登录（Agent 环境跳过）

非阻塞两段式：

```bash
# 第一段：返回 JSON 含 verification_uri_complete + device_code
lark-cli auth login --recommend --no-wait --json

# 把 verification_uri_complete 发给用户在浏览器点同意

# 第二段：等用户完成（阻塞）
lark-cli auth login --device-code <code>
```

scope 不全 → `lark-cli auth login --domain wiki,docs,drive`；device code 过期 → 重跑第一段。完成跑 `lark-cli auth status` 确认。

### 步骤 4 — 健康检查

```bash
lark-cli doctor
lark-cli wiki +space-list --limit 3
```

权限报错 → 回步骤 3 用 `--domain` 补 scope。

### 步骤 5 — 首次初始化目标

> **只首次执行一次。** 配置写入 `FEISHU_MAP.md` 顶部 frontmatter，后续同步自动读。用户说"切换同步目标"重新触发本步骤。

**5.1 检查是否已配置** — 读 `FEISHU_MAP.md`：
- 不存在 → 5.2
- 有 `<!-- asknow-sync: ... -->` → 跳过整个步骤 5
- 旧 `<!-- space_id: ... -->` 形式 → 自动迁移为新 frontmatter（`target.type=wiki`，space-id 取原值，`auto-sync-on-end=true`），告知用户

**5.2 问类型：** "wiki（知识库嵌套）还是 docs（云空间 folder）？"

**5.3 问目标：** 接受任一：
- 飞书链接（推荐，自动解析）
- `my_library`（仅 wiki，个人知识库）
- `root`（仅 docs，云空间根）
- `list`（让 Claude 列可选）

**5.4 URL 解析：**

| URL 模式 | 解析 |
|---------|------|
| `…/wiki/space/<id>` | `type=wiki`, `space-id=<id>` |
| `…/wiki/<token>`（不含 /space/） | `type=wiki`；用 `lark-cli wiki +node-get-space --token <token>` 反查 space-id，写入 `parent-node=<token>` |
| `…/drive/folder/<token>` | `type=docs`, `folder-token=<token>` |
| `…/docx/<token>` / `…/docs/<token>` | 拒绝：单篇文档不是容器，要求重发 |
| 解析失败 | 让用户重发 |

权限校验：
- wiki：`lark-cli wiki space.nodes --params '{"space_id":"<id>"}' --page-size 1`
- docs：`lark-cli drive files --params '{"folder_token":"<token>"}' --page-size 1`

无权限 → 让用户换目标或先给应用 / 用户授权。

**5.5 用户回 `list`：**
- wiki：`lark-cli wiki +space-list --limit 20`
- docs：`lark-cli drive files --params '{}' --page-size 20 | jq '.items[]|select(.type=="folder")'`

表格化展示给用户选编号。

**5.6 type=docs 追问格式：** "docx（推荐，富文本）还是 markdown（保留 .md）？" 写入 `target.docs-format`。

**5.7 写入 FEISHU_MAP.md frontmatter：**

```markdown
<!--
asknow-sync:
  target:
    type: wiki                       # wiki | docs
    space-id: 7xxxxxxxxxxxxx         # wiki: 空间 ID 或 my_library
    parent-node: wikcnPARENT         # wiki: 可选，作子节点 parent
    folder-token: fldXXXXXXXX        # docs: 根留空
    docs-format: docx                # docs: docx | markdown
    source-url: https://xxx.feishu.cn/wiki/space/7xxxxxxxxxxxxx
  options:
    auto-sync-on-end: true
  configured-at: 2026-05-11T18:30
-->
# 飞书同步映射

> 自动维护，勿手动编辑表格。配置通过对话调整。

| 本地路径 | 飞书 token | 飞书 URL | 最后同步时间 | 本地 updated |
|---------|----------|----------|------------|-------------|
| concepts/raft.md | wikcnAAAAAAAA | https://example.feishu.cn/wiki/wikcnAAAAAAAA | 2026-05-11T18:32 | 2026-05-11 |
```

只写当前 `target.type` 用到的字段；其它字段省略。`configured-at` 本地时区 `YYYY-MM-DDTHH:MM`。**列名兼容：** 解析时 `飞书 token` 与旧 `飞书 node_token` 都接受；写入统一用 `飞书 token`。

完成后告知用户："目标已锁定：{type} → {显示名}（{URL}）。后续自动同步默认开（『关闭自动同步』可关）。"

## 触发场景

- "同步到飞书" / "推送到 wiki" / "推送到飞书文档" / "立即同步"
- "切换同步目标" / "换个空间" / "换个文件夹"
- "关闭/开启自动同步"
- **自动**：orchestrator 检测到本回合有 md 更新 + `auto-sync-on-end=true` + 用户未跳过 → 收尾时调用

## 核心流程

### 1. 范围

- 用户指定文件 / 目录 → 该范围
- "全部同步" → 6 个知识目录下所有 .md
- 自动触发 → 本回合改动的增量集合

排除：`INDEX.md` / `GRAPH.md` / `TAGS.md` / `STATUS.md` / `FEISHU_MAP.md` / `journal/`。

### 2. 创建 vs 更新

读 FEISHU_MAP 表，对每个文件：
- 不在表 → 新建（3a）
- 在表 且本地 `updated` > 表中"最后同步时间" → 更新（3b）
- `updated` 未变 → 跳过

### 3a. 创建（按 target.type）

**wiki：**
```bash
lark-cli docs +create \
  --wiki-space "$SPACE_ID" \
  --wiki-node "$PARENT_OR_EMPTY" \
  --title "$TITLE" \
  --markdown @/tmp/processed.md
```

**docs (docx)：**
```bash
lark-cli docs +create \
  --folder-token "$FOLDER_TOKEN" \
  --title "$TITLE" \
  --markdown @/tmp/processed.md
```

**docs (markdown)：**
```bash
lark-cli markdown +create \
  --folder-token "$FOLDER_TOKEN" \
  --name "$TITLE.md" \
  --file /tmp/processed.md
```

返回 token + URL，写入 FEISHU_MAP 表格。

### 3b. 更新

**wiki / docs(docx)：**
```bash
lark-cli docs +update --api-version v2 \
  --doc "$TOKEN_OR_URL" \
  --command overwrite \
  --doc-format markdown \
  --content @/tmp/processed.md
```

**docs(markdown)：**
```bash
lark-cli markdown +overwrite \
  --file-token "$FILE_TOKEN" \
  --file /tmp/processed.md
```

刷新表中"最后同步时间"。

## 内容预处理

写入前顺序处理本地 markdown：

1. **去 frontmatter：** 删 `---` ... `---` 之间内容（含分隔线）
2. **替换 wiki-link：** `[[...]]` 查 FEISHU_MAP 表 → 命中替换 `[显示](URL)`；未命中去括号成普通文本 + `<!-- 未同步: path -->`
3. **清理章节：** 移"关联知识"段（链接已替换）；留"引用来源"段

## 自动同步开关

开关字段 `options.auto-sync-on-end`（默认 `true`）在 `FEISHU_MAP.md` 顶部 frontmatter。

| 用户说 | 行为 | 持久化 |
|--------|-----|------|
| "本次跳过" / "本次不要同步" | 当回合 skip | 否 |
| "关闭自动同步" / "暂停自动同步" | `auto-sync-on-end: false` | 是 |
| "开启自动同步" / "恢复自动同步" | `auto-sync-on-end: true` | 是 |
| "现在同步一下" / "立即同步" / "推到飞书" | 立即执行完整同步 | 否 |

修改时**只动那一行**，保留其它字段与表格。

### Orchestrator 集成约定

orchestrator（`asknow` skill）在每次交互的步骤 3 沉淀末尾：

1. 本回合无 md 更新 → 结束
2. `auto-sync-on-end=false` → 结束（可选轻提示）
3. FEISHU_MAP 无 `target` → 问用户是否现在初始化（启动本 skill 步骤 5）
4. 用户本回合说过"本次跳过" → 结束
5. 否则调用本 skill 核心流程（传入变更文件清单）→ 同步报告附在最终回复

自动同步触发时机 = 本回合最终回复**之前**，作为回复一部分，不单独占一轮。

## 切换同步目标

用户说"切换同步目标""换个空间"等：

1. 确认意图 — 现有表格保留，新文档去新目标
2. 重跑步骤 5.2–5.7
3. 旧文档继续更新到原 URL，新建落新目标
4. 提示：批量迁移未实现，需手动

## 目录结构映射

**type=wiki：** 6 个分类目录映射为一级节点：
1. 首次同步某目录时检查空间是否已有同名一级节点
2. 没有则建：`docs +create --wiki-space "$ID" --wiki-node "$ROOT_OR_PARENT" --title "概念 (concepts)" --markdown "(分类目录)"`
3. 后续文件建到对应一级节点下：`--wiki-node <分类节点 token>`
4. 一级节点也记录在 FEISHU_MAP 表（路径标记 `_dir/concepts`）

**type=docs：** 默认扁平 + 前缀（"`[concepts] Raft 共识算法`"）；用户明确"按目录分子文件夹"时记录 `target.subfolder-by-category: true`，在目标 folder 下建同名子文件夹。

## 同步报告

```
飞书同步完成 → {type} / {目标名}
- 新建：N 个 · path → URL …
- 更新：M 个 · path → URL …
- 跳过：K 个（无变更）
- 失败：F
```

自动触发时附在对话收尾，不单独占一轮。

## 注意事项

- 只做单向同步（本地 → 飞书），不拉回；不同步元文件与 `journal/`。
- `overwrite` 清空重写，会丢失飞书端手动评论 / 图片 — 同步前提醒。
- 飞书 Markdown 不支持 Mermaid 等，`GRAPH.md` 不适合同步。
- 批量同步在每次 API 之间加 200–500ms 延迟避免限流。
- token 前缀：`wikcn`（wiki 节点）/ `docx`（云文档）/ `fld`（drive 文件夹）— 统一存进 `飞书 token` 列。
- 遇旧 `<!-- space_id: ... -->` 格式自动升级到新 frontmatter。
