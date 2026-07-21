# /plans init

Bootstrap `plans/` in the current project from the template bundled with the plugin, at `<plugin-root>/template/plans/`.

## Prerequisites

**1. Delivery check** (the delivery rule in SKILL.md):

```text
if STANDALONE delivery:
  print:
    "This skill copy has no bundled template. Bootstrap with the CLI instead:"
    ""
    "  curl -sSL https://raw.githubusercontent.com/yrangana/Plans/main/install.sh | bash"
    "  plans-init"
    ""
    "Or install the plugin: /plugin marketplace add yrangana/Plans"
  stop.
```

**2. Existing installation check:**

```text
if plans/ exists in the project root:
  print: "plans/ already exists here. Nothing to bootstrap. Run sync to audit it,
          or update to refresh system files."
  stop.
```

## Steps

**1. Copy the template.** Copy `<plugin-root>/template/plans/` to `./plans/` in the project root, preserving the directory structure exactly:

```text
plans/
  README.md
  STATUS.md
  plans.json
  roadmap.html
  active/        (contains EXAMPLE_PLAN.md)
  shipped/
  superseded/
```

Copy every file as-is. Do not edit, fill in, or personalize any of them.

**2. Git exclusion.** If the project is a git repository, ask exactly one question:

```text
"Track plans/ in git, or keep it local to this machine? (default: local)"
```

- **Local** (default): append the line `plans/` to `.git/info/exclude`. Create the file if missing. Skip the append if the line is already present.
- **Tracked**: change nothing. Confirm: "plans/ will be tracked in git."

If the project is not a git repository: skip the question, note "Not a git repository: skipped git exclusion."

**3. Finish.** Print:

```text
plans/ is ready.

Next steps:
  1. Read plans/README.md
  2. Run {invocation} new to create your first plan
     (or edit plans/active/EXAMPLE_PLAN.md directly)
  3. Dashboard: run any static file server from the project root and open
     /plans/roadmap.html
```

where `{invocation}` is the spelling from the delivery rule (`/plans:plans` here, since this mode only runs under BUNDLED delivery).

## Behaviour contract

- Never overwrites an existing `plans/`.
- Never appends to instruction files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`): the plugin itself is the assistant integration.
- Asks exactly one question, only in a git repository.
- Copies the template verbatim; templates start empty by design.
