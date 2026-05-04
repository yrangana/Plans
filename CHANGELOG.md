# Changelog

All meaningful changes to the plans system are recorded here.

This project loosely follows [semantic versioning](https://semver.org/):

- **Major** version bumps for breaking changes to the plan file format, frontmatter spec, or directory layout (adopters must migrate).
- **Minor** version bumps for new features in `roadmap.html`, scripts, or docs (adopters can update or skip).
- **Patch** version bumps for bug fixes and small clarifications.

Versions are tagged on GitHub once meaningful changes accumulate. Until v1.0, the format is considered fluid.

---

## Unreleased

- `update.sh` auto-pulls the plans repo before applying updates (use `--no-pull` to skip)
- `install.sh` one-liner installer that clones the repo and symlinks `plans-init` / `plans-update` to `~/.local/bin/`
- `roadmap.html` derives page title from `STATUS.md` H1 (e.g. `# MyProject - Project Status` -> `MyProject - Roadmap`); adopters no longer need to manually edit the title
- `install.sh` URLs aligned to canonical `Plans` repo casing (was lowercase, now matches the GitHub repo name)
- `roadmap.html` derived title uses regular dash instead of em dash, consistent with the no-em-dash style convention
- `init.sh` auto-detects existing AI instruction files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`) and offers to append the plans snippet automatically. Idempotent: re-running skips files that already have the section. Use `--no-snippet` to opt out.

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
