---
name: plans
version: 0.4.0
description: Manage the plans/ spec-driven planning system. Use `init` to bootstrap plans/ in a project, `sync` to audit drift between plan files and git, `new` to create a plan file, `update` to refresh system files. Invoked as /plans:plans (plugin) or /plans (project-local).
---

# /plans

Four modes. Invoke as `/plans:plans <mode>` (plugin install) or `/plans <mode>` (project-local install).

```text
init     bootstrap plans/ in this project from the bundled template
sync     audit plans/ for drift, regenerate derived files, propose fixes
new      guided creation of a new plan file with correct structure
update   refresh system files (roadmap.html, plans/README.md) from the installed version
```

If invoked with no argument or an unrecognized one, list the four modes and ask which is wanted.

## Delivery detection

Every mode needs to know how this skill was delivered. Determine it once, from the absolute path of this SKILL.md:

- Path contains `/plugins/cache/`: **plugin** delivery. The plugin root is the ancestor directory that directly contains `template/`. The bundled template is at `<plugin-root>/template/plans/`. Invocation spelling for messages: `/plans:plans`.
- Otherwise (under `.claude/skills/` or `.agents/skills/` in a project): **project-local** delivery. There is no bundled template. Invocation spelling for messages: `/plans`.

## init

Bootstrap `plans/` in the current project. Full logic is in `references/init.md`. Load it now and follow it.

## sync

Audit `plans/` for drift between plan files and git reality. Regenerate derived files. Never write without confirmation. Full logic is in `references/sync.md`. Load it now and follow it.

## new

Guided creation of a new plan file. Guarantees correct format so sync does not immediately flag it. Full logic is in `references/new-plan.md`. Load it now and follow it.

## update

Refresh project system files from the installed skill version. Backs up before overwriting. Full logic is in `references/update.md`. Load it now and follow it.
