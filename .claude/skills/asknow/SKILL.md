---
name: asknow
description: "知识库自动沉淀编排器 — 在问答交互中自动检索已有笔记、回答时引用权威来源、回答后按分类规则与深度要求沉淀到结构化 Markdown，并维护索引、标签、关系图。覆盖 concepts/howto/insights/references/decisions/cases/journal 七大目录的分类规则、篇幅与深度基线、`/norecord` 等用户控制指令、延迟维护触发条件，以及到飞书知识库的可选同步。激活关键词：知识库 / wiki / 笔记 / 沉淀 / second brain / 学习 / 整理 / 复习 / 调研 / 复盘。"
metadata:
  delegates:
    - knowledge-write
    - knowledge-maintenance
    - feishu-sync
  bootstrap: "scripts/bootstrap.sh"
  data-root: "./"
---

# Asknow — 知识沉淀编排器

把每一次 AI 问答都变成可检索、可关联、可溯源的 Markdown 笔记。本 skill 是编排层，本身不直接写文件；写入、维护、同步分别委派给 `knowledge-write`、`knowledge-maintenance`、`feishu-sync` 三个子 skill。

> 本 skill 是 asknow 项目的可分发部分，不依赖项目根 `CLAUDE.md` 即可独立工作。如果目标项目希望"永远在线"激活（每次问答自动走 3 步 + 收尾流程），把下文"始终在线模式"段落复制到目标项目的 `CLAUDE.md` 即可。

## 何时激活

满足任一条件即激活本 skill：

- 用户在一个有 `INDEX.md` / `STATUS.md` / 任一知识目录的项目里发起问答
- 用户明确要求"沉淀""记到知识库""整理这段对话"
- 用户用了 `/norecord` 等本 skill 的控制指令
- 用户要求"维护知识库""清理 wiki""同步到飞书"

不激活：闲聊、纯执行性指令（"删掉这个文件"）、对当前代码库的具体修改任务。

## Bootstrap 检查（首次激活）

激活时先检查项目根的目录骨架。缺失则**询问用户**是否初始化（一次确认即可）：

```bash
ls STATUS.md INDEX.md 2>/dev/null
ls concepts howto insights references decisions cases journal 2>/dev/null
```

任一缺失 → 跑同目录 `scripts/bootstrap.sh`（若存在）或手动创建占位：

```
./
├── INDEX.md          # 全局索引（按分类+标签）
├── GRAPH.md          # Mermaid 知识关联图
├── TAGS.md           # 标签注册表
├── STATUS.md         # 跨会话状态（计数器 + 待处理队列）
├── FEISHU_MAP.md     # 飞书同步映射（仅启用 feishu-sync 时需要）
├── concepts/         # 是什么
├── howto/            # 怎么做
├── insights/         # 为什么
├── references/       # 速查
├── decisions/        # 选什么
├── cases/            # 案例
└── journal/          # 问答日志（按日期）
    └── archive/      # 季度归档（>90 天）
```

`STATUS.md` 初始模板：

```markdown
# Knowledge Base Status

- total_files: 0
- files_since_last_index: 0
- relations_since_last_graph: 0
- last_full_maintenance: null
- last_journal_archive: null
- pending: []
```

## 每次交互的 3 步工作流

### 步骤 1 — 检索

按用户提问的关键词，扫描相关目录文件名 + `INDEX.md`。命中则读对应文件的"核心要点"章节，作为回答上下文。冷启动（无 INDEX）跳过。

### 步骤 2 — 回答

**第一优先级。回答质量永远高于知识沉淀。** 回答应：

- 优先引用一手来源（官方文档、学术论文、行业报告、原始数据）
- 涉及数据 / 市场规模 / 技术规格时必须标注来源与时间
- 避免"较高""较多""一般认为"等模糊表述

### 步骤 3 — 沉淀（按需委派 knowledge-write）

判断是否值得写入。**值得写入**的信号：

- 用户陈述了一个事实、决策、经验、观点
- AI 回答中包含可复用的概念、流程、对比、案例
- 用户研究、复盘、选型、调研类对话

**不写入：** 闲聊、纯指令、琐碎内容、`/norecord`。

值得写入 → 调用子 skill `knowledge-write`，并把以下决策一起传递：

- 归入哪个目录（按下方"分类规则"）
- 是新建还是追加进已有文件（深度不足时优先追加）
- 关联到哪些已有笔记（双向链接）

写入完成后由 `knowledge-write` 顺手更新 `journal/YYYY-MM-DD.md` 与 `STATUS.md` 计数器。

### 步骤 3 收尾 — 自动同步检查（默认开启）

本回合的"沉淀"完成后、对话即将收尾时，按以下顺序检查是否要把本回合的更新自动推到飞书：

1. **本回合有 md 文件被新建 / 更新吗？**
   - 否 → 跳过同步，直接收尾
   - 是 → 进入 2
