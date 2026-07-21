# /plans update

Refresh project system files from the template bundled with the installed plugin, so they always match the plugin version. Same contract as the `plans-update` script: system files only, prompt before writing, back up first.

## Prerequisites

**1. Delivery check** (the delivery rule in SKILL.md):

```text
if PROJECT-LOCAL delivery:
  print: "This skill copy has no bundled template. Use the plans-update script instead."
  stop.
```

**2. Installation check:**

```text
if plans/ does not exist in the project root:
  print: "No plans/ directory found. Run /plans:plans init first."
  stop.
```

## System files vs user data

| Category | Files | Behavior |
| --- | --- | --- |
| System files | `plans/roadmap.html`, `plans/README.md` | Updated by this mode, with a `.bak` backup |
| User data | `plans/STATUS.md`, `plans/plans.json`, `active/`, `shipped/`, `superseded/`, anything else | Never touched by this mode |

## Steps

**1. Diff.** For each system file, compare the project copy against `<plugin-root>/template/plans/<file>`:

- Identical: report `= plans/<file> (already up to date)`.
- Different: report `~ plans/<file> (update available)` and show a short summary of what changed (first ~40 lines of a unified diff is enough).
- Missing from the project: report `+ plans/<file> (missing, will be restored)`.

**2. Confirm per file.** For each file with a change: ask "Update plans/<file>? (y/n)". Never batch-apply without asking.

**3. Apply.** For each confirmed file: copy the existing project file to `plans/<file>.bak` (skip the backup if the project file is missing), then copy the template file over it. Report each write.

**4. Finish.** If nothing changed: print "System files match the installed plugin version." Otherwise remind: "If you had customized roadmap.html (for example colors), restore from the .bak file."

## Behaviour contract

- Never touches user data (the table above is exhaustive).
- Never writes without per-file confirmation.
- Always writes a `.bak` before overwriting an existing file.
- Updates to exactly the installed plugin's version, never from the network.
