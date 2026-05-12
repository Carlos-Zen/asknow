---
name: asknow
description: "知识库沉淀编排器。ALWAYS invoke this skill when the user (a) 在已有知识目录（concepts/howto/insights/references/decisions/cases/journal 任一存在）的项目里发起问答；(b) 用以下任一自然语言短语表达意图：沉淀、记下来、记到知识库、整理这段对话、补到笔记、second brain、复盘、调研、选型对比、维护知识库、整理 wiki、清理重复笔记、归档日志、同步到飞书、推到飞书、推到 wiki、关闭自动同步、暂停自动同步、开启自动同步、恢复自动同步、切换同步目标、换个空间、换个文件夹、本次不要记、跳过沉淀、本次不要同步、跳过同步、归到 <目录>、改为 <标签>、更新 <文件>、标重要、高优先级。Do not answer these prompts directly — defer to this orchestrator first to run the 检索 → 回答 → 沉淀 → 收尾 four-step flow."
metadata:
  delegates:
    - knowledge-write
    - knowledge-maintenance
    - feishu-sync
  bootstrap: "scripts/bootstrap.sh"
  data-root: "./"
---

# Asknow — 知识沉淀编排器

把每次 AI 问答变成可检索、可关联、可溯源的 Markdown 笔记。本 skill 是编排层，不直接写文件；写入、维护、同步分别委派给 `knowledge-write`、`knowledge-maintenance`、`feishu-sync`。

> 默认按 description 语义匹配激活。若希望"每次对话都走流程"，把 [`skills.json`](../../../skills.json) 的 `claude-md-snippet` 字段贴进目标项目 `CLAUDE.md` 即可。

## 何时激活

满足任一条件：
- 用户在已有 `INDEX.md` / `STATUS.md` / 任一知识目录的项目里发起问答
- 用户用自然语言表达"沉淀 / 整理 / 维护 / 同步"等意图（见 description）
- 用户用本 skill"对话指令"段中的任一控制短语

不激活：闲聊、纯执行性指令、当前代码库的具体修改任务。

## Bootstrap（首次激活）

检查项目根：

```bash
ls STATUS.md INDEX.md concepts howto insights references decisions cases journal 2>/dev/null
```

任一缺失 → 询问用户后跑 `scripts/bootstrap.sh`（创建的文件 / 目录清单见 [`skills.json`](../../../skills.json) `bootstrap.creates`）。

## 每次交互的四步工作流

### 1. 检索

按提问关键词扫描相关目录文件名 + `INDEX.md`。命中则读对应文件"核心要点"作为回答上下文。冷启动跳过。

### 2. 回答

**第一优先级，回答质量永远高于知识沉淀。** 要求：
- 优先引用一手来源（官方文档、学术论文、行业报告、原始数据）
- 数据 / 市场规模 / 技术规格必须标注来源与时间
- 避免"较高""较多""一般认为"等模糊表述

### 3. 沉淀（按需委派 knowledge-write）

判断是否值得写入。**值得**：用户陈述事实/决策/经验/观点；AI 回答含可复用概念/流程/对比/案例；研究/复盘/选型/调研类对话。**不写入**：闲聊、纯指令、琐碎、用户要求跳过沉淀。

**编排判断（每篇笔记必须显式回答以下四类问题中至少三类）**：
1. **是什么** — 定义、边界、与相邻概念的差异
2. **为什么** — 动机、底层原理、设计权衡
3. **怎么用 / 怎么选** — 典型场景、前置条件、反模式、trade-off
4. **延伸** — 局限性、争议、演进趋势、与本库其他主题的关联

撑不起以上要求 → **追加进已有文件，而不是新建浅层笔记**。具体的篇幅基线、信息密度、禁止模式见 [`knowledge-write`](../knowledge-write/SKILL.md) §"深度与篇幅要求"。

调用 `knowledge-write` 时传：目录归属、新建 vs 追加、关联到哪些已有笔记。

### 4. 收尾 — 自动同步飞书