2. **读 `FEISHU_MAP.md` 顶部 frontmatter 的 `options.auto-sync-on-end`：**
   - `false` → 跳过；在收尾里轻量提示一句："本回合 N 个文件更新未同步（自动同步已关闭，发『开启自动同步』可恢复）"
   - `true` 或字段不存在（默认开启） → 进入 3
3. **`FEISHU_MAP.md` 顶部有 `target` 配置吗？**
   - 没有 → 在收尾里问用户："本回合产生了 N 个新笔记。要现在初始化飞书同步吗？回是则启动 feishu-sync 步骤 5（选 wiki/docs + 解析目标地址）。"
   - 有 → 进入 4
4. **用户在本回合说过"本次跳过同步"吗？**
   - 是 → 跳过
   - 否 → 调用 `feishu-sync`，传入本回合变更文件列表（增量集合）
5. 把 `feishu-sync` 返回的同步报告（新建数、更新数、跳过数、链接清单）作为对话收尾的一部分附给用户。

**自动同步的触发时机** = 本回合的最后一次助手回复**之前**。它不是单独的一轮对话；用户感受应当是"我问问题 → AI 回答 + 在回答末尾说『顺便同步到飞书了，链接如下』"。

## 分类规则

| 模式 | 目录 | 触发信号 |
|------|------|---------|
| 定义、术语、模型 | `concepts/` | "什么是" |
| 步骤、配置、流程 | `howto/` | "怎么做""如何" |
| 原理、洞察、因果 | `insights/` | "为什么" |
| 参数表、清单 | `references/` | 表格/列表型 |
| 对比、选型 | `decisions/` | "还是""怎么选" |
| 案例、排障、复盘 | `cases/` | "遇到了""复盘" |

用户陈述同样沉淀：决策 → `decisions/`，经验 → `cases/`，事实补充 → 更新已有或新建 `concepts/`，观点 → `insights/`。

## 深度与篇幅要求（强约束）

> 沉淀的目标不是"记录发生了什么"，而是"产出一份脱离当时对话、半年后仍有阅读价值的笔记"。一段内容撑不起以下要求 → **追加进已有文件**，而不是新建一篇浅层笔记。

### 思考深度：必须覆盖三层

每篇笔记显式回答以下四类问题中**至少三类**：

1. **是什么** — 定义、边界、与相邻概念的差异
2. **为什么** — 动机、底层原理、设计权衡
3. **怎么用 / 怎么选** — 典型场景、前置条件、反模式、与替代方案的横向对比（带 trade-off 表格）
4. **延伸** — 局限性、争议、演进趋势、与本库其他主题的关联

### 篇幅基线（中文字符）

| 类型 | 默认篇幅 | 必含结构 |
|------|---------|---------|
| concepts / insights | 800–2000 字 | 定义 + 原理 + 例子 + 与相邻概念对比 + 局限 |
| decisions | 1000–2500 字 | 候选方案表 + 各自 trade-off + 选型理由 + 适用边界 |
| howto | 不少于 800 字 | 步骤 + 每步**原理说明** + 易错点 + 验证方式 + 失败回退 |
| cases | 不少于 1000 字 | 现象 / 排查过程 / 根因 / 修复 / 复盘启示（五段不可省） |
| references | 篇幅放宽 | 但每个条目必须附 1–2 句解释，不允许只列名词或参数 |

少于下限的笔记需要在 frontmatter 加 `depth_note:` 写明原因；否则视为质量不达标，必须扩写或合并。

### 信息密度要求

- **数据要硬：** 涉及数据、规格、性能、市场规模等事实，必须给具体数字 + 权威来源链接。禁止"较高、较多、显著、大量"等模糊表述。
- **例子要具体：** 至少 1 个可复现的例子（代码片段、真实场景、数据样本、命令输出）。
- **关联要双向：** 至少 1 处指向本库其他文件的 `[[wiki-link]]`，并在被链接文件里回链。
- **取舍要显式：** 涉及方案选择的，必须用表格写出 trade-off。
- **来源要可查：** 引用外部信息标注来源。

### 禁止的浅层模式

- 把对话回答原样复制粘贴
- 通篇要点列表，没有解释性段落和过渡
- 用"详见 X"代替本应展开的内容
- 没有 trade-off、反例、局限性的"完美陈述"
- 一个文件只回答一个孤立问题，不与上下游概念产生连接

## 用户控制指令

对话中识别以下前缀指令并改变沉淀行为：

| 指令 | 作用 | 持久化 |
|------|------|------|
| `/norecord` | 本次不写入知识库 | 否 |
| `/reclassify <目录>` | 强制归入指定目录 | 否 |
| `/retag <标签>` | 手动指定标签 | 否 |
| `/update <文件>` | 强制更新指定已有文件而非新建 | 否 |
| `/important` | 标记为高优先级（frontmatter `importance: high`） | 是（写入笔记 frontmatter） |
| `/nosync` | 本次跳过自动同步飞书 | 否 |
| `/syncoff` | 关闭自动同步开关 | 是（写 `FEISHU_MAP.md` `options.auto-sync-on-end: false`） |
| `/syncon` | 开启自动同步开关 | 是 |
| `/synctarget <URL\|list>` | 重新初始化飞书同步目标（贴 URL 自动解析，回 `list` 列出可选） | 是（写 `FEISHU_MAP.md` `target.*`） |
| `/syncnow` | 立即触发一次完整同步，无视开关状态 | 否 |

