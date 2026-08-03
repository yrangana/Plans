# /plans init

Bootstrap `plans/` in the current project from the bundled template at `<this skill's directory>/template/plans/`. Works on every delivery.

## Prerequisites

**Existing installation check:**

```text
if plans/ exists in the project root:
  print: "plans/ already exists here. Nothing to bootstrap. Run sync to audit it,
          or update to refresh system files."
  stop.
```

## Steps

**1. Copy the template.** Copy `<this skill's directory>/template/plans/` to `./plans/` in the project root, preserving the directory structure exactly:

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

**2. Git exclusion.** Keeping `plans/` out of git is the user's decision, made by answering the question below. The only change taken on their behalf is appending the single line `plans/` to `.git/info/exclude`, git's per-clone local ignore file: never committed, never shared with collaborators, reversible by deleting that one line. No global git config is modified and nothing is executed against the repository. If the project is a git repository, ask exactly one question:

```text
"Track plans/ in git, or keep it local to this machine? (default: local)"
```

- **Local** (default):
  1. Attempt to append the line `plans/` to `.git/info/exclude`. Create the file if missing. Skip the append if the line is already present.
  2. Read `.git/info/exclude` back and confirm a line `plans/` is present.
  3. If confirmed, say so plainly: "plans/ is excluded via .git/info/exclude."
  4. If NOT confirmed (the write was blocked, deferred, or only printed for the user to run), do not claim success. Print a warning that cannot be mistaken for a completed action, for example:
     ```text
     WARNING: plans/ is NOT yet excluded from git.
     The write to .git/info/exclude did not go through.
     Run this yourself before committing anything in plans/:

       echo "plans/" >> .git/info/exclude

     Until you run it, plans/ will be picked up by git add / git commit.
     ```
- **Tracked**: change nothing. Confirm: "plans/ will be tracked in git."

If the project is not a git repository: skip the question, note "Not a git repository: skipped git exclusion."

**3. Instruction-file snippet (project-local deliveries only).** On the plugin delivery, skip this step entirely: the plugin's SessionStart hook already supplies these rules, and the plugin never edits instruction files.

```text
candidates = the files among CLAUDE.md, AGENTS.md, .cursorrules, .windsurfrules
             that exist in the project root

if no candidate exists:
  print:
    "No AI instruction file found. The plans rules snippet is bundled at:"
    "  <this skill's directory>/template/CLAUDE.md.snippet"
    "Append its body to your instruction file when you create one."
  continue to Step 4.

for each candidate file:
  if the file already contains the line "## Project Status & Plan Management":
    report "<file> already has the plans section." and continue to the next file.
  if /plans:plans is listed among the available skills in this session:
    ask: "Append the plans rules to <file>? The installed plugin already supplies
          these rules through its session hook, so skipping is fine. (y/N)"
  else:
    ask: "Append the plans rules section to <file>? (y/N)"
  on yes:
    append the snippet body to the end of the file: everything from the first
    "## " heading onward, skipping the leading HTML comment (the same rule
    scripts/init.sh uses). Then confirm the marker line is present in the file
    and report "Appended plans section to <file>."
  on no, or no clear answer:
    report "Skipped <file>."
```

Decline is the default. Never append without an explicit yes, and never append twice (the marker check guarantees this).

**4. Finish.**

If Local was chosen in Step 2 and the exclusion was NOT confirmed: do not print an unqualified success line. Lead with the unresolved warning, then the same next steps:

```text
WARNING: plans/ is NOT yet excluded from git. Run this before committing
anything in plans/:

  echo "plans/" >> .git/info/exclude

Next steps:
  1. Read plans/README.md
  2. Run {invocation} new to create your first plan
     (or edit plans/active/EXAMPLE_PLAN.md directly)
  3. Dashboard: run any static file server from the project root and open
     /plans/roadmap.html
```

Otherwise (exclusion confirmed, Tracked was chosen, or the project is not a git repository), print:

```text
plans/ is ready.

Next steps:
  1. Read plans/README.md
  2. Run {invocation} new to create your first plan
     (or edit plans/active/EXAMPLE_PLAN.md directly)
  3. Dashboard: run any static file server from the project root and open
     /plans/roadmap.html
```

where `{invocation}` is the spelling from the delivery rule in SKILL.md.

## Behaviour contract

- Never overwrites an existing `plans/`.
- Instruction files: on the plugin delivery, never touched. On project-local deliveries, appended only with explicit per-file consent, and never twice (marker guard).
- Asks at most one git question, only in a git repository.
- Copies the template verbatim; templates start empty by design.
- Makes no network requests.
