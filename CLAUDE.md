# Knowledge Base Builder

AI 在问答中自动将知识沉淀到 `./` 下的结构化 Markdown 文件中，逐步构建可浏览、可关联的知识库。目录不存在则首次写入前自动创建。

> **本项目可作为 Claude Code skill pack 一键分发** — 详见 [`skills.json`](skills.json) 与 orchestrator skill [`.claude/skills/asknow/SKILL.md`](.claude/skills/asknow/SKILL.md)。
> - 源项目（本仓）保留本 `CLAUDE.md` 作为"始终在线"激活配置，每次问答都走 3 步 + 收尾流程。
> - 分发到目标项目时，编排规则已经搬到 `asknow` skill 里，**目标项目无需复制本文件**；如果目标项目希望同样保持"始终在线"，把 [`skills.json`](skills.json) 中的 `claude-md-snippet` 字段粘贴到自己的 `CLAUDE.md` 即可。
> - **一键安装** — 通过 [`vercel-labs/skills`](https://github.com/vercel-labs/skills) 安装器，支持 **54 个 agent harness**（Claude Code / OpenClaw / Hermes-Agent / Cursor / Codex / OpenCode / Windsurf 等）。**前提：本仓库已推到 public GitHub。** 把 `<owner>` 换成你的 GitHub 用户名：
>   ```bash
>   npx skills add <owner>/asknow -p                                          # Claude Code 项目级
>   npx skills add <owner>/asknow -g                                          # 全局
>   npx skills add <owner>/asknow -a claude-code -a openclaw -a hermes-agent  # 多 agent
>   npx skills add <owner>/asknow --skill asknow                              # 按需挑 skill
>   ```
> - `npx skills` 只拷 SKILL.md，不跑 bootstrap。`asknow` skill 首次激活时**自动**判断并按需创建 `wiki/` 骨架；或预先 `curl -fsSL https://raw.githubusercontent.com/<owner>/asknow/main/scripts/bootstrap.sh | bash` 手动 bootstrap。
> - 完全本地手动：克隆仓库 → `bash scripts/bootstrap.sh` → 把 `.claude/skills/` 复制到目标项目。

## 目录结构

```
wiki/
├── INDEX.md              # 全局索引（按分类+标签）
├── GRAPH.md              # Mermaid 知识关联图（按领域拆子图）
├── TAGS.md               # 标签注册表（受控词表）
├── STATUS.md             # 跨 session 状态（计数器+待处理队列）
├── concepts/             # 是什么 — 概念、定义、模型
├── howto/                # 怎么做 — 流程、步骤、指南
├── insights/             # 为什么 — 原理、洞察、趋势
├── references/           # 速查 — 参数、清单、对照表
├── decisions/            # 选什么 — 对比、选型、决策
├── cases/                # 案例 — 复盘、排障、实验
└── journal/              # 问答日志（按日期）
    └── archive/          # 季度归档（>90天）
```

## 分类规则

| 模式 | 目录 | 信号 |
|------|------|------|
| 定义、术语、模型 | concepts/ | "什么是" |
| 步骤、配置、流程 | howto/ | "怎么做""如何" |
| 原理、洞察、因果 | insights/ | "为什么" |
| 参数表、清单 | references/ | 表格/列表型 |
| 对比、选型 | decisions/ | "还是""怎么选" |
| 案例、排障、复盘 | cases/ | "遇到了" |

用户陈述同样沉淀：决策→decisions/，经验→cases/，补充事实→更新已有或新建 concepts/，观点→insights/。

**不写入：** 闲聊、纯指令、琐碎内容、`/norecord`。

## 深度与篇幅要求（默认行为，强约束）

> 知识沉淀的目标不是"记录发生了什么"，而是"产出一份脱离当时对话、半年后仍有阅读价值的笔记"。所有写入必须满足以下要求；如果一段内容撑不起这些要求，应**追加进已有文件**（在原文件下补章节），而不是新建一篇浅层笔记。

### 思考深度：必须覆盖三层

每一篇笔记都不能停在用户的字面问题上，必须显式回答以下三类问题中**至少三类**：

1. **是什么** — 定义、边界、与相邻概念的差异（"它不是什么"和"它是什么"同样重要）
2. **为什么** — 动机、底层原理、设计权衡、为何不是另一种方案
3. **怎么用 / 怎么选** — 典型场景、前置条件、反模式、与替代方案的横向对比（带 trade-off 表格）
4. **延伸** — 局限性、已知争议、演进趋势、与本库其他主题的关联

回答用户当下问题只是起点，沉淀必须主动补齐背景、动机、对比、风险中的缺失维度。

### 篇幅基线（中文字符）

| 类型 | 默认篇幅 | 必含结构 |
|------|---------|---------|
| concepts / insights | 800–2000 字 | 定义 + 原理 + 例子 + 与相邻概念对比 + 局限 |
| decisions | 1000–2500 字 | 候选方案表 + 各自 trade-off + 选型理由 + 适用边界 |
| howto | 不少于 800 字 | 步骤 + 每步**原理说明** + 易错点 + 验证方式 + 失败回退 |
| cases | 不少于 1000 字 | 现象 / 排查过程 / 根因 / 修复 / 复盘启示（五段不可省） |
| references | 篇幅放宽 | 但每个条目必须附 1–2 句解释，不允许只列名词或参数 |

少于下限的笔记需要在文件顶部 frontmatter 用 `depth_note:` 写明原因（如"领域共识，无更多可挖"）；否则视为质量不达标，必须扩写或合并。

### 信息密度要求

- **数据要硬：** 涉及数据、规格、性能、市场规模等事实，必须给具体数字 + 权威来源链接（官方文档、论文、行业报告）。禁止"较高、较多、显著、大量"等模糊表述。
- **例子要具体：** 至少 1 个可复现的例子（代码片段、真实场景、数据样本、命令输出），不能只有抽象描述。
- **关联要双向：** 至少 1 处指向本库其他文件的 `[[wiki-link]]`，并在被链接文件里回链；避免孤岛。
- **取舍要显式：** 涉及方案选择的，必须用表格写出 trade-off，不允许只罗列优点。
- **来源要可查：** 引用外部信息标注来源，避免"据说""一般认为"。

### 禁止的浅层模式

- 把对话里的回答原样复制粘贴成笔记
- 通篇要点列表，没有解释性段落和过渡
- 用"详见 X"代替本应展开的内容
- 没有任何 trade-off、反例、局限性、对立观点的"完美陈述"
- 一个文件只回答一个孤立问题，不与上下游概念产生连接

## 用户指令

| 指令 | 作用 | 持久化 |
|------|------|------|
| `/norecord` | 本次不写入知识库 | 否 |
| `/reclassify <目录>` | 指定归入目录 | 否 |
| `/retag <标签>` | 手动指定标签 | 否 |
| `/update <文件>` | 强制更新指定文件 | 否 |
| `/important` | 标记为高优先级 | 是（写入笔记 frontmatter） |
| `/nosync` | 本次跳过自动同步飞书 | 否 |
| `/syncoff` | 关闭自动同步 | 是（写 `FEISHU_MAP.md` `options.auto-sync-on-end: false`） |
| `/syncon` | 开启自动同步 | 是 |
| `/synctarget <URL\|list>` | 重新初始化飞书同步目标 | 是（写 `FEISHU_MAP.md` `target.*`） |
| `/syncnow` | 立即触发一次完整同步 | 否 |

**自然语言等价表达**（不必记 slash 命令）：

| 用户说 | 等价于 |
|--------|------|
| "这次先别同步" / "本次跳过同步" | `/nosync` |
| "关闭自动同步" / "暂停自动同步" | `/syncoff` |
| "开启自动同步" / "恢复自动同步" | `/syncon` |
| "切换同步目标" / "换个空间" / "同步到 <URL>" | `/synctarget` |
| "现在同步一下" / "推到飞书" | `/syncnow` |

## Skills

本项目包含三个 skill，按需加载以减少常驻 token：

### knowledge-write

- **位置：** `.claude/skills/knowledge-write/SKILL.md`
- **何时调用：** 每次交互的第 3 步"沉淀"中，当判断内容值得写入时调用
- **做什么：** 提供文件模板、粒度规则、命名规范、标签匹配、质量要求、多轮对话处理规则，执行写入并更新 journal 和 STATUS.md

### knowledge-maintenance

- **位置：** `.claude/skills/knowledge-maintenance/SKILL.md`
- **何时调用：** 满足以下任一条件时调用：
  - 用户主动要求（"整理知识库""维护索引"）
  - STATUS.md 中 total_files >= 20 且距 last_full_maintenance > 30 天
- **做什么：** 全库扫描 → 检测问题（死链/重复/孤岛/标签）→ 自动修复 → 重建 INDEX.md 和 GRAPH.md → 生成报告 → 更新 STATUS.md

### feishu-sync

- **位置：** `.claude/skills/feishu-sync/SKILL.md`
- **依赖：** [lark-cli](https://github.com/larksuite/cli)（Node.js ≥ 18；skill 内有"首次使用"剧本引导一键安装 + 一键建应用 / harness 一键绑定）
- **支持两种同步载体（首次初始化时由用户选择，配置写入 `FEISHU_MAP.md` 顶部 frontmatter）：**
  - `wiki` — 飞书知识库，按分类目录在 space 下建嵌套节点
  - `docs` — 飞书云文档，folder 下的 docx（富文本）或 markdown（.md 文件）列表
- **何时调用：**
  - 用户说"同步到飞书""推送到知识库""发布到 wiki""推送到飞书文档" / `/syncnow`
  - 用户说"切换同步目标""换个空间" / `/synctarget`（重新跑首次初始化）
  - **自动触发：** 每次交互沉淀后，若本回合有 md 更新 + `options.auto-sync-on-end=true` + 用户未跳过 → 收尾时增量推送
- **做什么：**
  - 首次初始化（步骤 5）：询问 wiki/docs、解析用户给的飞书 URL（`/wiki/space/<id>` / `/wiki/<node>` / `/drive/folder/<token>` 三种入口）或列出可选项，把目标写入 `FEISHU_MAP.md` frontmatter
  - 同步：读 md → 去 frontmatter → 替换 `[[wiki-link]]` 为飞书链接 → 按 target.type 走 wiki 或 docs 分支 → 不存在则创建、已存在且本地有更新则覆盖
  - 切换 / 开关：直接改 `FEISHU_MAP.md` frontmatter `target.*` 或 `options.auto-sync-on-end`

## 工作流

### Session 启动

读 STATUS.md → 了解计数器和待处理项 → 不存在则创建。

### 每次交互（3 步 + 收尾）

1. **检索：** 按关键词扫描相关目录文件名 + INDEX.md，命中则读"核心要点"辅助回答。冷启动跳过。
2. **回答：** 第一优先级，回答质量永远高于知识沉淀。回答应尽量引用权威来源（官方文档、学术论文、行业报告等），尤其涉及数据统计、市场规模、技术规格等事实性内容时，必须标注信息来源。
3. **沉淀：** 判断是否值得写入 → 是则调用 `knowledge-write` skill 执行，并**严格遵守上方"深度与篇幅要求"**：先按三层维度补齐思考再动笔，达不到篇幅基线的优先合并进已有文件而非新建。
4. **收尾 — 自动同步飞书（默认开启）：** 沉淀完成后、最终回复给用户**之前**，按以下顺序判断是否自动推到飞书：
   1. 本回合有 md 文件被新建 / 更新吗？无 → 跳过。
   2. 读 `FEISHU_MAP.md` 顶部 `options.auto-sync-on-end`：`false` → 跳过（轻量提示一句"本回合 N 个文件未同步，自动同步已关闭"）。
   3. `FEISHU_MAP.md` 顶部有 `target` 配置吗？无 → 收尾里问用户"要现在初始化飞书同步吗？"（启动 `feishu-sync` 步骤 5）。
   4. 用户本回合说过"本次跳过同步" / `/nosync` 吗？是 → 跳过。
   5. 以上都通过 → 调用 `feishu-sync` 核心流程，传入本回合变更文件列表（增量集合），把同步报告附在最终回复末尾。
   
   **要点：** 自动同步不是单独一轮对话，而是当前回合最终回复的一部分；用户体验应当是"我问问题 → AI 回答 + 在回答末尾说『顺便已同步到飞书，链接如下』"。

### 延迟维护（读 STATUS.md 判断）

| 触发条件 | 操作 |
|---------|------|
| files_since_last_index >= 5 | 重建 INDEX.md |
| relations_since_last_graph >= 5 | 重建 GRAPH.md |
| total_files >= 20 且距 last_full_maintenance > 30 天 | 调用 `knowledge-maintenance` skill |
| 距 last_journal_archive > 90 天 | 归档 journal |
