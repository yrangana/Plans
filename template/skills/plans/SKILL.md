---
name: plans
version: 0.6.3
description: Manage the plans/ spec-driven planning system. Use `init` to bootstrap plans/ in a project, `sync` to audit drift between plan files and git, `new` to create a plan file, `update` to refresh system files. Invoked as /plans:plans (plugin) or /plans (project-local).
---

# /plans

Plans tracks what you are building in plain markdown: one file per feature with a seven-field spec, a `STATUS.md` front door, and a static `roadmap.html` that renders a Gantt chart and dependency graph with no server and no build step. Everything lives in your repo, so your assistant reads it like any other file.

Four modes. Invoke as `/plans:plans <mode>` (plugin install) or `/plans <mode>` (project-local install).

```text
init     bootstrap plans/ in this project from the bundled template
sync     audit plans/ for drift, regenerate derived files, propose fixes
new      guided creation of a new plan file with correct structure
update   refresh system files (roadmap.html, plans/README.md) from the installed version
```

If invoked with no argument or an unrecognized one, list the four modes and ask which is wanted.

## Bundled template

The bundled template lives at `<this SKILL.md's directory>/template/plans/`, and the instruction-file snippet at `<this SKILL.md's directory>/template/CLAUDE.md.snippet`. Every delivery of this skill carries both. No mode needs to locate anything outside this skill's own directory.

## Delivery detection

One distinction remains: plugin versus project-local. It determines the invocation spelling `{invocation}` used in messages, and whether `init` offers the instruction-file snippet. Determine it once, from the absolute path of this SKILL.md, in precedence order:

1. If the path contains a `.claude/skills` or `.agents/skills` component, this is a **project-local** delivery (installed by `scripts/init.sh` or `npx skills add`). Spelling: `/plans`. This rule wins even when an ancestor contains `.claude-plugin/plugin.json`, because a project may ship its own plugin while also carrying a project-local copy of this skill.
2. Otherwise, walk up from this file's directory; if any ancestor directly contains `.claude-plugin/plugin.json`, this is the **plugin** delivery (marketplace install, or a checkout loaded with `claude --plugin-dir`). Spelling: `/plans:plans`. Ambient rules come from the plugin's SessionStart hook.
3. Otherwise, treat it as project-local. Spelling: `/plans`.

## init

Bootstrap `plans/` in the current project. Full logic is in `references/init.md`. Load it now and follow it.

## sync

Audit `plans/` for drift between plan files and git reality. Regenerate derived files. Never write without confirmation. Full logic is in `references/sync.md`. Load it now and follow it.

## new

Guided creation of a new plan file. Guarantees correct format so sync does not immediately flag it. Full logic is in `references/new-plan.md`. Load it now and follow it.

## update

Refresh project system files from the installed skill version. Backs up before overwriting. Full logic is in `references/update.md`. Load it now and follow it.
