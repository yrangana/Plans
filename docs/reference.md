# Spec-Driven Planning: Technical Reference

A structured planning convention for software projects built with AI assistance.
The system gives developers a single source of truth for project intent: what's planned, what's in progress, what's shipped, in a format that is both human-readable and machine-readable.

---

## Scope and Boundaries

### What it is

- An intent/spec layer separate from git history
- Markdown + JSON files in a git-excluded `plans/` directory
- A way to keep persistent context across plans, for yourself, over time
- A weekly reconciliation pattern (manual now, automated via `/plans sync`)

### What it is not

- Not a project management tool (no replacement for Linear / Jira / Asana)
- Not a task tracker (operates at plan/phase level, not individual TODOs)
- Not a team collaboration system (single-author, local-only)
- Not a documentation system (design docs, RFCs, ADRs still belong in `docs/`)
- Not git-tracked or auditable (decisions must live in commits/PRs if traceability matters)
- Not required by any AI assistant (it's optional context, not infrastructure)

### What you get

- A single source of truth for "what's in flight, what's next, what just shipped"
- Persistent context for AI assistants across sessions
- A shareable visual roadmap (roadmap.html) for non-technical stakeholders
- Automated drift detection between plans and git log (via `/plans sync`)
- Forced clarity: writing the spec surfaces muddy thinking before the code does
- Reduced context-switching cost when resuming work after a break

### When to adopt

| Adopt when | Don't adopt when |
|---|---|
| 1 to 3 person team | 5+ person team (use a real PM tool) |
| 3+ committed features in flight | Single-feature scope |
| AI-assisted development | Minimal AI assistance |
| Regular re-explaining of project context | Project state stays in your head |
| Plans accumulating at repo root | No spec writing happens |
| Multi-week or multi-month projects | One-off scripts, prototypes |

### Audience

| Primary | Secondary | Not the audience |
|---|---|---|
| Solo devs, indie hackers | Small startup teams (≤3) | Larger engineering orgs |
| Users of Claude Code / Antigravity / Cursor | Engineers prototyping rapidly | Open source maintainers (use Issues) |
| | | Regulated environments (need audit trail) |

---

## Directory Structure

```
plans/
├── README.md              # System overview for anyone new to the repo
├── STATUS.md              # Front door, daily check-in file
├── plans.json             # Machine-readable snapshot: { project, plans[] } (auto-generated, never hand-edit)
├── roadmap.html           # Visual dashboard, reads plans.json directly
├── active/                # In-progress and committed-but-not-started plans
│   └── FEATURE_NAME.md
├── shipped/               # Completed plans (archived, not deleted)
│   └── FEATURE_NAME.md
└── superseded/            # Plans replaced by a different approach (archived, not deleted)
    └── FEATURE_NAME.md
```

**Git exclusion.** `plans/` is local-only, never committed:

```bash
echo "plans/" >> .git/info/exclude
```

Use plain `mv` for all file moves, not `git mv`.

---

## Plan File Spec

### Location

- Active / queued: `plans/active/FEATURE_NAME.md`
- Completed: `plans/shipped/FEATURE_NAME.md`
- Replaced by another approach: `plans/superseded/FEATURE_NAME.md`
- Naming: `SCREAMING_SNAKE_CASE.md`, descriptive, no version suffixes

### File structure

```markdown
---
{frontmatter}
---

# Plan: {Title}

## Status

{status banner}

---

{body: context, goals, non-goals, phases, implementation notes}
```

### Frontmatter spec

10 fields. The first 7 are required at creation. `start_date`, `eta`, and `in_flight` are managed by the tooling: `/plans new` writes `start_date` (and `eta` when you give an effort estimate); `in_flight` is set separately when work actually starts.

| Field | Type | Values | Description |
|---|---|---|---|
| `status` | enum | `active` `shipped` `superseded` `paused` `blocked` | Current state |
| `priority` | enum | `P0` `P1` `P2` `P3` | P0 = critical, P3 = nice-to-have |
| `owner` | string | username | Who is responsible |
| `type` | enum | `plan` `feature` `bug` `research` `spike` | Work category |
| `depends_on` | list | filenames without `.md` | Plans this is waiting on |
| `blocks` | list | filenames without `.md` | Plans waiting on this |
| `last_updated` | date | `YYYY-MM-DD` | Last meaningful update |
| `start_date` | date | `YYYY-MM-DD` | When work is planned to start. Written by `/plans new` (defaults to today). Anchors the Gantt bar's left edge. |
| `eta` | date | `YYYY-MM-DD` | Target completion date. Written by `/plans new` from an effort estimate, or added later. Optional; an undated plan is flagged by `/plans sync` Rule 10. |
| `in_flight` | bool | `true` `false` | Set to `true` when work actively starts. Drives dashboard "In flight" vs "Up next" split. Omit or set `false` at creation. |

Example:

```yaml
---
status: active
priority: P1
owner: you
type: feature
depends_on: [AUTH_PLAN]
blocks: [DASHBOARD_PLAN, WIDGET_PLAN]
last_updated: 2026-05-04
start_date: 2026-05-01
eta: 2026-05-11
in_flight: false
---
```

### Status banner spec

The second heading in every plan. Must agree with frontmatter `status`.

**Status indicators:**

| Indicator | Meaning |
|---|---|
| Done | Shipped |
| In progress | Active work |
| Not started | Queued |
| Paused | On hold |
| Blocked | Waiting on something external |

**Required fields in the banner:**

- `**Overall:**` one-line summary with phase progress
- One line per phase with status, name, and date or ETA
- `**Next action:**` the single next concrete step
- `**Last updated:**` must match frontmatter date

Template:

```markdown
## Status

- **Overall:** In progress, Phase 2 of 3
- **Phase 0 (Design):** Done (2026-04-28)
- **Phase 1 (Backend):** Done (2026-05-01)
- **Phase 2 (Frontend):** In progress
- **Phase 3 (Tests):** Not started

**Next action:** Wire up the state to the API client.
**Last updated:** 2026-05-04
```

### Two-source rule

Frontmatter `status` and banner must always agree. If they conflict, **frontmatter wins**. Update both together.

---

## plans.json Spec

Auto-generated by `/plans sync`. Never hand-edit. Consumed by `roadmap.html` and any future tooling (including a future centralised dashboard that aggregates `plans.json` across multiple projects).

### Schema

Top-level shape: an object with a `project` header and a `plans` array.

```json
{
  "project": {
    "name": "My Project",
    "description": "One-line project description.",
    "repo": "https://github.com/owner/repo"
  },
  "plans": [
    {
      "file": "FEATURE_NAME.md",
      "title": "Human-readable plan title",
      "status": "active",
      "priority": "P1",
      "owner": "you",
      "type": "feature",
      "depends_on": [],
      "blocks": ["OTHER_PLAN"],
      "last_updated": "2026-05-04",
      "start_date": "2026-05-01",
      "overall": "In progress (Phase 2 of 3)",
      "eta": "2026-05-11",
      "in_flight": true,
      "next_action": "Wire up the state to the API client.",
      "phase_summary": [
        { "phase": 0, "name": "Design",   "status": "shipped",     "date": "2026-04-28" },
        { "phase": 1, "name": "Backend",  "status": "shipped",     "date": "2026-05-01" },
        { "phase": 2, "name": "Frontend", "status": "in_progress", "eta": "2026-05-11"  },
        { "phase": 3, "name": "Tests",    "status": "not_started", "eta": null           }
      ]
    }
  ]
}
```

### project header

The `project` object identifies which project this `plans.json` belongs to. Required.

| Field | Type | Description |
|---|---|---|
| `name` | string | Project name. Required. Drives the dashboard title and any aggregator grouping. Empty string allowed as a stub; expected to be filled in. |
| `description` | string | One-line project description. Required. Empty string allowed as a stub. |
| `repo` | string | Repository URL (e.g., GitHub). Required. Empty string allowed as a stub. |

If a `plans.json` is missing the `project` header, `/plans sync` creates a stub with empty strings and notes it in the sync output. Adopters then fill in the values; subsequent syncs preserve them.

### plans array field reference

| Field | Source | Description |
|---|---|---|
| `file` | filename | Plan filename including `.md` |
| `title` | H1 heading | Human-readable title |
| `status` | frontmatter | Current state |
| `priority` | frontmatter | P0 to P3 |
| `owner` | frontmatter | Responsible person |
| `type` | frontmatter | Work category |
| `depends_on` | frontmatter | Blocking dependencies |
| `blocks` | frontmatter | Downstream dependents |
| `last_updated` | frontmatter | Last update date |
| `start_date` | frontmatter, else earliest dated phase, else `last_updated` | Gantt bar start |
| `overall` | status banner | One-line summary string |
| `eta` | frontmatter, else latest dated/ETA phase, else `null` | Gantt bar end; target completion date |
| `in_flight` | explicit field | `true` = actively being worked now |
| `next_action` | status banner | Next concrete step |
| `phase_summary` | status banner | Per-phase breakdown array |

---

## STATUS.md Spec

The daily check-in file. One file answers: what's in flight, what's next, what just shipped, what's the backlog.

### Structure

```markdown
# {Project}: Project Status
*Last updated: YYYY-MM-DD*

> {One-paragraph mission or project description}

---

<!-- AUTO-GENERATED from plans/plans.json -->

## At a glance
{summary table: in flight / up next / shipped counts}

## Roadmap at a glance
{mermaid gantt}

## Cross-plan dependencies
{mermaid flowchart}

## In flight: what we're working on now
{table}

## Up next: committed for next 30 days
{table}

<!-- END AUTO-GENERATED -->

---

## Recently shipped: last 30 days
{table}

## Monthly log: append-only history
{append-only log entries}

---

## Backlog / ideas: captured, not committed
{bullet list}

## Blocked / risks
{table}
```

### Auto-generated vs hand-maintained

| Section | Source |
|---|---|
| At a glance | Auto, count of `plans.json` entries by `in_flight` / `status` |
| Gantt chart | Auto, from `plans.json` |
| Dependencies flowchart | Auto, from `plans.json` `depends_on`/`blocks` |
| In flight table | Auto, from `plans.json` where `in_flight: true` |
| Up next table | Auto, from `plans.json` where `status: active, in_flight: false` |
| Recently shipped | Auto, from git log since last update |
| Monthly log | Hand-maintained, append-only |
| Backlog | Hand-maintained, ideas not yet committed |
| Blocked / risks | Hand-maintained |

---

## Idea Lifecycle

```
New idea
  -> Add bullet to STATUS.md backlog
  -> No plan file yet

Committed (work starting soon)
  -> Create plans/active/FEATURE.md with frontmatter + banner
  -> Add row to STATUS.md "Up next" table
  -> Add entry to plans.json

Work starts
  -> Set in_flight: true in frontmatter and plans.json
  -> Move STATUS.md row to "In flight" table

Phase ships
  -> Mark phase done in banner
  -> Update STATUS.md tables
  -> Bump last_updated in frontmatter and banner

Plan fully ships
  -> mv plans/active/FEATURE.md plans/shipped/FEATURE.md
  -> Update status: shipped in frontmatter
  -> Move to STATUS.md "Recently shipped"
  -> Update plans.json entry

Plan is replaced by a different approach
  -> mv plans/active/FEATURE.md plans/superseded/FEATURE.md
  -> Update status: superseded in frontmatter
  -> Note which plan or approach replaced it in the plan body
  -> Remove from STATUS.md "In flight" / "Up next" tables
```

---

## AI Assistant Integration

Add this section to your instruction file (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, etc.). `plans-init` appends it automatically.

```markdown
## Project Status & Plan Management

Read `plans/STATUS.md` at the start of every session. It is the front door: what is in flight, what is up next, what just shipped.
Active plans live in `plans/active/`, completed plans in `plans/shipped/`, replaced plans in `plans/superseded/`.
`plans/plans.json` is auto-generated. Never hand-edit it.

Every plan file has two layers that must agree. See `plans/README.md` for exact format and valid field values.

1. YAML frontmatter (machine-readable) with 8 fields: `status`, `priority`, `owner`, `type`, `depends_on`, `blocks`, `last_updated` (all required at creation), plus `in_flight` (set to `true` when work actively starts).
2. `## Status` banner (human-readable) showing per-phase progress and the next action.

If frontmatter and banner conflict, frontmatter wins.

When a phase ships or a PR maps to a plan:

1. Mark the phase done in the plan's `## Status` banner; highlight the next phase
2. Bump `last_updated` in the plan's frontmatter and banner
3. Update `plans/STATUS.md`, move rows between "In flight" / "Up next" / "Recently shipped"
4. If fully complete: `mv plans/active/X.md plans/shipped/X.md`
5. If replaced by another approach: `mv plans/active/X.md plans/superseded/X.md`, set `status: superseded`

Idea lifecycle:

- New idea: add a bullet to `plans/STATUS.md` backlog only. No plan file yet.
- Work committed: run `/plans new` to create `plans/active/FEATURE.md` with correct frontmatter and banner, then add a row to STATUS.md
- Work started: set `in_flight: true` in the plan's frontmatter (this drives the dashboard timeline)
- Never create plan files at the repo root: `plans/active/` is the only home
- Every "In flight" and "Up next" row in STATUS.md must have a corresponding plan file

`plans/` is git-excluded. Use plain `mv`, not `git mv`.
Update plan files as part of the work, not as a follow-up.
To audit drift between plans and git, run `/plans sync`.
To create a new plan file with correct structure, run `/plans new`.
```

---

## /plans Skill Spec

A slash command (Claude Code) or equivalent skill (Antigravity, Cursor) with two modes.

```
/plans sync   audit plans/ for drift, regenerate derived files, propose fixes
/plans new    guided creation of a new plan file with correct structure
```

### /plans sync

#### What it reads

| Source | Purpose |
|---|---|
| `plans/active/*.md` frontmatter | Canonical machine-readable state |
| `plans/active/*.md` `## Status` banners | Cross-check for two-source disagreement |
| `plans/shipped/*.md` frontmatter | Dependency validation |
| `plans/superseded/*.md` frontmatter | Dependency validation |
| `plans/STATUS.md` tables | Verify rows match plan files |
| `git log --since="{last STATUS.md update}"` | Commits since last sync |

#### Drift detection rules

| Rule | Detection | Resolution |
|---|---|---|
| Stale active plan | `status: active` + no commits in 14d touching its domain | Flag: paused or abandoned? |
| Unrecorded shipped phase | Commits indicate shipped feature; plan still Not started | Propose marking Done |
| Plan not in STATUS.md | File in `plans/active/` missing from In flight or Up next | Propose adding row |
| Stale `last_updated` | Frontmatter date >7d on active plan with recent commits | Propose bumping date |
| Orphaned STATUS.md row | Row in tables but no file in `plans/active/` | Flag: create plan or demote to backlog |
| Dependency cycle | `depends_on` graph has a cycle | Flag, cannot auto-resolve |
| Orphaned edge | Plan A `depends_on: [B]` but B doesn't list `blocks: [A]` | Propose adding reverse edge |
| Two-source disagreement | Frontmatter `status` vs banner conflict | Frontmatter wins; propose fixing banner |
| Missing frontmatter field | Any of 7 creation-required fields absent | Flag with expected value |
| Missing timeline data | Active plan with no `eta` and no dated phases | Flag: Gantt cannot draw a real span |
| Stale start_date | Unstarted active plan with `start_date` in the past | Propose rolling forward to today, sliding `eta` to match |
| Missing project header | `plans.json` is an array or lacks `project` object | Auto-create a stub `{"name":"","description":"","repo":""}` and note it in sync output |
| Empty project field | `project.name`, `project.description`, or `project.repo` is an empty string | Flag: prompt the adopter to fill it in |

#### Output pipeline

```
plans/active/*.md  +  plans/shipped/*.md
        |
        |  extract frontmatter
        v
plans/plans.json   (regenerated: project header preserved, plans[] rebuilt, superseded excluded)
        |
        +-> plans/STATUS.md   (auto-generated sections regenerated)

plans/roadmap.html reads plans.json directly, no regeneration needed
```

When regenerating `plans.json`, `/plans sync` preserves the existing `project` header verbatim. If the file is missing the header (e.g., legacy array-only file from before this spec), sync creates a stub with empty strings and notes it in the output.

#### Behaviour contract

- Proposal-only: never writes without explicit confirmation
- Prints changes as a diff-style list
- Asks for confirmation per file or all-at-once
- Applies only confirmed changes

### /plans new

Guided creation of a new plan file. Asks: name, type, priority, depends_on, blocks, owner, timeline (start date and an effort estimate in days). Writes `plans/active/NAME.md` with correct frontmatter and status banner template, including `start_date` and a resolved `eta`. Reminds the user to add a row to `plans/STATUS.md`. Does not set `in_flight: true`.

---

## Platform Portability

`plans/` is platform-agnostic, pure markdown and JSON. Only the delivery mechanism differs per platform.

| Component | Claude Code | Antigravity | Cursor |
|---|---|---|---|
| Instruction file | `CLAUDE.md` | `AGENTS.md` | `.cursorrules` |
| Skill location | `.claude/skills/plans/` | `.agents/skills/plans/` | Custom commands |
| `plans/` directory | Identical | Identical | Identical |
| `plans.json` | Identical | Identical | Identical |
| `roadmap.html` | Identical | Identical | Identical |

`plans-init` detects which platform is in use and installs the skill to the correct location automatically. `plans-update` checks both locations.

---

## Installation and Updates

The plans system ships as a small set of bash scripts. Install once on your machine, then bootstrap and update individual projects.

### One-liner installer

```bash
curl -sSL https://raw.githubusercontent.com/yrangana/Plans/main/install.sh | bash
```

What it does:

1. Clones the plans repo to `~/.local/share/plans` (override with `PLANS_DIR=...`).
2. Symlinks `plans-init` and `plans-update` into `~/.local/bin/` (override with `PLANS_BIN=...`).
3. Prints a PATH reminder if `~/.local/bin` is not on your `PATH`.

Re-run any time to update the plans system itself. If `~/.local/share/plans` already exists, the installer pulls latest instead of re-cloning.

Custom repo URL: `PLANS_REPO=https://github.com/your-fork/plans.git curl -sSL ... | bash`.

### plans-init: bootstrap a project

```bash
plans-init                    # set up plans/ in the current directory
plans-init /path/to/project   # set up plans/ in the given directory
plans-init --no-snippet       # skip auto-append to AI instruction file
plans-init -h                 # show usage
```

What it does:

1. Copies `template/plans/` into the target directory.
2. Adds `plans/` to `.git/info/exclude` (local git ignore, never committed).
3. Detects AI instruction files in this order: `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`. For each detected file, prompts before appending the planning section from `template/CLAUDE.md.snippet`.
4. Installs the `/plans` skill to the matching platform directory: `.claude/skills/plans/` for Claude Code / Cursor / Windsurf, `.agents/skills/plans/` for Antigravity.
5. Idempotent: if a detected file already contains the snippet's marker heading (`## Project Status & Plan Management`), it skips that file.
6. Aborts if `plans/` already exists in the target. Use `plans-update` to refresh existing installations.

### plans-update: refresh system files in an existing project

```bash
plans-update                          # update plans/ in the current directory
plans-update /path/to/project         # update plans/ in the given directory
plans-update --no-pull                # skip the auto-pull (offline or local edits)
plans-update -h                       # show usage
```

What it does:

1. By default, runs `git pull` on the plans repo at `~/.local/share/plans` to fetch the latest system files.
2. Diffs system files against the project's copies. Shows previews of changes.
3. Prompts before applying. Backs up each modified file as `<file>.bak` before overwriting.
4. Exits cleanly if nothing changed.

### System files vs user data

`plans-update` enforces a clear boundary so user data is never lost.

| Category | Files | Behavior |
|---|---|---|
| System files | `plans/roadmap.html`, `plans/README.md` | Replaced on update. Backup written to `.bak`. |
| User data | `plans/STATUS.md`, `plans.json`, `active/`, `shipped/`, `superseded/`, anything else | Never touched by `plans-update`. |

If you customize a system file (e.g., your own colour scheme in `roadmap.html`), expect updates to overwrite it. Restore from `<file>.bak` if needed, or run with `--no-pull` to inspect changes before they're fetched.

### Versioning

The plans repo loosely follows [semantic versioning](https://semver.org/). See [CHANGELOG.md](../CHANGELOG.md) for what's changed between versions.

- **Major:** breaking changes to the plan file format, frontmatter spec, or directory layout (adopters must migrate).
- **Minor:** new features in `roadmap.html`, scripts, or docs (adopters can update or skip).
- **Patch:** bug fixes and clarifications.

Until v1.0, the format is considered fluid and breaking changes may occur.
