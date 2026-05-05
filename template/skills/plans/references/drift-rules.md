# Drift Detection Rules

Run all 9 rules. Collect all findings before reporting.

## Rule 1: Missing frontmatter field

**Check:** Each active plan has all 7 required fields: `status`, `priority`, `owner`, `type`, `depends_on`, `blocks`, `last_updated`.

**Flag:** List each missing field with expected type/values.

---

## Rule 2: Two-source disagreement

**Check:** Frontmatter `status` matches the `## Status` banner's Overall line.

| Frontmatter status | Expected banner indicator |
|---|---|
| `active` | In progress / Not started / Paused / Blocked |
| `shipped` | Done |
| `paused` | Paused |
| `blocked` | Blocked |
| `superseded` | any |

**Resolution:** Frontmatter wins. Propose updating the banner to match.

---

## Rule 3: Stale active plan

**Check:** Plan has `status: active` but no commits in the last 14 days that touch files plausibly related to that plan (match on plan filename stem or keywords from the plan title against commit messages and changed file paths).

**Flag:** "Active for Xd with no recent commits. Paused or abandoned?"

Do not auto-resolve. Ask the user.

---

## Rule 4: Stale last_updated

**Check:** An active plan has recent commits (within 7d) touching its domain, but `last_updated` in frontmatter is more than 7 days ago.

**Propose:** Bump `last_updated` to today's date in both frontmatter and banner.

---

## Rule 5: Unrecorded shipped phase

**Check:** Recent commits (since last STATUS.md update) contain messages that suggest a feature shipped (e.g. "merge", "complete", "ship", "done", "release", or a plan filename stem) but the corresponding plan phase is still marked Not started or In progress.

**Propose:** Mark the relevant phase as Done with today's date.

This is a heuristic. Present the matching commits so the user can confirm.

---

## Rule 6: Plan not in STATUS.md

**Check:** A file exists in `plans/active/` but has no corresponding row in the "In flight" or "Up next" tables in STATUS.md.

**Propose:** Add a row to the appropriate table based on `in_flight` field.

---

## Rule 7: Orphaned STATUS.md row

**Check:** A row exists in STATUS.md "In flight" or "Up next" tables but no matching file in `plans/active/`.

**Flag:** "Row exists in STATUS.md but no plan file found. Create the plan file or demote to backlog?"

Do not auto-resolve.

---

## Rule 8: Orphaned dependency edge

**Check:** Plan A has `depends_on: [B]` but plan B does not list `blocks: [A]`. Or vice versa.

**Propose:** Add the missing reverse edge to plan B's frontmatter.

---

## Rule 9: Dependency cycle

**Check:** BFS/DFS on the `depends_on` graph across all plans (active + shipped). Detect any cycle.

**Flag:** Print the cycle path (e.g. A → B → C → A).

Cannot auto-resolve. User must break the cycle manually.
