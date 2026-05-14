# Changelog

All meaningful changes to the plans system are recorded here.

This project loosely follows [semantic versioning](https://semver.org/):

- **Major** version bumps for breaking changes to the plan file format, frontmatter spec, or directory layout (adopters must migrate).
- **Minor** version bumps for new features in `roadmap.html`, scripts, or docs (adopters can update or skip).
- **Patch** version bumps for bug fixes and small clarifications.

Versions are tagged on GitHub once meaningful changes accumulate. Until v1.0, the format is considered fluid.

---

## v0.2.0

- `VERSION` file added at the repo root: single source of truth for the released version, starting at `0.2.0`. `template/skills/plans/SKILL.md` carries a matching `version:` field so an installed skill is self-identifying.
- `/plans sync` gained a Step 0 version check: on each run it reads its own skill version and fetches the published `VERSION` from GitHub, printing a one-line nudge to run `plans-update` if the skill is behind. The check is best-effort and never blocks: any network failure (offline, timeout, non-200) is silent and sync proceeds normally.
- `plans-update`: after a successful skill update, prints the new skill version and reminds the user to run `/plans sync` to apply any STATUS.md structure changes.
- `template/plans/roadmap.html`: rebuilt on the deployed `web/roadmap.html` design (metric strip, Gantt with date axis and today line, dependency block-chains, plan list with phase dots and progress bars, sidebar legend). Keeps the `plans.json` / `STATUS.md` fetch layer and the `file://` error state. Drops the vis.js dependency: the dependency view is now static block-chains instead of a force-directed graph. The deployed demo (`web/`) and the adopter template no longer share a build, so this brings adopters to visual parity with the demo.
- `template/plans/roadmap.html`: STATUS.md title regex now matches the canonical `# {Project}: Project Status` colon format (also accepts dash and en dash). Previously expected only a dash, so the page title never resolved against the shipped STATUS.md template.
- `template/plans/STATUS.md`: added an `## At a glance` summary table (in flight / up next / shipped counts) and reordered the auto-generated zone to At a glance, Roadmap (Gantt), Cross-plan dependencies, In flight, Up next. Matches the read flow of the web status view. Hand-maintained sections (recently shipped, monthly log, backlog, blocked/risks) are unchanged and still outside the auto-generated markers.
- `docs/reference.md`: STATUS.md structure block and the auto-versus-hand-maintained source table updated to the new section order and the new `At a glance` section.
- `/plans` skill: `sync.md` Step 5 now lists the five auto-generated STATUS.md sections in regeneration order; Step 3 report text names all regenerated sections instead of only the two tables.
- `/plans` skill: `new-plan.md` "Up next" row template fixed to 5 columns (`Initiative | Why it matters | Effort | Depends on | Plan`); it previously emitted a 4-column row that did not match the table.
- `template/CLAUDE.md.snippet`: corrected frontmatter description from "8 fields" to "7 required fields plus an optional 8th (`in_flight`)", consistent with `docs/reference.md`.
- `examples/demo.svg`: animated SVG terminal demo added for README, showing `plans-init` output and a mini STATUS.md panel with Gantt bars.
- `docs/presentation.html`: outcome slide updated to show STATUS.md markdown format with a live link, replacing the colour panel mockup.
- README: status badges, demo SVG, screenshots, and the docs table added; GitHub Pages links repointed from the retired `examples/` paths to the `web/` deploy root.

### Earlier in this release

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

## v0.1.0 (original scope, never tagged)

The initial public scope. Never cut as a standalone tag; `0.2.0` is the
first numbered release. Kept here as a record of the original feature set:

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
