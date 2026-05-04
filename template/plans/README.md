# Nahra Planning System

A lightweight, Claude-native way to track what we're building, why, and where things stand — without a project management tool.

---

## The Problem It Solves

Software projects accumulate scattered planning documents — stale specs, ideas in Slack, decisions buried in PRs. Over time nobody knows what's planned, what shipped, and what was quietly abandoned.

AI assistants like Claude have the same problem: every new session starts blind. You re-explain context, Claude re-discovers what's in flight, work gets duplicated.

This system gives Claude (and everyone else) a **persistent, structured memory of intent** that survives across sessions.

---

## How It Works

Three layers, each with a distinct job:

```
plans/active/*.md       ← What we're building and why (spec + live status)
plans/plans.json        ← Machine-readable snapshot of all plans
plans/STATUS.md         ← Engineer's front door — what's in flight, what's next
plans/roadmap.html      ← Stakeholder view — interactive timeline + dependency graph
```

**Git log** is the ground truth for what actually shipped. Plans are the intent layer. A weekly audit (`/status-sync`, coming) reconciles the two automatically.

---

## Lifecycle of an Idea

```
1. New idea
   → Add a bullet to STATUS.md backlog section
   → Nothing else until committed

2. Work is committed (starting soon)
   → Create plans/active/MY_FEATURE.md with frontmatter + status banner
   → Add a row to STATUS.md "Up next" table

3. Work starts
   → Set in_flight: true in frontmatter
   → Move row to STATUS.md "In flight" table

4. Phase ships
   → Mark phase ✅ in the plan's ## Status banner
   → Update STATUS.md tables
   → Bump last_updated in both files

5. Everything ships
   → mv plans/active/MY_FEATURE.md plans/shipped/
   → Move row to STATUS.md "Recently shipped"
```

---

## Anatomy of a Plan File

Every plan has two layers:

**1. YAML frontmatter** — machine-readable, at the top of the file:

```yaml
---
status: active            # active | shipped | superseded | paused | blocked
priority: P1              # P0 (critical) → P3 (nice to have)
owner: yash
type: feature             # plan | feature | bug | research | spike
depends_on: []            # other plan filenames this is waiting on
blocks: []                # other plan filenames waiting on this
last_updated: 2026-05-04
---
```

**2. `## Status` banner** — human-readable, second heading in the file:

```markdown
## Status

- **Overall:** 🟡 In progress — Phase 2 of 3
- **Phase 0 — Design:** ✅ Done (2026-04-28)
- **Phase 1 — Backend:** ✅ Done (2026-05-01)
- **Phase 2 — Frontend:** 🟡 In progress
- **Phase 3 — Tests:** 🔴 Not started

**Next action:** Wire up the state to the API client.
**Last updated:** 2026-05-04
```

**Rule:** frontmatter and banner must agree. If they disagree, frontmatter wins.

---

## Directory Structure

```
plans/
├── README.md           ← You are here
├── STATUS.md           ← Front door: in flight / up next / shipped / backlog
├── plans.json          ← Auto-generated snapshot (never hand-edit)
├── roadmap.html        ← Interactive dashboard (reads plans.json directly)
├── active/             ← Plans in progress or committed-but-not-started
│   ├── MY_FEATURE.md
│   └── ...
└── shipped/            ← Completed plans (kept for history)
    └── ...
```

> `plans/` is git-excluded — use plain `mv`, not `git mv`.

---

## The Views

### STATUS.md — for engineers and Claude

Text-based. Claude reads this at the start of every session to get oriented. Contains:
- **In flight** — what's being worked on now
- **Up next** — committed for the next 30 days
- **Recently shipped** — last 30 days
- **Backlog** — captured ideas, not yet committed
- **Monthly log** — append-only history

### roadmap.html — for stakeholders

Interactive web page. Load it with a local server:
```
python -m http.server 8080
# then open http://localhost:8080/roadmap.html
```

Shows:
- **Gantt chart** — timeline with progress bars, Today button
- **Dependency graph** — which plans block which
- **Plan cards** — filterable by status, with phase breakdown

Reads `plans.json` directly — no manual updates needed.

---

## What Claude Does With This

At the start of every session, Claude reads `STATUS.md` and relevant plan files. This means:

- **"What's next?"** has a deterministic answer — no re-explaining
- **"Is X shipped?"** — Claude cross-checks git log against plan status
- **When you ship something** — Claude knows which plan to update and how
- **Drift detection** — `/status-sync` (coming) reads git log, compares to plan frontmatter, proposes fixes

---

## Coming: `/status-sync`

A Claude slash command that automates the weekly audit:

1. Reads all plan frontmatter
2. Runs `git log` since last sync
3. Detects drift (shipped phases not marked, stale plans, orphaned dependencies)
4. Proposes fixes as a diff — never writes without confirmation

Build trigger: after 1-week manual validation (~2026-05-11).

---

## Quick Rules

- **One capture point** — ideas go to `STATUS.md` backlog, nowhere else
- **No root plan files** — `plans/active/` is the only home for new plans
- **Every "In flight" / "Up next" row needs a plan file** — create both together
- **Don't bulk-migrate old plans** — triage them on-demand when revisited
- **`plans.json` is auto-generated** — edit plan `.md` files, never the JSON directly
