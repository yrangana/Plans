# /plans sync

Audit `plans/` for drift, regenerate derived files, propose fixes. Never write without confirmation.

## Prerequisites

**1. Check for `plans/`:**

```
if plans/ does not exist in the project root:
  print:
    "No plans/ directory found in this project."
    "Set it up with:"
    ""
    "  curl -sSL https://raw.githubusercontent.com/yrangana/Plans/main/install.sh | bash"
    "  plans-init"
    ""
    "Or visit https://github.com/yrangana/Plans for full instructions."
  stop.
```

**2. Check required files:**

```
if plans/STATUS.md is missing:
  print: "plans/STATUS.md not found. Re-run plans-init or check https://github.com/yrangana/Plans"
  stop.

if plans/active/ does not exist:
  print: "plans/active/ not found. Nothing to audit."
  stop.
```

**3. Check for git:**

```
if git is not available or not a git repo:
  print: "Git not available. Skipping commit-based drift detection. Frontmatter validation will still run."
  proceed without git-based rules (Rules 3, 4, 5).
```

---

## Run Order

1. Read: collect current state from all sources
2. Detect: run all drift rules
3. Report: print findings grouped by severity
4. Regenerate: build new plans.json and STATUS.md auto-sections
5. Confirm: ask before writing anything
6. Apply: write only confirmed changes

---

## Step 1: Read

```
plans/STATUS.md          (extract last-updated date from line 2: *Last updated: YYYY-MM-DD*)
plans/active/*.md        (extract frontmatter + ## Status banner from each file)
plans/shipped/*.md       (extract frontmatter only, for dependency validation)
plans/superseded/*.md    (extract frontmatter only, for dependency validation)
plans/plans.json         (current snapshot, compare against what you will regenerate)
git log --oneline --since="{last STATUS.md date}"  (commits since last sync)
```

For each active plan, parse:
- All 7 frontmatter fields: `status`, `priority`, `owner`, `type`, `depends_on`, `blocks`, `last_updated`
- `## Status` banner: Overall line, per-phase lines, Next action, Last updated

---

## Step 2: Detect Drift

Run all 9 rules from `drift-rules.md`. Collect every finding before reporting.

---

## Step 3: Report

```
=== /plans sync findings ===

ERRORS (must fix):
  [plan file] missing frontmatter field: `priority`
  [plan file] two-source disagreement: frontmatter=active, banner=shipped

WARNINGS (review needed):
  [plan file] stale: active for 18d with no recent commits. Paused or abandoned?
  STATUS.md row "Feature X" has no matching plan file in plans/active/

PROPOSED UPDATES:
  plans.json (regenerated from current frontmatter, N plans)
  STATUS.md  (In flight / Up next tables updated)
```

If nothing found: print `Everything is in sync.` and stop.

---

## Step 4: Regenerate plans.json

Build new `plans.json` by extracting from all plan files (active + shipped). Superseded plans are excluded.
Each entry follows the schema in `plans-json-schema.md`.

Show a one-line diff summary: `plans.json: N plans, X changed, Y added, Z removed`

---

## Step 5: Regenerate STATUS.md auto-sections

Regenerate only the sections between the auto-generated markers:

```
<!-- AUTO-GENERATED from plans/plans.json -->
...
<!-- END AUTO-GENERATED -->
```

Leave everything outside those markers untouched (monthly log, backlog, blocked/risks).

Show a summary of what changed in each table.

---

## Step 6: Confirm and Apply

```
Apply these changes? (y/n/select)
  y      apply all
  n      apply nothing
  select choose per file
```

Apply only confirmed changes. Report each file written.

---

## Behaviour Contract

- Proposal-only: never write without confirmation
- Frontmatter wins over banner on any conflict
- Flag dependency cycles (cannot auto-resolve)
- If `plans/` is empty or has no active plans, report that and stop cleanly
- If git is unavailable, skip git-based rules and note it in the report
