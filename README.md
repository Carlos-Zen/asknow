# AskNow — Turn every Q&A with Claude into a knowledge asset

> **English** · [简体中文](./README.zh-CN.md)

> Just chat with Claude. It quietly turns every conversation into searchable, linked, source-traceable Markdown notes.
> Three months in, you'll have your own **second brain** — and Claude will actually *read it* the next time you ask.

---

## Why this exists

Everyone has lived this:

- You asked a great technical question last week. **This week you can't recall the details.**
- The same question gets asked across three different chats — **each time from scratch.**
- You're researching a topic / reading a book / tracking a domain, and your notes scatter across Notion, Apple Notes, browser bookmarks. Nothing connects.
- AI gives a great answer, but **the answer only exists inside that one window.** Close the tab and it's gone.

**AskNow solves two things:**

1. **Capture** — turn AI output from a *one-shot consumable* into a *compounding asset*.
2. **Reuse (the bigger one)** — make the AI *actually read your past research* before it answers the next question, so it gives you advice that fits **your** project, not generic boilerplate.

It is not a new note-taking app and not a chat skin. It's a **set of working rules injected into Claude Code**: Claude follows them to capture after every answer, and to consult your notes as long-term context on every future turn. Your past benchmarks, the ideas you killed, the calls you made — all retrievable. The knowledge base lives on your disk, opens in any editor, and can sync to Lark/Feishu (Wiki or Docs) for teams.

---

## One-line summary

**AskNow = Claude Code + a `CLAUDE.md` rulebook + 1 orchestrator skill + 3 executor skills.**

`cd` into the project, run `claude`, chat normally. Claude will:

1. **Search** — scan your existing notes before answering; pull in matching entries.
2. **Answer** — quality first, with cited sources where it matters.
3. **Capture** — decide what's worth keeping, then write it as structured Markdown under the right category, maintaining indexes, tags, and a relationship graph.
4. **Tail step — auto-sync to Feishu** (default on) — if this turn produced new or updated notes, incrementally push them to your chosen Feishu target (Wiki space or Docs folder) and append the links to the final reply.

The flow doesn't interrupt the conversation. The base grows on its own — and the Feishu mirror grows with it.

---

## What it looks like

The base lives at the project root, organized **by the nature of the knowledge**, not by date:

```
./
├── INDEX.md              # Global index (categories + tags)
├── GRAPH.md              # Mermaid relationship graph
├── TAGS.md               # Controlled vocabulary
├── STATUS.md             # Cross-session counters & queues
├── FEISHU_MAP.md         # Feishu sync map (only when feishu-sync is enabled)
├── concepts/             # WHAT — concepts, definitions, models
├── howto/                # HOW — flows, steps, guides
├── insights/             # WHY — principles, takes, trends
├── references/           # LOOKUP — params, checklists, tables
├── decisions/            # WHICH — comparisons, choices, calls
├── cases/                # CASES — postmortems, debugging, experiments
└── journal/              # Daily Q&A log
    └── archive/          # Quarterly archive
```

Every note is a self-contained Markdown file with YAML frontmatter:

```markdown
---
title: Harvey Deep Dive — How a Vertical Legal AI Builds a Moat
category: cases
tags: [ai-startup, vertical, moat, legal-tech]
related:
  - path: concepts/ai-application-moat-defensibility.md
    type: applies
  - path: insights/ai-application-startup-landscape-2026.md
    type: relates-to
created: 2026-05-08
updated: 2026-05-08
importance: high
---

# Harvey Deep Dive

## TL;DR
3–5 sentence summary ...

## Body
Background → product evolution → customers & pricing → moat analysis → takeaways ...
```

Notes link via `[[wiki-link]]`s, which auto-feed `GRAPH.md` to form a graph that's uniquely yours.

---

## How it differs from the alternatives

| Dimension | Notion / Obsidian | Plain ChatGPT | **AskNow** |
|---|---|---|---|
| Content production | You type everything | AI writes well, nothing persists | **AI captures while answering** |
| Structure | You design folders | None | **Forced taxonomy + templates** |
| Linking | Manual | None | **AI maintains bidirectional links** |
| Capture depth | Depends on your mood | 0 | **`CLAUDE.md` enforces 3-layer thinking + word-count floors** |
| Data ownership | Vendor | OpenAI / Anthropic | **Local Markdown — yours** |
| Team sharing | One vault each | One chat each | **Auto-sync to Lark/Feishu Wiki or Docs** |

