# Plans

> A lightweight intent layer for AI-assisted projects. Markdown + JSON, works with Claude Code, Antigravity, Cursor, or any AI coding assistant.

[Live demo](https://yrangana.github.io/Plans/examples/) · [Slides](https://yrangana.github.io/Plans/docs/presentation.html) · [Blog post](docs/blog-post.md) · [Reference spec](docs/reference.md)

---

## What this is

A spec-driven planning convention. Every project feature is a markdown file with structured frontmatter and a status banner. One `STATUS.md` answers "what's in flight, what's next, what just shipped". A static `roadmap.html` renders an interactive Gantt + dependency graph from the same data.

It works with any AI coding assistant. The data model is plain markdown and JSON. Only the instruction file (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`) changes per platform.

## What you get

- A single source of truth for "what's in flight, what's next, what just shipped"
- Persistent context across plans, for yourself, over time
- Persistent context for your AI assistant across sessions
- A shareable visual roadmap for non-technical stakeholders
- Drift detection between intent (plans) and reality (git log)

## Is this for you?

| Adopt when | Skip when |
| --- | --- |
| Solo dev or small team (1 to 3 people) | Team of 5+ (use a real PM tool) |
| 3+ committed features in flight | Single-feature scope |
| AI-assisted development | Regulated environments (need audit trail) |
| Plans accumulating at repo root | Open source (use Issues) |

Full scope and audience details in [docs/reference.md](docs/reference.md).

---

## Quick Start

### 1. Drop the template into your project

```bash
git clone https://github.com/yrangana/Plans.git ~/.local/share/plans
~/.local/share/plans/scripts/init.sh /path/to/your/project
```

Or copy the `template/plans/` directory manually.

### 2. Tell your AI assistant about it

Append the contents of [`template/CLAUDE.md.snippet`](template/CLAUDE.md.snippet) to your project's `CLAUDE.md` (or `AGENTS.md`, `.cursorrules`, etc.).

### 3. Open the dashboard

```bash
cd /path/to/your/project
python -m http.server 8080
# open http://localhost:8080/plans/roadmap.html
```

### 4. Edit your first plan

Open `plans/active/EXAMPLE_PLAN.md`, replace it with your real first plan, and add a row to `plans/STATUS.md`.

---

## Docs and resources

Four ways into the system, depending on what you want:

| Resource | Best for | Format |
| --- | --- | --- |
| [**Live demo**](https://yrangana.github.io/Plans/examples/) | Seeing the dashboard with real data | Interactive web page |
| [**Slides**](https://yrangana.github.io/Plans/docs/presentation.html) | A 5-minute overview of the whole system | Reveal.js deck |
| [**Blog post**](docs/blog-post.md) | The story and motivation behind it | Long-form prose |
| [**Reference spec**](docs/reference.md) | Implementation details, every field, every rule | Technical reference |

---

## Repo Structure

```text
plans/
├── docs/                    # Full guide
│   ├── reference.md         # Technical spec
│   ├── blog-post.md         # Narrative explanation
│   └── presentation.html    # Slideshow
├── template/                # Drop-in starter for your project
│   ├── plans/               # The directory you copy into your repo
│   │   ├── README.md        # Onboarding doc
│   │   ├── STATUS.md        # Daily check-in template
│   │   ├── plans.json       # Machine-readable snapshot (empty to start)
│   │   ├── roadmap.html     # Interactive dashboard
│   │   ├── active/          # In-progress plans (with EXAMPLE_PLAN.md)
│   │   └── shipped/         # Completed plans
│   └── CLAUDE.md.snippet    # The section to add to your AI instruction file
├── scripts/
│   └── init.sh              # One-command setup
└── examples/
    └── plans.json           # Demo data for the live roadmap
```

## How It Works

```text
plans/active/*.md             plans/shipped/*.md
   (frontmatter + banner)        (frontmatter + banner)
              \                  /
               \                /
                v              v
              plans/plans.json    <- machine-readable snapshot
              /              \
             v                v
   plans/STATUS.md       plans/roadmap.html
   (engineer's front     (stakeholder visual
    door)                 dashboard)
```

Git log is the ground truth for what shipped. Plan files are the intent layer. The `/status-sync` skill (coming) reconciles them weekly.

---

## Coming: `/status-sync` Skill

A Claude Code slash command (and Antigravity skill, Cursor command) that automates the weekly audit:

1. Reads all plan frontmatter
2. Runs `git log` since last sync
3. Detects drift (shipped phases unmarked, stale plans, missing fields)
4. Regenerates `plans.json` and STATUS.md auto-sections
5. Shows proposed changes as a diff, asks before writing

Track progress in [docs/reference.md](docs/reference.md).

---

## Platform Compatibility

| Platform | Instruction file | Skill format |
| --- | --- | --- |
| Claude Code | `CLAUDE.md` | `.claude/skills/*.md` |
| Antigravity | `AGENTS.md` | `.agents/skills/*/SKILL.md` |
| Cursor | `.cursorrules` | Custom slash commands |
| Windsurf | `.windsurfrules` | Workflows |

The `plans/` directory is identical across all platforms.

---

## Contributing

This is a small, opinionated convention. Issues and PRs welcome for:

- Bug fixes in `template/plans/roadmap.html`
- Doc clarifications
- Cross-platform skill ports (Cursor, Windsurf)
- The `/status-sync` skill implementation

For substantive changes to the convention itself (frontmatter spec, lifecycle), open an issue first to discuss.

## License

[MIT](LICENSE). Fork, adapt, share.