沉淀完成后、最终回复**之前**判断是否触发同步：本回合若有 md 更新 → 调用 [`feishu-sync`](../feishu-sync/SKILL.md)（具体的"读 FEISHU_MAP / 检查 auto-sync 开关 / 用户跳过判断"五步流程由 feishu-sync 自己负责，详见其 §"Orchestrator 集成约定"）。同步报告附在当前回复末尾，**不单独占一轮**。

## 分类规则

| 模式 | 目录 | 触发信号 |
|------|------|---------|
| 定义、术语、模型 | `concepts/` | "什么是" |
| 步骤、配置、流程 | `howto/` | "怎么做""如何" |
| 原理、洞察、因果 | `insights/` | "为什么" |
| 参数表、清单 | `references/` | 表格/列表型 |
| 对比、选型 | `decisions/` | "还是""怎么选" |
| 案例、排障、复盘 | `cases/` | "遇到了""复盘" |

用户陈述同样沉淀:决策 → `decisions/`,经验 → `cases/`,事实补充 → 更新已有或新建 `concepts/`,观点 → `insights/`。

## 对话指令（自然语言）

识别以下自然语言短语并改变行为。所有指令都通过对话表达,**不使用 slash 前缀**。

### 写入控制

| 用户说 | 行为 | 持久化 |
|--------|-----|------|
| "这次不要记" / "跳过沉淀" / "别记到知识库" | 本回合不调用 knowledge-write | 否 |
| "归到 <目录>" / "放到 decisions" / "分类成案例" | 强制目录归属 | 否 |
| "用 <X> 作标签" / "打标签为 X" | 手动指定 tags | 否 |
| "更新 <文件>" / "改进已有的 Y 文件" | 强制更新而非新建 | 否 |
| "标重要" / "高优先级" / "important" | frontmatter `importance: high` | 是 |

### 同步控制（转发给 feishu-sync）

| 用户说 | 行为 |
|--------|-----|
| "本次不要同步" / "跳过同步" | 本回合 skip |
| "关闭自动同步" / "暂停自动同步" | 持久化关闭开关 |
| "开启自动同步" / "恢复自动同步" | 持久化开启开关 |
| "切换同步目标" / "换个空间" / "同步到 <URL>" | 重新初始化同步目标 |
| "现在同步一下" / "推到飞书" / "立即同步" | 立即执行完整同步 |

详细行为（FEISHU_MAP 字段写入、URL 解析等）见 [`feishu-sync`](../feishu-sync/SKILL.md)。

## 子 skill 委派

| 触发 | 调用 |
|------|------|
| 沉淀判定为是 | `knowledge-write` |
| "整理 / 维护知识库""清理重复""归档日志" | `knowledge-maintenance` |
| `STATUS.md` `total_files >= 20` 且距 `last_full_maintenance` > 30 天 | `knowledge-maintenance`(先告知用户) |
| 同步类自然语言短语 + 收尾时本回合有 md 更新 | `feishu-sync` |
| 首次同步前 / "切换同步目标" | `feishu-sync` 步骤 5(首次初始化) |
| "关闭 / 开启自动同步" | 直接改写 `FEISHU_MAP.md` frontmatter `options.auto-sync-on-end`,不调子 skill |

## 延迟维护触发

读 `STATUS.md`：

| 条件 | 操作 |
|------|------|
| `files_since_last_index >= 5` | 顺手重建 `INDEX.md` |
| `relations_since_last_graph >= 5` | 顺手重建 `GRAPH.md` |
| `total_files >= 20` 且距 `last_full_maintenance` > 30 天 | 调用 `knowledge-maintenance`（重量，先告知用户） |
| 距 `last_journal_archive` > 90 天 | 归档 `journal/` 到 `journal/archive/<季度>/` |

## 关联文件

- 项目说明：[`README.zh-CN.md`](../../../README.zh-CN.md) · [`README.md`](../../../README.md)
- 子 skill：[`knowledge-write`](../knowledge-write/SKILL.md) · [`knowledge-maintenance`](../knowledge-maintenance/SKILL.md) · [`feishu-sync`](../feishu-sync/SKILL.md)
- Bootstrap：[`scripts/bootstrap.sh`](../../../scripts/bootstrap.sh)
- 分发清单：[`skills.json`](../../../skills.json)
