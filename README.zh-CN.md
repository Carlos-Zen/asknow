# AskNow — 在问答中沉淀你的知识库

> [English](./README.md) · **简体中文**

> 你只管和 Claude 聊天，它替你把每一次问答变成可检索、可关联、可溯源的 Markdown 笔记。
> 三个月后回头看，你会拥有一座自己的"第二大脑"，而且 Claude 在下一次提问时会**真的读过它**。

---

## 为什么需要它

每个人都遇到过这样的场景：

- 上周问了一个技术问题，AI 给了很好的回答，**这周再用时已经记不清细节**。
- 同一个问题在不同会话里重复问了三遍，**每次都从零开始**。
- 想做技术调研、读一本书、追一个领域，**笔记零散在 Notion / Apple Notes / 微信收藏里**，找不回来也连不起来。
- 问 AI 时它的回答很好，但**回答只属于那次会话**，关掉窗口就消失了。

**Knowledge Base Builder 解决两件事：**

1. **沉淀** — 让 AI 的输出从"一次性消费品"变成"复利资产"。
2. **复用（更重要）** — 让 AI 在下一次对话时，**真的读过你的过往研究**，给出贴合你具体处境的创意、方案、决策建议，而不是套话连篇的通用回答。

它不是一个新的笔记软件，也不是一个聊天机器人皮肤。它是一份注入到 Claude Code 的"工作守则"，让 Claude 在每一次回答之后自动沉淀；并在下一次提问时，把你的笔记当作长期上下文来用——你过去研究过的标杆、否决过的方案、形成的判断，全部能被精准调用。这座知识库长在你的硬盘上，归你所有，可被任何编辑器打开，也可同步到飞书等团队空间。

---

## 一句话介绍

**Knowledge Base Builder = Claude Code + 一份 CLAUDE.md 守则 + 1 个 orchestrator skill + 3 个执行 skill。**

启动 Claude Code 进入项目目录，正常聊天。Claude 会：

1. **检索** — 回答前先扫一眼你已有的笔记，命中相关条目就先读后答。
2. **回答** — 优先保证回答质量，引用权威来源。
3. **沉淀** — 判断是否值得写入 → 是则按分类规则、深度要求、关联策略写成结构化 Markdown，并维护索引、标签、关系图。
4. **收尾（自动同步飞书）** — 本回合有更新且自动同步开关开着（默认开）→ 增量推到你最初指定的飞书目标（wiki 知识库或云文档 folder），把同步链接附在最终回复末尾。

整个过程不打扰对话节奏，知识库自动生长，飞书侧也自动跟着长。

---

## 它长什么样

知识库住在项目根目录 `./` 下，按"知识的本质"而非"时间顺序"组织：

```
./
├── INDEX.md              # 全局索引（按分类 + 标签）
├── GRAPH.md              # Mermaid 知识关联图
├── TAGS.md               # 受控词表
├── STATUS.md             # 跨会话状态：计数器、待处理项
├── concepts/             # 是什么 — 概念、定义、模型
├── howto/                # 怎么做 — 流程、步骤、指南
├── insights/             # 为什么 — 原理、洞察、趋势
├── references/           # 速查 — 参数、清单、对照表
├── decisions/            # 选什么 — 对比、选型、决策
├── cases/                # 案例 — 复盘、排障、实验
└── journal/              # 问答日志（按日期）
    └── archive/          # 季度归档
```

每篇笔记都是一份带 YAML frontmatter 的独立 Markdown（取自一个真实的 AI 创业商业调研库 [`../ac`](../ac)）：

```markdown
---
title: Harvey 深度复盘 — 法律垂直 AI 如何建立护城河
category: cases
tags: [AI创业, 垂直应用, 护城河, 法律科技]
related:
  - path: concepts/ai-application-moat-defensibility.md
    type: 应用
  - path: insights/ai-application-startup-landscape-2026.md
    type: 关联
  - path: decisions/ai-business-model-selection-2026.md
    type: 对比
created: 2026-05-08
updated: 2026-05-08
importance: high
---

# Harvey 深度复盘

## 核心要点
3–5 句话概括 ...

## 详细内容
背景 → 产品演进 → 客户与定价 → 护城河分析 → 启示 ...
```

笔记之间用 `[[wiki-link]]` 双向关联，自动汇入 `GRAPH.md`，形成一张你专属的知识网。

---

## 它和其他东西的区别

