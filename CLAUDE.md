# Knowledge Base Builder

AI 在问答中自动将知识沉淀到 `./` 下的结构化 Markdown 文件中，逐步构建可浏览、可关联、可同步飞书的知识库。

> 本文件是源仓的「始终在线」激活配置；所有详细规则（分类、深度、指令、工作流）都在 [`asknow` skill](.claude/skills/asknow/SKILL.md) 与 3 个执行 skill 里。**目标项目无需复制本文件** — 装完 skill 后由 description 关键词自动激活；想要"每次对话都走流程"则把 [`skills.json`](skills.json) 的 `claude-md-snippet` 字段贴进目标项目的 `CLAUDE.md`。

## 始终在线（每次问答都走 4 步）

**任何问答交互后，始终激活 `asknow` skill 走 4 步流程：**

1. **检索** — 扫已有笔记 + `INDEX.md`，命中则读"核心要点"辅助回答
2. **回答** — 第一优先级（高于沉淀）；权威来源 + 标注引用；数据 / 规格必须给具体数字
3. **沉淀** — 调用 `knowledge-write`；达不到深度基线 → 优先追加进已有文件而非新建浅层笔记
4. **收尾** — 若本回合有 md 更新 + `FEISHU_MAP.md` `options.auto-sync-on-end: true`（默认），调用 `feishu-sync` 把变更增量推到飞书，把同步报告附在最终回复末尾

详细规则见各 SKILL.md：
- 分类规则、Bootstrap、延迟维护：[`asknow/SKILL.md`](.claude/skills/asknow/SKILL.md)
- 文件模板、深度与篇幅基线、引用来源规则：[`knowledge-write/SKILL.md`](.claude/skills/knowledge-write/SKILL.md)
- 全库维护、INDEX/GRAPH 重建：[`knowledge-maintenance/SKILL.md`](.claude/skills/knowledge-maintenance/SKILL.md)
- 飞书同步（wiki / docs 双载体、自动同步开关、URL 解析）：[`feishu-sync/SKILL.md`](.claude/skills/feishu-sync/SKILL.md)
- 用户控制指令（全部自然语言、无 slash 前缀）：[`asknow/SKILL.md`](.claude/skills/asknow/SKILL.md) §"对话指令" + [`feishu-sync/SKILL.md`](.claude/skills/feishu-sync/SKILL.md) §"自动同步开关"

## 知识库骨架

项目根 `./` 下：
- 5 个元文件：`INDEX.md` / `GRAPH.md` / `TAGS.md` / `STATUS.md` / `FEISHU_MAP.md`
- 7 个目录：`concepts/` / `howto/` / `insights/` / `references/` / `decisions/` / `cases/` / `journal/`（含 `journal/archive/`）

由 `scripts/bootstrap.sh` 创建（幂等）；`asknow` skill 首次激活时检测到缺失会询问用户后自动创建。完整清单见 [`skills.json`](skills.json) `bootstrap.creates`。

## 分发与安装

一键安装（54 个 agent harness — Claude Code / OpenClaw / Hermes-Agent / Cursor / Codex / OpenCode / Windsurf 等）：

```bash
npx skills add Carlos-Zen/asknow -p                                          # Claude Code 项目级
npx skills add Carlos-Zen/asknow -g                                          # 全局
npx skills add Carlos-Zen/asknow -a claude-code -a openclaw -a hermes-agent  # 多 agent
npx skills add Carlos-Zen/asknow --skill asknow                              # 按需挑 skill
```

- `npx skills` 只拷 SKILL.md，不跑 bootstrap、不改目标项目 CLAUDE.md。
- 完全本地手动：克隆仓库 → `bash scripts/bootstrap.sh` → 把 `.claude/skills/` 复制到目标项目。
- 完整 manifest 与 harness 适配字段：[`skills.json`](skills.json)。