**自然语言等价表达**（用户不必记 slash 命令，下列说法也识别为对应行为）：

| 用户说 | 等价于 |
|--------|------|
| "这次先别同步" / "本次跳过同步" | `/nosync` |
| "关闭自动同步" / "暂停自动同步" / "停止自动同步" | `/syncoff` |
| "开启自动同步" / "恢复自动同步" | `/syncon` |
| "切换同步目标" / "换个空间" / "换个文件夹" / "同步到 <URL>" | `/synctarget` |
| "现在同步一下" / "立即同步" / "推到飞书" | `/syncnow` |

## 子 skill 委派

| 触发 | 调用 |
|------|------|
| 3 步工作流中"沉淀"判定为是 | `knowledge-write` |
| 用户说"整理 / 维护知识库""清理 wiki" | `knowledge-maintenance` |
| `STATUS.md` 中 `total_files >= 20` 且距 `last_full_maintenance` > 30 天 | `knowledge-maintenance`（在告知用户后） |
| 用户说"同步到飞书""推送到 wiki""推送到飞书文档" / `/syncnow` | `feishu-sync`（核心流程） |
| 步骤 3 收尾检测到本回合有 md 更新 + `options.auto-sync-on-end=true` + 用户未跳过 | `feishu-sync`（核心流程，增量） |
| 首次同步前 / 用户说"切换同步目标" / `/synctarget` | `feishu-sync` 步骤 5（首次初始化） |
| 用户说"关闭/开启自动同步" 或 `/syncoff` `/syncon` | 直接改写 `FEISHU_MAP.md` 顶部 frontmatter `options.auto-sync-on-end`，不调子 skill |

## 延迟维护触发条件

读 `STATUS.md` 判断：

| 条件 | 操作 |
|------|------|
| `files_since_last_index >= 5` | 重建 `INDEX.md`（轻量，可在写入后顺手做） |
| `relations_since_last_graph >= 5` | 重建 `GRAPH.md`（轻量） |
| `total_files >= 20` 且距 `last_full_maintenance` > 30 天 | 调用 `knowledge-maintenance`（重量，先告知用户） |
| 距 `last_journal_archive` > 90 天 | 归档 `journal/` 到 `journal/archive/<季度>/` |

每次满足条件并执行后更新对应字段。

## 始终在线模式（可选）

本 skill 默认按 Claude Code 标准激活机制（description 匹配）触发。如果希望"每次对话都走 3 步 + 收尾流程"（更像项目根 `CLAUDE.md` 的常驻行为），在目标项目的 `CLAUDE.md` 顶部加一段：

```markdown
## 知识沉淀（始终在线）

任何问答交互后，**始终激活 `asknow` skill** 走 4 步：检索 → 回答 → 沉淀 → 收尾（自动同步飞书）。

- **沉淀**：达不到深度基线时优先追加进已有文件，而不是新建浅层笔记。
- **收尾**：若本回合有 md 更新且 `FEISHU_MAP.md` 顶部 `options.auto-sync-on-end: true`（默认），调用 `feishu-sync` 把变更增量推到飞书，把同步报告附在最终回复末尾。
- **用户控制**：`/norecord`（跳过沉淀）/ `/nosync`（跳过本次同步）/ `/syncoff` `/syncon`（开关）/ `/synctarget`（切换 wiki/docs 目标）/ `/syncnow`（立即同步）。自然语言等价表达由 `asknow` skill 内部识别。
```

加上这段后无论用户提问关键词是否匹配，Claude 都会主动走流程。

> 这段 snippet 与 [`skills.json`](../../../skills.json) 中的 `claude-md-snippet` 字段保持一致；当 OpenClaw / Hermes 这类安装器读取 `skills.json` 自动配置目标项目 CLAUDE.md 时，应注入相同内容。

## 关联文件与来源

- 项目说明：[`README.zh-CN.md`](../../../README.zh-CN.md)（英文版 [`README.md`](../../../README.md)）
- 子 skill：
  - [`knowledge-write`](../knowledge-write/SKILL.md) — 写入与更新单篇笔记
  - [`knowledge-maintenance`](../knowledge-maintenance/SKILL.md) — 全库扫描与修复
  - [`feishu-sync`](../feishu-sync/SKILL.md) — 同步到飞书（首次初始化时选 wiki 知识库或 docs 云文档；默认对话结束自动增量推送）
- 首次激活引导脚本：[`scripts/bootstrap.sh`](../../../scripts/bootstrap.sh)
- 分发清单与 harness 适配：[`skills.json`](../../../skills.json)