| 维度 | 普通笔记软件 (Notion/Obsidian) | 直接和 ChatGPT 聊 | **Knowledge Base Builder** |
|------|-----------------------------|-----------------|---------------------------|
| 内容产出 | 全靠你手打 | AI 写得好但留不下 | **AI 边答边记** |
| 结构组织 | 你自己设计目录 | 没结构 | **强制分类 + 模板** |
| 关联关系 | 手动建链 | 无 | **AI 自动维护双向链接** |
| 沉淀深度 | 取决于你当时心情 | 0 | **CLAUDE.md 强制三层思考、最低字数** |
| 数据归属 | 平台 | OpenAI / Anthropic | **本地 Markdown，归你** |
| 团队协作 | 各自一份 | 各自一份 | **可自动同步飞书（知识库 wiki 或云文档，二选一）** |

它**不是** Obsidian 替代品。如果你已经是 Obsidian 重度用户，这个项目生成的目录是 100% 兼容 Obsidian 的——你完全可以把 `./` 直接当 Obsidian 仓库打开，享受图谱、反向链接、搜索的全部能力，同时让 Claude 替你持续写新笔记。

---

## 快速开始（5 分钟）

### 前置条件

- 已安装并登录 [Claude Code](https://claude.com/claude-code)
- Node.js ≥ 18（仅当你想用一键安装或飞书同步时需要）
- macOS / Linux / Windows 任一系统皆可
- （可选）`lark-cli` — 仅当你想同步到飞书知识库；一键安装路径会引导你装好

### 一键安装（推荐 — 通过 vercel-labs/skills 安装到 Claude Code / OpenClaw / Hermes 等 54 个 agent）

本项目是一个 **Claude Code skill pack**（1 个 orchestrator + 3 个执行 skill），通过 [`vercel-labs/skills`](https://github.com/vercel-labs/skills) 开放安装器分发。该 CLI 支持 **54 个 agent harness**（Claude Code / OpenClaw / Hermes-Agent / Cursor / Codex / OpenCode / Windsurf …），只需 `.claude/skills/*/SKILL.md` 结构即可被发现 — 本项目天然兼容。

**前提：** 本仓库已推到 public GitHub（`Carlos-Zen/asknow`）。`npx skills` 通过 `<owner>/<repo>` 简写从 GitHub 拉取。如果你 fork 后想从自己的 fork 安装，把命令里的 `Carlos-Zen` 换成你的 GitHub 用户名即可。

**安装命令（按 agent 选）：**

```bash
# Claude Code 项目级（推荐 — 写到当前目录 .claude/skills/）
npx skills add Carlos-Zen/asknow -p

# Claude Code 全局（写到 ~/.claude/skills/）
npx skills add Carlos-Zen/asknow -g

# 同时安装到多个 agent harness（auto-detect 也行，下面是显式声明）
npx skills add Carlos-Zen/asknow -a claude-code -a openclaw -a hermes-agent

# 只装单个 skill（按需）
npx skills add Carlos-Zen/asknow --skill asknow --skill knowledge-write

# 先看清单不装
npx skills add Carlos-Zen/asknow --list
```

**`npx skills` 做什么：** 从你的 GitHub 仓库拉 `.claude/skills/*/SKILL.md`，复制到目标 agent 的 skill 目录。`-p` 写 `./<agent>/skills/`、`-g` 写 `~/<agent>/skills/`、`-a <agent>` 显式声明目标 agent。

**`npx skills` 不做什么：** 不会跑 `scripts/bootstrap.sh`、不会绑 lark-cli、不会修改 CLAUDE.md。Bootstrap 由下面两条路径中**任一**完成即可：

1. **自动（推荐，零摩擦）：** 装完直接打开 Claude Code 在目标项目里随便问个问题 → `asknow` skill 激活 → 自动判断 `wiki/` 骨架是否存在，缺则在对话里向你确认后创建占位（5 个元文件 + 7 个目录）。不需要任何命令。
2. **手动：** 拉脚本跑一次（适合预先初始化）：
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Carlos-Zen/asknow/main/scripts/bootstrap.sh | bash
   ```

**飞书同步初始化** 不依赖任何安装器 — 始终在你第一次说"同步到飞书"时由 `feishu-sync` skill 的对话向导启动（询问 wiki/docs → 解析飞书链接 → 校验权限 → 写入 `FEISHU_MAP.md`）。详见 [`.claude/skills/feishu-sync/SKILL.md`](.claude/skills/feishu-sync/SKILL.md) "首次使用"剧本。

**始终在线模式（可选）：** 想让 Claude 每次对话都自动走 4 步流程（含自动同步）？把 [`skills.json`](skills.json) 顶部 `claude-md-snippet` 字段（约 5 行 Markdown）粘到目标项目 `CLAUDE.md` 顶部即可。详细 skill pack 清单与 harness 适配字段也见仓库根 [`skills.json`](skills.json)。

### 手动三步上手（不用 harness 时）

**第一步：克隆或复制目录**

```bash
git clone <this-repo> ~/think/teach
cd ~/think/teach
bash scripts/bootstrap.sh           # 创建 wiki 骨架（幂等，已有则跳过）
```

或者把 `CLAUDE.md` 和 `.claude/` 目录复制到任何你想存放知识库的目录。

**第二步：进入目录启动 Claude Code**

```bash
cd ~/think/teach
claude
```

Claude Code 会自动加载根目录的 `CLAUDE.md`，从此刻起它就进入了"知识库建设者"模式。

**第三步：开始聊**

以一个 AI 创业商业调研的真实场景为例，你问：

> "帮我盘一下 2026 年 AI 应用层创业格局，哪些垂直赛道已经跑出 Harvey、Cursor 这样的赢家？护城河长什么样？"

Claude 会先回答你（引用一手报告与公司公开数据），然后在后台静悄悄地：

1. 判断这是一段值得沉淀的内容 → 是
2. 调用 `knowledge-write` skill
3. 创建 `insights/ai-application-startup-landscape-2026.md`（赛道全景）
4. 创建 `cases/harvey-deep-dive.md`、`cases/cursor-deep-dive.md`（标杆复盘）
5. 创建 `concepts/ai-application-moat-defensibility.md`（护城河概念）
6. 在四个文件之间建立"应用 / 关联 / 对比"关系
7. 更新 `INDEX.md`、`STATUS.md`、`journal/2026-05-09.md`

**关键一步：第二天再来。** 你问："基于我已经调研过的 Harvey 和 Cursor，结合我对应用层格局的理解，帮我设计一个 agentic commerce 的冷启动方案。"——Claude 直接读取这些笔记把它们当作上下文，给出的方案是基于你过往研究的延伸，而不是从零开始的通用建议。这就是 [`../ac`](../ac) 那个 AI 创业调研库正在发生的事。

---

## 内置指令

在对话里随时可以用（slash 指令）：

| 指令 | 作用 |
|------|------|
| `/norecord` | 本次回答不写入知识库 |
| `/reclassify <目录>` | 强制把当前内容归入指定目录（如 `/reclassify decisions`） |
| `/retag <标签>` | 手动指定标签 |
| `/update <文件>` | 强制更新指定已有文件而不新建 |
| `/important` | 把本次内容标记为高优先级 |
| `/nosync` | 本次跳过自动同步飞书（下次回合恢复） |
| `/syncoff` | 关闭自动同步开关（持久写入 FEISHU_MAP.md） |
| `/syncon` | 开启自动同步开关 |
| `/synctarget <URL\|list>` | 切换飞书同步目标（贴飞书空间 / 文件夹链接自动解析；回 `list` 列出可选） |
| `/syncnow` | 立即触发一次完整同步 |

**不记 slash 也行 — 自然语言也识别：**

> "这次先别同步"、"关闭自动同步"、"换个空间同步"、"现在推到飞书"、"帮我维护下知识库"

整理知识库时直接说"**帮我维护下知识库**"——Claude 会调用 `knowledge-maintenance` skill，自动检测死链、重复条目、孤岛文件、标签漂移，并重建索引和关系图，最后给你一份维护报告。

---

## 四个 Skill（1 个编排 + 3 个执行）

为节省每轮对话的 token 占用，skill 不常驻、按需加载。

### 0. `asknow` — 编排器（orchestrator）

**何时触发：** 用户在有知识库结构的项目里发起问答；或显式说"沉淀""整理""知识库"等关键词；或目标项目 `CLAUDE.md` 顶部加了"始终在线"段（每次问答都激活）。
**做什么：** 总控每次交互的 4 步流程（检索 → 回答 → 沉淀 → 收尾自动同步），决定何时委派给下面 3 个执行 skill，识别用户控制指令（`/norecord` / `/nosync` / `/synctarget` 等以及自然语言等价表达）。

> **设计意图：** 本项目以前完全靠根目录 `CLAUDE.md` 描述编排逻辑；现在编排逻辑也下沉到 `asknow` skill 里，**这样把整个项目当 skill pack 分发到 OpenClaw / Hermes / 其他 Claude Code 项目时，目标项目不用复制 CLAUDE.md 也能跑起来**。源项目本仓继续保留 CLAUDE.md 作为"始终在线"激活配置。

### 1. `knowledge-write` — 写入

**何时触发：** 每次交互判断为"值得沉淀"时，由 `asknow` 委派调用。
**做什么：**
- 按内容类型分类（六大目录之一）
- 检查是否已有相似文件（避免重复）
- 套用模板写入 / 更新
- 维护双向链接（`related` 字段）
- 写 journal、更新 STATUS.md

**强约束：** CLAUDE.md / asknow 中规定了**深度与篇幅基线**——`concepts` 类笔记 800–2000 字、`decisions` 必须包含 trade-off 表格、`howto` 每步必须解释原理、`cases` 必须含"现象 / 过程 / 根因 / 修复 / 启示"五段。Claude 写不够这个深度时，会优先选择**追加进已有文件**而非新建一篇浅薄笔记。这从根本上避免了知识库变成"流水账合集"。

### 2. `knowledge-maintenance` — 维护

**何时触发：**
- 用户主动要求（"整理知识库"）
- `STATUS.md` 显示文件数 ≥ 20 且距上次完整维护 > 30 天（`asknow` 自动判断）

**做什么：**
- 全库扫描所有 md 文件
- 检测：死链、重复内容、标签错用、孤岛文件、命名不一致
- 自动修复 / 给出修复建议
- 重建 `INDEX.md` 和 `GRAPH.md`
- 输出维护报告

### 3. `feishu-sync` — 推送到飞书（可选，支持 wiki + 云文档双载体）

**何时触发：**
- 用户说"同步到飞书""推送到 wiki""推送到飞书文档" / `/syncnow` → 完整同步
- 用户说"切换同步目标" / `/synctarget` → 重新初始化
- **自动触发：** 每次对话有 md 更新且 `FEISHU_MAP.md` 顶部 `auto-sync-on-end: true`（默认）→ 收尾时增量推送（由 `asknow` 自动委派）

**两种同步载体（首次初始化时选）：**

| 类型 | 目标 | 适合 |
|------|-----|-----|
| `wiki` | 飞书知识库 — 按分类目录建嵌套节点 | 团队共享、分类深、需层级 |
| `docs` | 飞书云空间 folder — docx 富文本或 markdown 文件列表 | 个人速记、单篇分享、扁平结构 |

**首次初始化做什么（一次性）：**

1. 问你想用 wiki 还是 docs
2. 让你贴一个飞书链接（`/wiki/space/<id>` / `/wiki/<node>` / `/drive/folder/<token>` 都能解析）或回 `list` 列出可选
3. 校验权限，把目标写入 `FEISHU_MAP.md` 顶部 frontmatter
4. 之后所有同步默认走这里，对话里说"切换同步目标"可随时改

**自动同步做什么（每个回合，无需手动触发）：**

- 读 `FEISHU_MAP.md` 提取本回合修改 / 新建的 md 文件清单
- 去 frontmatter、替换 `[[wiki-link]]` 为飞书链接
- 不存在则按 target.type 创建（wiki 节点或 docx / .md 文件），已存在则覆盖更新
- 同步报告作为最终回复的尾部附给你（含飞书链接）

适合**团队协作 / 个人备份场景**：每个人本地有完整知识库，飞书侧是公开镜像；自动同步意味着不会忘记推送、不需要专门触发。

---

## 工作流：一次完整的对话发生了什么

以一次 AI 创业战略对话为例：

```
你：    "agentic commerce 短期起不来，
         我们要不要先做 Shopify 插件 / 中转站 / 比价 bot 来积累流量和数据？"
  │
  ├── ① 检索：Claude 扫描 ./decisions/ ./insights/ ./idea.md 等相关文件
  │         → 命中 idea.md（"流量、数据、token"框架），先读后答
  │
  ├── ② 回答：Claude 回答你（结合你过往沉淀的赛道判断 + 当前一手数据）
  │
  ├── ③ 沉淀（后台）：
  │     ├── 判断：值得写入 ✓
  │     ├── 调用 knowledge-write skill
  │     ├── 更新 decisions/ai-startup-ideas-2026-agentic-commerce-aligned.md
  │     │  （在已有候选方向后追加四条新方案的 trade-off 对比）
  │     ├── 创建 cases/ai-wrapper-graveyard.md（反例库，警示同类失败模式）
  │     ├── 在文件间建立 "对比 / 警示" 关系
  │     ├── 在 idea.md 中追加 [[ai-startup-ideas-2026]] 反向链接
  │     ├── 写 journal/2026-05-09.md
  │     └── 更新 STATUS.md（计数器 +2）
  │
  └── ④ 收尾自动同步飞书（默认开，无更新或开关关闭则跳过）：
        ├── 读 FEISHU_MAP.md 顶部 frontmatter → 目标 = wiki / 研发部门空间
        ├── 增量推送本回合改过的 2 个 md 文件
        ├── decisions/...（更新）→ https://xxx.feishu.cn/wiki/...
        ├── cases/ai-wrapper-graveyard.md（新建）→ https://xxx.feishu.cn/wiki/...
        └── 把上述链接附在最终回复末尾告诉你
```

**接下来真正有意思的事发生在下一轮对话：** 你问"我们的中转站方案 vs Cursor 早期定价策略哪个更适合冷启动"——Claude 直接读这些笔记 + `cases/cursor-deep-dive.md`，回答里有真实数据、有你自己的战略上下文，**它已经"记得"你的项目和你的判断**；而飞书侧的团队成员也能在 wiki 看到最新版本。

---

## 知识库的真正价值：让 AI 给你更好的创意和方案

> 笔记本身没价值。让 AI **用你的笔记**给你更好的下一步建议，才是这套系统的真正目的。

普通 ChatGPT 对话每次都从零开始——它不知道你已经研究过什么，也不知道你的项目背景、你的判断、你之前否决过什么方案。所以它给的建议总是泛泛而谈、套话连篇。

Knowledge Base Builder 把你的知识库变成了 Claude 的"长期工作记忆"。下一次你问它："基于我已经调研过的 X、Y、Z，给我一个 ABC 方案"——它会真的去读那些文件，把你的研究、你的判断、你的项目阶段全部纳入考量，然后给出**只对你的项目成立**的建议。

### 三种典型的创意/方案产出场景

**1. 跨笔记综合 — 从你的研究里提炼新方案**

> "结合我已沉淀的 Harvey、Cursor、Manus 三家标杆，加上 idea.md 里'流量/数据/token'的框架，
>  帮我设计一个 agentic commerce 的产品冷启动路径，要避开 cases/ai-wrapper-graveyard.md 里那几类陷阱。"

Claude 会真的去读这五份文件，给出一份**贴合你项目处境**的方案——而不是网上随便搜来的通用建议。

**2. 决策辅助 — 把已有判断推进到下一步动作**

> "我们已经决定不死磕 agentic commerce（见 idea.md）。
>  对照 decisions/ai-startup-ideas-2026 里的四个候选方向，
>  哪个是未来 3 个月投入产出比最高的？给我一份执行清单。"

Claude 接住你已有的战略判断，往下推一层到具体动作。

**3. 反思与盲点扫描 — 让 AI 当你的镜子**

> "把我过去一个月在 cases/ 下沉淀的所有失败案例做一遍模式抽取——
>  我自己有没有可能正在重复某种典型失败？"

Claude 用你自己的反例库审视你自己——这是单纯聊天永远做不到的。

### 一个比喻

把知识库想成 AI 的"工作记忆"：

| | 没有它 | 有了它 |
|---|---|---|
| 每次对话开场 | 和一个失忆症患者从头介绍背景 | AI 已"读完了你的过往研究" |
| AI 的建议 | 通用、套话、网上随便搜得到 | 贴合你的项目、判断、阶段 |
| 你的角色 | 反复给 AI 喂背景 | 直接进入高阶讨论与决策 |

沉淀只是手段，**让每一次 AI 对话都站在你过往思考的肩膀上**才是目的。

---

## 适合谁用

**强烈推荐：**
- 技术学习者：长期追一个领域（分布式、AI、数据库、密码学……）
- 内容创作者：博客、newsletter、研究报告作者，需要把日常思考沉淀
- 顾问 / 研究员：每天处理大量信息，需要可复用的 brief
- 团队 tech lead：把团队问答沉成可推到飞书的内部 wiki
- 在校生 / 自学者：把刷题、读论文、面试准备的成果累积起来

**可能不太合适：**
- 只想用 AI 写代码、不打算积累知识 → 用普通 Claude Code 即可
- 内容高度敏感、绝不能本地落盘 → 关闭沉淀
- 笔记量极小（一周 < 5 条）→ 任何笔记软件都够，无需自动化

---

## 进阶用法

### 与 Obsidian 共生

把 `./` 当 Obsidian Vault 打开。Claude 写、Obsidian 读：
- Obsidian 的图谱视图 = `GRAPH.md` 的可视化
- Obsidian 的反向链接 = Claude 维护的 `related:` 字段
- Obsidian 的全文搜索 + Claude 的语义检索 = 双引擎

### 与 Git 共生

把整个目录初始化为 Git 仓库：

```bash
cd ~/think/teach
git init && git add . && git commit -m "init"
```

每天结束跑一次：

```bash
git add . && git commit -m "$(date +%F)"
```

你就拥有了一份带完整变更历史的"个人维基百科"。

### 与团队飞书共生

**首次配置（一次性，对话里说"同步到飞书"即触发）：**

> Claude："要同步到飞书的 **wiki**（知识库，按目录嵌套）还是 **docs**（云空间 folder，扁平列表）？"
>
> 你："wiki"
>
> Claude："请贴一个飞书链接（空间或节点）。例：`https://example.feishu.cn/wiki/space/...`，或回 `list` 让我列。"
>
> 你：贴上空间链接
>
> Claude：解析 → 校验权限 → 写入 `FEISHU_MAP.md` 顶部 frontmatter → 锁定为今后默认目标

**之后每次对话自动同步**（默认开，可对话切关）：

每个回合若有 md 文件变更，Claude 会在最终回复尾部告诉你新建/更新了哪些飞书文档，附链接。

**随时控制：**

> "关闭自动同步" / "本次跳过同步" / "切换同步目标到 https://xxx.feishu.cn/drive/folder/..." / "把 concepts/ 下所有 importance: high 的文档现在同步一下"

也可以用 slash：`/syncoff`、`/nosync`、`/synctarget <URL>`、`/syncnow`。完整列表见上面"内置指令"。

---

## FAQ

**Q：和 ChatGPT 的 Memory 功能比有什么不同？**
A：ChatGPT Memory 是黑盒、不可读、不可迁移、由平台决定记什么。本项目的"记忆"是你硬盘上的 Markdown 文件，可读、可改、可迁移、可分享、可版本控制。

**Q：Claude 会不会乱写一通把知识库搞乱？**
A：CLAUDE.md 里有明确的分类规则、文件粒度规则、深度基线、查重逻辑。`knowledge-maintenance` skill 会定期清理。最坏情况你也只是多了几个文件，删除即可——所有内容都是纯 Markdown。

**Q：会不会一聊天就疯狂建文件？**
A：不会。CLAUDE.md 明确说**闲聊、纯指令、琐碎内容不写入**；多轮对话默认追加进同一文件而非新建；写不够深度基线时优先合并进已有文件。

**Q：可以用别的 AI 吗（GPT、Gemini）？**
A：技术上 CLAUDE.md 的规则可以迁移给其他 AI，但 Skill 系统是 Claude Code 特有的。其他 AI 上效果会打折。

**Q：笔记越写越多怎么办？**
A：journal 90 天后自动季度归档；`knowledge-maintenance` 会合并重复内容；`STATUS.md` 跟踪全局状态。可持续运行。

**Q：能在多台机器同步吗？**
A：用 Git / iCloud / Dropbox / Syncthing 任一方案同步整个目录即可。

---

## 一句结语

> AI 不是替你思考的工具，是**放大你思考**的工具。
>
> 你每天都在和 AI 对话，但每次对话结束后，AI 一无所获、你也一无所剩——这是这个时代最隐秘的浪费。
>
> Knowledge Base Builder 让每一次提问既沉下一砖一瓦，又让下一次对话踩在已经垒起的墙上。
> 三个月后，你拥有的不只是一座知识库，而是一个**真的懂你项目的 AI 协作者**。

**现在就 `cd` 进项目目录，打开 Claude，问出今天的第一个问题。**
