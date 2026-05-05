# I Built a Lightweight Planning System for AI-Assisted Projects

When you're building fast with AI assistance, the velocity is great. The visibility isn't.

Features ship in hours. Plans multiply at the root of your repo. A week in, you can't answer "what's actually in flight right now?" without reading ten files. A month in, half those files are stale and you've forgotten which ones.

I built a system to fix that. It's called spec-driven planning, and the primary audience is me, not my AI assistant.

## The Real Problem

I had 38 `*_PLAN.md` files at the root of my repo. Some were active. Some had shipped. Some were half-done ideas from two months ago. Some contradicted each other.

Every time I opened a new session with Claude, I'd spend 15 minutes explaining which ones were still relevant. But that wasn't actually the problem. The problem was that *I* didn't have a clear picture either. I was re-explaining context I shouldn't have needed to re-explain, because I had no single place to look.

## The System

I created a `plans/` directory with three simple components:

**Plan files:** one per feature, with structured frontmatter and a status banner.

```yaml
---
status: active
priority: P1
owner: you
type: feature
depends_on: []
blocks: []
last_updated: 2026-05-04
---
```

```markdown
## Status

- **Overall:** In progress, Phase 2 of 3
- **Phase 0 (Design):** Done (2026-04-28)
- **Phase 1 (Backend):** Done (2026-05-01)
- **Phase 2 (Frontend):** In progress

**Next action:** Wire up the API client.
```

**STATUS.md:** one file that answers "where are we?". In flight, up next, recently shipped, backlog. You open this instead of searching through files.

**roadmap.html:** an interactive visual timeline that reads the plan files directly. Gantt chart, dependency graph, filterable plan cards. Open it in a browser, share it with anyone.

## The One Rule That Makes It Work

Everything starts as a backlog bullet in `STATUS.md`. No plan file gets created until work is committed. No idea lives in two places.

```
New idea -> STATUS.md backlog bullet (nothing else)
    committed
Plan file created -> STATUS.md "Up next" row
    work starts
in_flight: true -> STATUS.md "In flight" row
    phase ships
Phase marked done -> STATUS.md updated
    fully done
mv plans/active/ plans/shipped/
```

This eliminates the scattered document problem. Every idea has exactly one home at any given stage.

## Git Is the Ground Truth

Here's the subtle part: plans describe intent, not reality. Git log is what actually happened.

A plan can say Phase 2 is not started, but the code might already be merged. That's drift. Without a way to catch it, your plans become less useful over time.

The fix is a weekly audit. `/plans sync` is a Claude skill that reads git log, cross-references it against plan frontmatter, and proposes fixes as a diff. Review and confirm in about 2 minutes.

Frontmatter is machine-readable specifically for this. The skill reads it, validates it, catches disagreements between the frontmatter status and the banner, flags stale plans with no recent commits, detects orphaned dependency edges.

## What Actually Changed

I open STATUS.md in the morning and I know what's happening. I don't need to read ten files. I don't need to ask Claude. The answer is just there.

When I do open a new session with Claude, it reads STATUS.md and the relevant plan files. It already knows what's in flight. We start working in two messages instead of fifteen. But that's a side effect, not the point.

The point is that *I* know where my project stands. The AI benefit is that structured files are easier to reason about than scattered docs. Both are true, but one is the reason I built it.

## The Visual Layer

`roadmap.html` is probably my favourite part. It's a static HTML file that reads `plans.json` (auto-generated from plan frontmatter) and renders:

- A Gantt chart with progress bars, shipped items in green, a Today button that scrolls to the current date
- A dependency graph showing which plans block which, with zoom controls
- Filterable plan cards with phase breakdowns

No server, no database, no account. `python -m http.server 8080` and open the file. I share it with teammates who don't want to read markdown.

## Platform Portability

The `plans/` directory is pure markdown and JSON. Nothing about it is Claude-specific.

When Antigravity launched (Google's AI coding assistant), I checked their skills format. It's nearly identical to Claude Code's: a `SKILL.md` file with frontmatter in `.agents/skills/`. The `/plans` skill ports over by moving one file and renaming the directory.

The plans themselves don't change at all.

## How to Adopt It

Two commands and a quick prompt.

```bash
curl -sSL https://raw.githubusercontent.com/yrangana/Plans/main/install.sh | bash
plans-init /path/to/your/project
```

The first command installs the system once on your machine. The second bootstraps `plans/` in your project, adds it to `.git/info/exclude`, and detects your AI instruction file (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`). It asks before appending the planning section, so nothing happens to your file without consent.

After that:

1. Run `/plans new` to create your first real plan with correct structure (or edit `plans/active/EXAMPLE_PLAN.md` directly)
2. Add a row to `plans/STATUS.md`
3. Open `roadmap.html` in a browser (`python -m http.server 8080`)

When the system itself improves (new dashboard features, fixed bugs), run `plans-update` to pull updates in. It only touches system files like `roadmap.html`, never your `STATUS.md`, plans.json, or plan files. Backups go to `.bak` before any overwrite.

If you'd rather see what's happening underneath: it's just `mkdir`, a copy of the template directory, an entry in `.git/info/exclude`, and an append to your AI instruction file. Nothing magical.

The full templates, reference spec, roadmap dashboard, and `/plans` skill are in the repo.

The insight that made it click: structure isn't overhead. When your intent is structured, you can reason about it, and so can your tools.
