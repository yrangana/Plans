---
name: plans
version: 0.2.1
description: Manage the plans/ spec-driven planning system. Use `/plans sync` to audit drift between plan files and git, regenerate plans.json and STATUS.md. Use `/plans new` to create a correctly structured plan file.
---

# /plans

Two modes. Invoke as `/plans sync` or `/plans new`.

```
/plans sync   audit plans/ for drift, regenerate derived files, propose fixes
/plans new    guided creation of a new plan file with correct structure
```

If invoked as `/plans` with no argument, ask: "Did you mean `/plans sync` or `/plans new`?"

---

## /plans sync

Audit `plans/` for drift between plan files and git reality. Regenerate derived files. Never write without confirmation.

Full logic is in `references/sync.md`. Load it now and follow it.

---

## /plans new

Guided creation of a new plan file. Guarantees correct format so `/plans sync` does not immediately flag it.

Full logic is in `references/new-plan.md`. Load it now and follow it.