It is **not** an Obsidian replacement. If you already use Obsidian, point it at this directory — Obsidian's graph, backlinks, and search will all work. AskNow just keeps writing new notes for you.

---

## Quick start

### Prerequisites

- [Claude Code](https://claude.com/claude-code) installed and signed in
- Node.js ≥ 18 (only if you use the one-line install or Feishu sync)
- macOS / Linux / Windows — any
- Optional: `lark-cli` — only if you want Feishu sync; the first-time wizard installs it for you

### One-line install (recommended — works for 54 agent harnesses)

This project is a **Claude Code skill pack** (1 orchestrator + 3 executors), distributed via the [`vercel-labs/skills`](https://github.com/vercel-labs/skills) installer. That CLI supports **54 agent harnesses** (Claude Code / OpenClaw / Hermes-Agent / Cursor / Codex / OpenCode / Windsurf …). Any directory with `.claude/skills/*/SKILL.md` works — this repo qualifies natively.

**Prerequisite:** the repo is already pushed to public GitHub (`Carlos-Zen/asknow`). `npx skills` pulls from there via the `<owner>/<repo>` shorthand. If you fork and want to install from your fork, just swap `Carlos-Zen` for your GitHub username.

```bash
# Claude Code, project-scope (writes to ./.claude/skills/)
npx skills add Carlos-Zen/asknow -p

# Claude Code, global (writes to ~/.claude/skills/)
npx skills add Carlos-Zen/asknow -g

# Multiple agent harnesses at once (auto-detect also works)
npx skills add Carlos-Zen/asknow -a claude-code -a openclaw -a hermes-agent

# Pick specific skills
npx skills add Carlos-Zen/asknow --skill asknow --skill knowledge-write

# Inspect without installing
npx skills add Carlos-Zen/asknow --list
```

**What `npx skills` does:** pulls `.claude/skills/*/SKILL.md` from the GitHub repo and drops them under the target agent's skill directory. `-p` → `./<agent>/skills/`, `-g` → `~/<agent>/skills/`, `-a <agent>` declares the target agent.

**What `npx skills` does NOT do:** run `scripts/bootstrap.sh`, bind `lark-cli`, or edit `CLAUDE.md`. Bootstrap happens via either of:

1. **Automatic (zero-friction):** Just open Claude Code in the target project and ask anything → the `asknow` skill activates → it checks if the `wiki/` skeleton exists and offers to create it inline (5 meta files + 7 category dirs). No command needed.
2. **Manual:** Run the bootstrap script once:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Carlos-Zen/asknow/main/scripts/bootstrap.sh | bash
   ```

**Feishu sync init** does not require an installer — it always kicks off the first time you say *"sync to Feishu"*, via the `feishu-sync` skill's interactive wizard (pick wiki vs docs → paste a Feishu URL → permission check → write `FEISHU_MAP.md`). Full script: [`.claude/skills/feishu-sync/SKILL.md`](.claude/skills/feishu-sync/SKILL.md).

**Always-on mode (optional):** want Claude to auto-run the 4-step flow on *every* conversation (including auto-sync)? Paste the `claude-md-snippet` field from [`skills.json`](skills.json) (~5 lines of Markdown) into your target project's `CLAUDE.md`. Full skill-pack manifest with harness adapters: [`skills.json`](skills.json).

### Manual three-step setup (without an installer)

**1. Clone**

```bash
git clone https://github.com/Carlos-Zen/asknow.git ~/think/asknow
cd ~/think/asknow
bash scripts/bootstrap.sh           # creates the wiki skeleton, idempotent
```

Or copy `CLAUDE.md` and `.claude/` into any directory you want as a knowledge base.

**2. Launch Claude Code**

```bash
cd ~/think/asknow
claude
```

Claude Code auto-loads the root `CLAUDE.md` — from this moment it's in *Knowledge Base Builder* mode.

**3. Just talk to it**

Example — researching the AI startup landscape:

> "Walk me through the 2026 AI application-layer landscape. Which verticals already produced winners like Harvey or Cursor? What do their moats look like?"

Claude answers (citing reports and public data), then quietly:

1. Decides this is worth capturing → yes
2. Calls the `knowledge-write` skill
3. Creates `insights/ai-application-startup-landscape-2026.md` (the landscape)
4. Creates `cases/harvey-deep-dive.md`, `cases/cursor-deep-dive.md` (benchmark teardowns)
5. Creates `concepts/ai-application-moat-defensibility.md` (the concept)
6. Wires *applies / relates / contrasts* edges between them
7. Updates `INDEX.md`, `STATUS.md`, `journal/2026-05-09.md`
8. **(If auto-sync is on)** Pushes the new files to your Feishu target and appends the resulting links to its reply

**The point comes the next day.** You ask: *"Based on Harvey and Cursor that I already studied, plus my read on the application layer, design me a cold-start plan for an agentic-commerce product."* — Claude pulls those notes as context. The plan extends your prior research instead of starting from zero. That's the whole point.

---

## In-conversation commands

| Command | Effect |
|---|---|
| `/norecord` | Don't capture this turn |
| `/reclassify <dir>` | Force this content into a category (e.g. `/reclassify decisions`) |
| `/retag <tag>` | Set the tag manually |
| `/update <file>` | Append to a specific file instead of creating a new one |
| `/important` | Mark as high importance |
| `/nosync` | Skip Feishu auto-sync for this turn only |
| `/syncoff` | Disable auto-sync (persisted to `FEISHU_MAP.md`) |
| `/syncon` | Re-enable auto-sync |
| `/synctarget <URL\|list>` | Switch Feishu target (paste a Feishu space/folder URL, or reply `list`) |
| `/syncnow` | Trigger a full sync now |

**Slash-free equivalents (natural language works too):**

> "skip the sync this time" · "turn off auto-sync" · "switch the sync target" · "push to Feishu now" · "tidy up the knowledge base"

When you want a tidy-up, just say *"maintain the knowledge base"* — Claude runs `knowledge-maintenance`, detects dead links, duplicates, orphans, tag drift, rebuilds indexes & graph, and hands you a report.

---

## The four skills (1 orchestrator + 3 executors)

Skills load on demand, not on every turn — keeps token cost low.

### 0. `asknow` — orchestrator

**Triggers:** the user starts a Q&A in a project that already has the knowledge-base structure; or explicitly says "capture", "tidy up", "knowledge base"; or the target project's `CLAUDE.md` carries the always-on snippet (every turn activates it).
**Does:** drives the 4-step flow each turn (search → answer → capture → tail-sync), decides when to delegate to the three executor skills, and parses user-control commands (`/norecord` / `/nosync` / `/synctarget` … plus their natural-language equivalents).

> **Why an orchestrator skill exists:** previously all the orchestration logic lived in the root `CLAUDE.md`. Lifting it into the `asknow` skill means **the whole project can be distributed as a skill pack to OpenClaw / Hermes / any other Claude Code project, without forcing the target to copy `CLAUDE.md`**. The source repo keeps its `CLAUDE.md` as the always-on activation config.

### 1. `knowledge-write` — capture

**Triggers:** every turn where content is judged worth keeping (delegated by `asknow`).
**Does:**
- Classify into one of six folders
- Check for duplicates (avoid sprawl)
- Apply a template, write or update
- Maintain bidirectional `related:` links
- Append to today's journal, bump `STATUS.md`

**Hard constraint:** `CLAUDE.md` enforces a *depth & length floor* — `concepts` notes 800–2000 words, `decisions` must include a trade-off table, `howto` must explain *why* per step, `cases` must hit the five-section pattern (symptom / investigation / root cause / fix / takeaway). When Claude can't reach the depth, it **appends to an existing file rather than creating a thin new one.** That's how the base avoids becoming a stream-of-consciousness graveyard.

### 2. `knowledge-maintenance` — upkeep

**Triggers:**
- You ask ("clean up the knowledge base")
- `STATUS.md` shows ≥ 20 files and last full maintenance > 30 days (auto-detected by `asknow`)

**Does:**
- Full-base scan of all `.md` files
- Detect: dead links, duplicate content, mis-tagged notes, orphan files, naming drift
- Auto-fix where safe / suggest where not
- Rebuild `INDEX.md` and `GRAPH.md`
- Emit a maintenance report

### 3. `feishu-sync` — push to Lark/Feishu (optional, dual-target)

**Triggers:**
- You say *"sync to Feishu"* / *"push to wiki"* / *"push to Feishu docs"* / `/syncnow` → full sync
- You say *"switch sync target"* / `/synctarget` → re-run init
- **Automatic:** any turn that produced `.md` changes and `FEISHU_MAP.md` has `auto-sync-on-end: true` (default) → incremental push (delegated by `asknow`)

**Two sync targets (chosen at first init):**

| Type | Destination | Best for |
|---|---|---|
| `wiki` | Feishu Wiki — nested nodes per category | Team sharing, deep taxonomy, hierarchy |
| `docs` | Feishu Drive folder — docx (rich-text) or `.md` files | Personal jottings, flat single-doc structure |

**First-time init (one-shot):**

1. Asks whether to use `wiki` or `docs`
2. Asks you to paste a Feishu link (`/wiki/space/<id>`, `/wiki/<node>`, or `/drive/folder/<token>` all parse) or reply `list` to get the available options
3. Validates permissions, writes the target into `FEISHU_MAP.md`'s top-frontmatter
4. Every subsequent sync defaults here; say *"switch the sync target"* any time to change

**Per-turn auto-sync (no manual trigger):**

- Reads `FEISHU_MAP.md`, gathers the `.md` files touched this turn
- Strips frontmatter, rewrites `[[wiki-link]]`s as Feishu URLs
- Creates the file if missing (wiki node or docx/.md), overwrites if local is newer
- Appends the resulting Feishu links to the final reply

Good fit for **team collaboration / personal backup**: everyone keeps a full local base, the Feishu side stays as the shared mirror; auto-sync means you never forget to push, and never have to push manually.

---

## Workflow — one full conversation

```
You:    "Agentic commerce won't take off short term.
         Should we ship a Shopify plug-in / proxy / price-comparison bot
         to bank traffic and data first?"
  │
  ├── ① Claude scans ./decisions/, ./insights/, ./idea.md
  │     → hits idea.md (your "traffic / data / token" framing) → reads it
  │
  ├── ② Claude answers (your prior take + current first-party data)
  │
  ├── ③ Background capture:
  │     ├── Worth writing? ✓
  │     ├── Calls knowledge-write
  │     ├── Updates decisions/ai-startup-ideas-2026.md
  │     │  (appends a trade-off table for four new directions)
  │     ├── Creates cases/ai-wrapper-graveyard.md (anti-patterns)
  │     ├── Wires "contrasts / warns" edges
  │     ├── Backlinks idea.md → ai-startup-ideas-2026
  │     ├── Writes journal/2026-05-09.md
  │     └── STATUS.md counter +2
  │
  └── ④ Tail step: auto-sync to Feishu (default on; skipped if nothing changed or auto-sync off):
        ├── Reads FEISHU_MAP.md frontmatter → target = wiki space "R&D"
        ├── Incrementally pushes the 2 changed .md files
        ├── decisions/...     (update) → https://xxx.feishu.cn/wiki/...
        ├── cases/ai-wrapper-graveyard.md (new) → https://xxx.feishu.cn/wiki/...
        └── Appends the links to the final reply
```

**The interesting part is the next turn.** You ask: *"Our proxy plan vs Cursor's early pricing strategy — which fits cold-start better?"* Claude reads those notes plus `cases/cursor-deep-dive.md`, answers with real data and your strategic context. **It already remembers your project and your thinking** — and your teammates see the latest in Feishu.

---

## The real point — better suggestions, not just notes

> Notes by themselves are nearly worthless. The point is to make AI **use your notes** to give you a sharper next move.

A vanilla ChatGPT chat starts from zero every time — it doesn't know what you've researched, what your project's about, what you already ruled out. So the advice is generic.

AskNow turns your knowledge base into Claude's *long-term working memory*. Next time you ask *"based on the X, Y, Z I've already studied, give me an ABC plan"*, it actually reads those files and folds in your research, your judgment, your project stage. The advice comes out **only valid for your project.**

### Three patterns that pay off

**1. Cross-note synthesis — distill new plans from your own research**

> "Combining Harvey, Cursor, and Manus that I've already studied, plus the 'traffic / data / token' framework in `idea.md`, design me a cold-start path for an agentic-commerce product. Avoid the failure modes in `cases/ai-wrapper-graveyard.md`."

Claude actually reads those five files, returns a plan that **fits your specific context** — not a stock template.

**2. Decision support — push prior calls into next actions**

> "We already decided not to die on agentic commerce (see `idea.md`). Of the four directions in `decisions/ai-startup-ideas-2026`, which has the best ROI for the next 3 months? Give me an execution checklist."

Claude picks up where your strategic call left off and pushes one level into action.

**3. Reflection & blind-spot scan — let AI mirror your own past**

> "Take every postmortem under `cases/` from the last month and extract the failure-pattern signature. Could I be running into one of those right now?"

Claude uses your own counterexamples to check you. Plain chat can't do this.

### A metaphor

Treat the knowledge base as the AI's working memory:

| | Without it | With it |
|---|---|---|
| Start of every chat | Re-onboard an amnesiac | AI has *read your past research* |
| Quality of advice | Generic, googleable | Fits your project, judgment, stage |
| Your role | Endlessly re-feed context | Jump straight to high-level decisions |

Capture is the means. **Letting every future AI conversation stand on the shoulders of your past thinking is the end.**

---

## Who this is for

**Strongly recommended for:**
- Engineers tracking a domain over time (distributed systems, AI, databases, cryptography…)
- Writers — bloggers, newsletter authors, researchers — who need to compound daily thinking
- Consultants / analysts processing high information throughput
- Tech leads turning team Q&A into a Feishu/Confluence-ready wiki
- Students / self-learners stacking up problem solutions, paper notes, interview prep

**Probably not for:**
- "I just want AI to write code, not accumulate knowledge" → vanilla Claude Code is fine
- Highly sensitive content that must never hit local disk → disable capture
- Tiny note volume (< 5 entries / week) → any note app is enough; automation is overkill

---

## Advanced

### With Obsidian

Point Obsidian at `./`. Claude writes, Obsidian reads:
- Obsidian Graph view = visualization of `GRAPH.md`
- Obsidian backlinks = the `related:` field Claude maintains
- Obsidian full-text search + Claude semantic retrieval = dual engine

### With Git

```bash
git init && git add . && git commit -m "init"
```

End of each day:

```bash
git add . && git commit -m "$(date +%F)"
```

Now you have a *personal Wikipedia* with full version history.

### With a team Feishu space

**First-time setup (one-shot, kicks in when you say "sync to Feishu"):**

> Claude: "Sync to a Feishu **wiki** (Wiki space, nested categories) or **docs** (Drive folder, flat list)?"
>
> You: "wiki"
>
> Claude: "Paste a Feishu link (space or node). Example: `https://example.feishu.cn/wiki/space/...`. Reply `list` to list available spaces."
>
> You: paste a space URL
>
> Claude: parses → checks permissions → writes `FEISHU_MAP.md` frontmatter → locks it as the default target

**After that, every turn auto-syncs** (default on, dialog-controllable):

When a turn changes `.md` files, Claude appends a "synced N file(s)" block with Feishu links to its final reply.

**Take control any time:**

> "turn off auto-sync" · "skip the sync this turn" · "switch the sync target to https://xxx.feishu.cn/drive/folder/..." · "push all `concepts/` notes tagged `importance: high` now"

Or use slashes: `/syncoff`, `/nosync`, `/synctarget <URL>`, `/syncnow`. Full list in the table above.

---

## FAQ

**Q: How is this different from ChatGPT's Memory?**
A: ChatGPT Memory is opaque, unreadable, non-portable, vendor-decided. AskNow's "memory" is local Markdown — readable, editable, portable, shareable, version-controllable.

**Q: Won't Claude pollute the base with random files?**
A: `CLAUDE.md` defines categorization rules, file granularity, depth floors, and dedup logic. The `knowledge-maintenance` skill cleans up periodically. Worst case: a few extra files — delete them. It's all plain Markdown.

**Q: Will it create files for every chat?**
A: No. `CLAUDE.md` explicitly excludes small talk, raw commands, trivial content. Multi-turn conversations append to the same file. Below the depth floor → merge into an existing file rather than create a thin one.

**Q: Can I use it with GPT or Gemini?**
A: The `CLAUDE.md` rules can port, but the skill system is Claude Code-specific. Effect on other AIs is degraded.

**Q: What about long-term volume?**
A: Journals auto-archive quarterly after 90 days. `knowledge-maintenance` merges duplicates. `STATUS.md` tracks global state. It scales.

**Q: Multi-machine sync?**
A: Use Git / iCloud / Dropbox / Syncthing — sync the whole directory. Or rely on the Feishu mirror as the shared source of truth.

---

## One closing line

> AI isn't a tool that thinks for you. It's a tool that **amplifies your thinking** — but only if your thinking compounds.
>
> You talk to AI every day. Every conversation ends, AI keeps nothing, you keep nothing. That is the most quietly wasteful pattern of this era.
>
> AskNow makes every question lay a brick, and makes every next question stand on the wall you've already built.
> Three months in, you don't just have a knowledge base — you have **an AI collaborator that actually understands your project**.

**`cd` into the project, run `claude`, ask the first question of today.**

---

## License

MIT
