# /plans new

Guided creation of a new plan file with correct structure. Guarantees format correctness so `/plans sync` does not immediately flag it.

## Flow

Ask these questions in order. Do not proceed to the next until the current is answered.

**1. Plan name**

"What is the plan name? (becomes the filename in SCREAMING_SNAKE_CASE, e.g. AUTH_REFACTOR)"

Derive the filename: uppercase, spaces to underscores, strip special characters, append `.md`.

**2. Type**

"What type of work is this?"
- `feature`: new user-facing capability
- `bug`: defect fix
- `research`: investigation with no predetermined output
- `spike`: time-boxed technical exploration
- `plan`: meta-plan or coordination document

**3. Priority**

"What is the priority?"
- `P0`: critical, blocks everything
- `P1`: high, current focus
- `P2`: medium, next quarter
- `P3`: nice to have

**4. Dependencies**

"Does this depend on any other plans? Enter filenames without .md, comma-separated, or press enter for none."

Also ask: "Does anything block on this plan? Enter filenames, or press enter for none."

**5. Owner**

"Who owns this plan? (your username or name)"

---

## Generate the file

Write `plans/active/NAME.md` with this exact structure:

```markdown
---
status: active
priority: {P0|P1|P2|P3}
owner: {owner}
type: {feature|bug|research|spike|plan}
depends_on: [{depends_on list, or []}]
blocks: [{blocks list, or []}]
last_updated: {today YYYY-MM-DD}
---

# Plan: {Human-readable title}

## Status

- **Overall:** Not started
- **Phase 0 ({First phase name}):** Not started
- **Phase 1 ({Second phase name}):** Not started

**Next action:** {First concrete step to take.}
**Last updated:** {today YYYY-MM-DD}

---

## Context

{Why this work is needed. What problem it solves.}

## Goals

- {Goal 1}

## Non-goals

- {What is explicitly out of scope}

## Phases

### Phase 0: {Name}

{What this phase covers}

### Phase 1: {Name}

{What this phase covers}

## Notes

{Implementation notes, open questions, links to relevant code or PRs}
```

Fill in today's date for `last_updated`. Leave placeholder text in context/goals/phases for the user to fill in.

---

## After creating the file

Print:

```
Created plans/active/{NAME}.md

Next steps:
  1. Fill in the Context, Goals, and Phases sections
  2. Add a row to plans/STATUS.md "Up next" table:
     | [{Title}](active/{NAME}.md) | {type} | {priority} | {eta or TBD} |
  3. Set in_flight: true in frontmatter when work actually starts
```

Do not create the STATUS.md row. That is the user's responsibility.
Do not set `in_flight: true`. The user sets that when work starts.
