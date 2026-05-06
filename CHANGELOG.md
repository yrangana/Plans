# Changelog

All meaningful changes to the plans system are recorded here.

This project loosely follows [semantic versioning](https://semver.org/):

- **Major** version bumps for breaking changes to the plan file format, frontmatter spec, or directory layout (adopters must migrate).
- **Minor** version bumps for new features in `roadmap.html`, scripts, or docs (adopters can update or skip).
- **Patch** version bumps for bug fixes and small clarifications.

Versions are tagged on GitHub once meaningful changes accumulate. Until v1.0, the format is considered fluid.

---

## Unreleased

- `roadmap.html`: replaced Frappe Gantt with a pure CSS/JS horizontal bar timeline matching the visual design of `status.html` (dark header, card sections, `#e2e8f0` borders, uppercase label typography). No external Gantt library dependency.
- `roadmap.html`: today line now rendered via CSS `calc()` in the timeline, consistent with `status.html`. Always visible when today falls within the plan date range.
- `roadmap.html`: header badge shows last-updated date; section headers use uppercase label style; emoji removed from all section headings.
- `roadmap.html`: dependency graph now only renders nodes that participate in at least one edge. Isolated active plans (no deps) no longer appear as floating islands.
- `roadmap.html`: when no dependencies exist, graph controls are hidden and the empty state collapses to a single short row instead of a tall blank box.
- `roadmap.html`: status pills aligned to `status.html` style (`.pill-active`, `.pill-shipped`, `.pill-blocked`, `.pill-paused`).
- `examples/demo.svg`: animated SVG terminal demo added for README, showing `plans-init` output and a mini STATUS.md panel with Gantt bars.
- `examples/status.html`: today line `calc()` formula fixed (was rendering at far left due to invalid mixed-unit expression).
- `docs/presentation.html`: outcome slide updated to show STATUS.md markdown format with a live link, replacing the colour panel mockup.
- README: status badges, demo SVG, status.html link, screenshots, and five-entry docs table added.

## Unreleased (carried from previous)

- `update.sh` auto-pulls the plans repo before applying updates (use `--no-pull` to skip)
- `install.sh` one-liner installer that clones the repo and symlinks `plans-init` / `plans-update` to `~/.local/bin/`
- `roadmap.html` derives page title from `STATUS.md` H1 (e.g. `# MyProject - Project Status` -> `MyProject - Roadmap`); adopters no longer need to manually edit the title
- `install.sh` URLs aligned to canonical `Plans` repo casing (was lowercase, now matches the GitHub repo name)
- `roadmap.html` derived title uses regular dash instead of em dash, consistent with the no-em-dash style convention
- `init.sh` auto-detects existing AI instruction files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`) and offers to append the plans snippet automatically. Idempotent: re-running skips files that already have the section. Use `--no-snippet` to opt out.
- `init.sh` and `update.sh`: fixed symlink resolution bug — scripts now work correctly when invoked via symlinks in `~/.local/bin/` (was resolving to symlink directory instead of real script location)
- `init.sh`: when no AI instruction file is detected, prints the snippet content inline instead of a path to the installed clone
- `roadmap.html`, `init.sh`, README: server options expanded to Python 3, Node.js (`npx serve`), and PHP (was Python-only)
- `plans/README.md` added to system files managed by `plans-update` (was user data, now updated on `plans-update` like `roadmap.html`)
- Skill renamed from `/status-sync` to `/plans-sync` throughout docs for consistency with `plans-init` / `plans-update` naming
- Uninstall instructions added to README
- `plans/superseded/` directory added to the convention: plans replaced by a different approach move here (distinct from `shipped/`, which means the work is done). `template/`, `template/CLAUDE.md.snippet`, all docs, and `update.sh` updated accordingly.
- `/plans` skill built at `template/skills/plans/` with two modes: `/plans sync` (weekly drift audit: reads frontmatter + banners, cross-references git log, regenerates `plans.json` and `STATUS.md` auto-sections, proposes diff before writing) and `/plans new` (guided creation of a correctly structured plan file). Replaces the earlier single-mode `/plans-sync` skill.
- `plans-init` now installs the `/plans` skill to the correct platform directory: `.agents/skills/plans/` for `AGENTS.md` projects (Antigravity), `.claude/skills/plans/` for all others (Claude Code, Cursor, Windsurf). Default falls back to `.claude/skills/plans/` when no instruction file is detected.
- `plans-update` now checks and offers to update the skill at both `.claude/skills/plans/` and `.agents/skills/plans/`, running skill checks before the system-file early exit so skill-only updates are never silently skipped.

## v0.1.0 (TBD)

First public release. Includes:

- 7-field plan frontmatter spec (`status`, `priority`, `owner`, `type`, `depends_on`, `blocks`, `last_updated`)
- `plans/` directory convention: `active/`, `shipped/`, plus `STATUS.md`, `plans.json`, `roadmap.html`
- Two-source rule (frontmatter and banner must agree)
- Idea lifecycle: backlog bullet -> plan file when committed -> shipped/ when complete
- `roadmap.html` interactive dashboard:
  - Frappe Gantt timeline with cluster-based color coding (connected components in dependency graph)
  - vis-network dependency graph with zoom controls
  - Filterable plan cards (All / Active / Shipped)
  - Today button and auto-scroll on load
  - Read-only (drag-to-edit disabled)
- `init.sh` and `update.sh` bash scripts for setup and updates
- `template/CLAUDE.md.snippet` for AI assistant integration
- Live demo at GitHub Pages, reads `examples/plans.json`
- Documentation: `README.md`, `docs/reference.md`, `docs/blog-post.md`, `docs/presentation.html`
