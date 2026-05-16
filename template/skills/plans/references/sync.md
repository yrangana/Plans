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

0. Version check: nudge if the skill is outdated (never blocks)
1. Read: collect current state from all sources
2. Detect: run all drift rules
3. Report: print findings grouped by severity
4. Regenerate: build new plans.json and STATUS.md auto-sections
5. Confirm: ask before writing anything
6. Apply: write only confirmed changes

---

## Step 0: Version check

A best-effort check that the installed skill is current. This step must never block sync.

1. Read the `version:` field from this skill's `SKILL.md` frontmatter (one directory up from this file).
2. Fetch the latest published version: `https://raw.githubusercontent.com/yrangana/Plans/main/VERSION` (short timeout).
3. Compare:
   - **Any failure** (offline, non-200, timeout, missing or unparseable version on either side): print nothing. Proceed to Step 1.
   - **Installed version is behind**: print one line, then proceed to Step 1:
     ```
     Note: plans skill v{installed} is installed, v{latest} is available.
           Run plans-update to upgrade, then re-run /plans sync.
     ```
   - **Installed version is current or ahead**: print nothing. Proceed to Step 1.

The check is informational only. It never aborts sync, never prompts, and never writes anything.

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
- Optional frontmatter fields if present: `start_date`, `eta`, `in_flight`
- `## Status` banner: Overall line, per-phase lines, Next action, Last updated

From `plans/plans.json`, also read the existing `project` header (`name`, `description`, `repo`) if present. It will be preserved verbatim in Step 4. If absent (legacy array shape or missing entirely), record this so Step 4 can stub it.

---

## Step 2: Detect Drift

Run all 13 rules from `drift-rules.md`. Collect every finding before reporting.

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
  STATUS.md  (auto-generated sections regenerated: At a glance, gantt, dependencies, In flight, Up next)
```

If nothing found: print `Everything is in sync.` and stop.

---

## Step 4: Regenerate plans.json

Build new `plans.json` as a top-level object `{ project, plans }` per `plans-json-schema.md`.

**Project header.** Preserve the existing `project` object verbatim from the current `plans.json` (read in Step 1). If the current file is missing the header (legacy array shape, missing object, or fresh project), create a stub `{"name": "", "description": "", "repo": ""}` and note it in the diff summary so the adopter sees it. Never overwrite non-empty project fields.

**Plans array.** Extract from all plan files (active + shipped). Superseded plans are excluded. Each entry follows the schema in `plans-json-schema.md`.

**Deriving `start_date` and `eta`.** These drive the `roadmap.html` Gantt, so resolve them on every regeneration:

- `start_date`: explicit frontmatter field if present; otherwise the earliest dated phase line in the banner; otherwise `last_updated`.
- `eta`: explicit frontmatter field if present; otherwise the latest dated/ETA phase line in the banner; otherwise leave `null`.

Do not invent dates that have no source. Plans with no `eta` and no dated phases are surfaced by Rule 10, not silently filled. Carry the keys through even when `null` so consumers can rely on their presence.

Show a one-line diff summary: `plans.json: N plans, X changed, Y added, Z removed` (append `, project header stubbed` if Rule 12 fired).

---

## Step 5: Regenerate STATUS.md auto-sections

Regenerate only the sections between the auto-generated markers:

```
<!-- AUTO-GENERATED from plans/plans.json -->
...
<!-- END AUTO-GENERATED -->
```

Inside the markers, regenerate these sections in this order:

1. `## At a glance` summary table: counts of in flight, up next, and shipped (last 30 days)
2. `## Roadmap at a glance` mermaid gantt
3. `## Cross-plan dependencies` mermaid flowchart
4. `## In flight: what we're working on now` table
5. `## Up next: committed for next 30 days` table

Leave everything outside those markers untouched (recently shipped, monthly log, backlog, blocked/risks).

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
