# Changelog

All meaningful changes to the plans system are recorded here.

This project loosely follows [semantic versioning](https://semver.org/):

- **Major** version bumps for breaking changes to the plan file format, frontmatter spec, or directory layout (adopters must migrate).
- **Minor** version bumps for new features in `roadmap.html`, scripts, or docs (adopters can update or skip).
- **Patch** version bumps for bug fixes and small clarifications.

Versions are tagged on GitHub once meaningful changes accumulate. Until v1.0, the format is considered fluid.

---

## v0.7.0

Makes the skill package self-sufficient. The project template and the instruction-file snippet now ship inside the skill directory (`template/skills/plans/template/`), so every delivery can bootstrap a project: the Claude Code plugin, the scripts, and `npx skills add yrangana/Plans`, which installs the skill on roughly 70 assistants and previously could not create `plans/` at all.

- Template moved: `template/plans/` and `template/CLAUDE.md.snippet` now live under `template/skills/plans/template/`. The old locations are deleted. Both scripts repoint; `scripts/init.sh` decouples its skill-source path from its template-source path, which the naive repoint would have silently broken.
- Delivery detection rewritten: the walk-up rule and the BUNDLED/STANDALONE distinction are deleted. The template location is a constant relative to SKILL.md. The remaining plugin versus project-local test is precedence-ordered so a project shipping its own plugin cannot misclassify a project-local copy.
- `init` works on every delivery and, on project-local deliveries only, offers to append the rules snippet to a detected instruction file (explicit per-file consent, marker guard against double appends, skip is the default when the plugin is also installed). The plugin delivery still never touches instruction files.
- `sync` Step 0 no longer fetches VERSION from raw.githubusercontent.com. Every delivery compares system files against the bundled template instead. The skill now makes zero runtime network requests on every path.
- `update` works on every delivery; its STANDALONE refusal is deleted.
- README, docs/reference.md, and the website lead the non-Claude-Code path with `npx skills add`; the curl scripts remain supported as a fallback, including the inspect-first variant.
- web/privacy.html covers three install paths and drops the sync version-check disclosure, because the check no longer exists.
- New maintenance invariant in CLAUDE.md: files under `template/skills/plans/` are add-only across releases, because `update_skill`'s copy-over cannot delete orphans in adopter projects.

---

## v0.6.3

Presentation fixes prompted by the skill's page going live on skills.sh, which renders SKILL.md to browsers rather than only to models.

- `template/skills/plans/SKILL.md`: adds a two-sentence opening after the `# /plans` heading describing what Plans actually is. The visible portion of the skills.sh page previously ran straight from the install command into "Four modes" and then the delivery-detection algorithm, so a human visitor read invocation syntax and directory-walking logic without ever learning what the skill is for. The `description:` frontmatter carries that explanation but appears only as a search blurb and meta tag, not in the page body. Costs roughly 60 tokens per invocation and grounds the domain before the modes are listed.
- `README.md`: adds a download-and-read alternative beside the piped installer under Quick Start. v0.6.2 redirected the skill's STANDALONE messages here rather than printing `curl ... | bash` themselves, so this is where that chain now terminates; it should not terminate in piping an unread script. The one-liner is unchanged and still first.

Deliberately unchanged: the `description:` frontmatter, which exists to tell a model when to invoke the skill and should not be rewritten as directory copy. Also unchanged are the piped-install commands in `web/index.html`, `web/presentation.html`, `docs/blog-post.md`, and `docs/reference.md`. Those are read by humans who choose whether to run them, which is the pattern rustup, Homebrew, and bun all ship; the audit finding was specifically about instructions an agent can execute unattended.

---

## v0.6.2

Removes the piped-shell install command from the skill's instructions, after the skills.sh listing published a failing Snyk audit against it.

- `template/skills/plans/references/init.md`, `sync.md`, `new-plan.md`: the STANDALONE messages no longer print `curl -sSL .../install.sh | bash`. They point at `https://github.com/yrangana/Plans#quick-start` instead. Snyk flagged the piped form as **E005, CRITICAL** ("suspicious download URL detected in skill instructions"), and the finding is fair: instructing a user to pipe a remote script straight into a shell is a poor pattern regardless of the audit. `install.sh` itself is unchanged and still supported; only the skill's recommendation of the piped invocation is gone.
- `template/skills/plans/references/init.md`: the STANDALONE message now checks whether `/plans:plans` is present among the session's available skills and, if so, says to run `/plans:plans init` rather than installing anything. Found by running the v0.6.1 message on a machine that had both a plugin copy and a skills.sh copy installed: the old text told the user to install a plugin that was already there.

Known and accepted: Snyk also reports **W011, MEDIUM** (indirect prompt injection) because the skill reads `plans/STATUS.md` and `plans/active/*.md` into context. That is inherent to what the skill does and is not being changed. `sync.md` still fetches `VERSION` from `raw.githubusercontent.com` for the staleness check; it is a plain-text read rather than a piped script, and it remains disclosed in the privacy policy.

Neither update path is affected. `update.md` never referenced the install script, and `scripts/update.sh` copies the skill directory wholesale without parsing message text, so script-path adopters receive the corrected instructions on their next `plans-update`.

---

## v0.6.1

Fixes install advice given to users who are not on Claude Code. The skill is installable via `npx skills add yrangana/Plans`, which serves roughly 70 assistants and delivers the skill without the bundled template, so it lands in STANDALONE mode. Two messages on that path were wrong: one recommended a Claude Code command to everyone, and all three recommended a remedy that silently produces a duplicate skill copy.

- `template/skills/plans/references/init.md`: the STANDALONE message now branches on the assistant rather than presenting `/plugin marketplace add` as an afterthought to every user. `/plugin marketplace add yrangana/Plans` is labelled as the Claude Code route; the install script is labelled as the route for every other assistant. Previously a Cursor or Windsurf user was shown a command that does not exist in their editor.
- `template/skills/plans/references/init.md`, `sync.md`, `new-plan.md`: all three recommend `plans-init` to STANDALONE users, and `plans-init` installs its own copy of the skill alongside the one already present. That leaves two copies with separate update paths, which is the outcome the skills.sh delivery decision was meant to avoid. Each message now says so and points at `npx skills remove plans` as the way to avoid it.

No logic, modes, or file layout changed. Adopters on the plugin and script paths are unaffected: both are BUNDLED, and none of these messages fire for them.

---

## v0.6.0

Closes a gap between the two adoption paths. On the script path, `scripts/init.sh` appends `template/CLAUDE.md.snippet` to the user's CLAUDE.md, and that snippet carries ambient operational rules (write plans only into `plans/active/`, never hand-edit `plans/plans.json`, update a plan's status banner before ending a session that touched its code, read `plans/STATUS.md` at session start) that apply even when the skill is never invoked. The plugin path had no equivalent: skills only load on invocation, so plugin users silently lost all of those rules unless they happened to run `/plans:plans`.

- `hooks/plans-context.sh`: new. A `SessionStart` hook that prints `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}` on stdout, carrying a condensed version of the snippet's non-deferrable rules (including the drift-audit rule, so the hook payload and the snippet carry the same four rules). Guarded on `${CLAUDE_PROJECT_DIR:-.}/plans` rather than the process working directory, since a `SessionStart` hook can run from any cwd: without that guard, a subdirectory session would silently lose the rules, and an unrelated directory that happens to contain a `plans/` folder would get them injected, which is the context pollution the guard exists to prevent. Exits 0 always, emits nothing when the guard fails, never prompts or writes. Shebang is `#!/bin/sh`; the script is POSIX-clean and needs nothing from bash.
- `hooks/hooks.json`: new. Registers the hook for `SessionStart` with matcher `"startup|resume|clear|compact"`, so the rules are injected on a fresh session, on `--resume`/`--continue`/`/resume`, on `/clear`, and on both manual and automatic compaction. Invoked via `"\"${CLAUDE_PLUGIN_ROOT}\"/hooks/plans-context.sh"` (quoted, matching the official docs, so a plugin cache path containing a space does not break the command).
- `.claude-plugin/plugin.json`: adds `"hooks": "./hooks/hooks.json"`.
- `hookSpecificOutput.additionalContext` is a documented, supported mechanism: Claude Code's official hooks reference states the string is wrapped in a system reminder and inserted into the model's context at the point the hook fires, capped at 10,000 characters. The current payload is about 760 characters, well within that cap.
- Script path unchanged: `scripts/init.sh`, `scripts/update.sh`, and `template/CLAUDE.md.snippet` are untouched. Script-path adopters keep getting the equivalent rules through the snippet already appended to their CLAUDE.md.
- `docs/reference.md`: documents the hook in the plugin section, what it injects, the project-root guard, the four matchers, and the script-path equivalent, plus the both-installed case (plugin hook and script-path snippet both present: duplicated but consistent, and harmless).

## v0.5.0

Makes the Claude Code plugin the primary, self-sufficient adoption path. The skill gains `init` and `update` modes, so a plugin install alone now delivers a working system. v0.4.0 shipped the plugin as a pointer to the CLI; this release removes that dependency. Scripts remain the documented fallback for Cursor, Antigravity, Windsurf, and no-plugin setups.

- `template/skills/plans/SKILL.md`: four-mode router (`init`, `sync`, `new`, `update`) with a shared delivery-detection rule. Plugin installs are invoked `/plans:plans <mode>`, project-local installs stay `/plans <mode>`.
- `references/init.md`: new. Bootstraps `plans/` from the bundled template, asks one question (track in git or keep local, default local), never appends to instruction files. Project-local copies point at `plans-init` instead.
- `references/init.md`: the git-exclusion step now confirms the `.git/info/exclude` write actually landed by reading the file back, instead of assuming it succeeded. If the write did not go through, it warns explicitly and prints the exact command (`echo "plans/" >> .git/info/exclude`) to run manually, and the finish step leads with that warning instead of an unqualified success line.
- `references/update.md`: new. Refreshes `plans/roadmap.html` and `plans/README.md` from the installed plugin's bundled template with per-file confirmation and `.bak` backups. Same contract as `plans-update`, sourced from the installed version instead of the network.
- `references/sync.md`: Step 0 is delivery-aware. Plugin copies check system-file freshness against the bundled template and suggest the update mode; project-local copies keep the GitHub VERSION check and suggest `plans-update`.
- `references/new-plan.md`: the missing `plans/` check stays delivery-aware (`/plans:plans init` vs `plans-init`); the missing `plans/active/` check is not, since neither delivery path has a command that restores just that one directory.
- Fixes two remediation messages that told users to run commands incapable of fixing the stated problem. `references/new-plan.md`: missing `plans/active/` now says `mkdir -p plans/active` instead of pointing at init or update, both of which refuse when `plans/` already exists. `references/sync.md`: missing `plans/STATUS.md` now says no command restores it (it is user data, not a system file) and points at version control instead of re-running init or update, which never touch it. The `sync.md` case is a bug fix: the old message shipped in v0.4.0 and earlier.
- Docs: README Quick Start and the site lead with the plugin; the script path moves to an "Other assistants" section. `docs/reference.md` documents all four modes and both delivery paths.
- Data format unchanged. `scripts/init.sh` and `scripts/update.sh` behavior unchanged from v0.4.0. Adopters on the script path are unaffected.

## v0.4.0

Packages the `/plans` skill as a Claude Code plugin so it is discoverable through `/plugin` without cloning the repo first. This is a discovery entry point, not a second way to adopt the system: the plugin delivers the skill and nothing else, and `plans-init` remains the only path that creates `plans/`.

- `.claude-plugin/plugin.json`: new. Exposes the skill via `"skills": "./template/skills/"`. That field adds to the default scan rather than replacing it, so the skill file stays at `template/skills/plans/` and `scripts/init.sh` is unchanged.
- `.claude-plugin/marketplace.json`: new. Declares the `yrangana-plans` marketplace with the plugin sourced from the repo root, so `/plugin marketplace add yrangana/Plans` works directly against GitHub.
- `template/skills/plans/references/new-plan.md`: adds the prerequisites block that `sync.md` already had. `/plans new` previously ran the full five-question flow in projects with no `plans/` directory, then failed at write time. It now checks for `plans/` and `plans/active/` first and stops with setup instructions.
- `scripts/update.sh`: when no project-local skill is found, prints a note that a plugin-installed copy is managed by Claude Code and is not updated by `plans-update`. Previously reported "Nothing to update. You are current," which was wrong for plugin users.
- `docs/reference.md`: documents the plugin install, and which of the two paths owns updates.
- `CLAUDE.md`: release process now covers three version fields, and adds a warning about distributing the plugin from a local working tree.
- Adopters on `plans-init` are unaffected. No schema, path, or `plans.json` change.

## v0.3.3

Makes `roadmap.html` order plans by recency, not priority. v0.3.2 used `last_updated` only as a tiebreaker *after* priority, so a recently shipped P1 still sank below older P0s and the Shipped filter did not read newest-first. This supersedes that ordering.

- `template/plans/roadmap.html`: `sortPlans` drops priority as a sort key. Order is now in-flight first, then status (active, paused, blocked, shipped, superseded), then `last_updated` descending within each status group (missing dates last). Priority still shows on each card but no longer affects order.
- Effect: the Shipped filter reads as a newest-first changelog (most recently shipped at the top), and a recent lower-priority plan is never buried under an older P0. Applies to both the plan list and the Gantt row order.
- `docs/reference.md`: the "Dashboard rendering" subsection now documents the ordering rule.
- No schema or `plans.json` change. Adopters pick it up on the next `plans-update`.

## v0.3.2

Fixes plan ordering in `roadmap.html`. Plans that shared an `in_flight` state, status, and priority fell back to `plans.json` insertion order (effectively filename order), so within a bucket the plan list and Gantt rows ignored recency.

- `template/plans/roadmap.html`: `sortPlans` now adds `last_updated` (descending, newest first) as the final tiebreaker, after `in_flight`, status, and priority. Plans with no `last_updated` sort last. Applies to both the plan list and the Gantt row order.
- Priority still groups above recency within a status (all P0s before P1s, each group newest-first); recency only breaks ties inside a bucket.
- No schema or `plans.json` change. Adopters pick it up on the next `plans-update`.

## v0.3.1

Keeps `roadmap.html` readable as shipped history accumulates. Previously the Gantt drew every plan ever recorded and the plan list rendered all of them on load, so a project a year in would show a year-wide axis with one row per shipped plan and dump the full set by default.

- `template/plans/roadmap.html`: the Gantt now uses a 6-week rolling window (`GANTT_WINDOW_DAYS = 42`). Active plans always appear; plans shipped more than 6 weeks ago drop off the chart. They stay reachable in the plan list under the Shipped filter, and the filter counts still reflect the full set.
- `template/plans/roadmap.html`: the "All plans" list now opens on the Active filter instead of All. The All and Shipped filters are one click away.
- `docs/reference.md`: new "Dashboard rendering (roadmap.html)" subsection documenting both rules. Both behaviours are fixed (no config); adopters who want a different cutoff fork `roadmap.html`.
- `web/roadmap.html` (marketing snapshot) is intentionally unchanged: its `today` is the real current date while its inline data is frozen, so a rolling window would empty the demo Gantt as wall-clock time advances past mid-June.
- No schema or `plans.json` change. Adopters pick it up on the next `plans-update`; nothing to migrate.

## v0.3.0

Adds a `project` header to `plans.json` so each file is self-describing: a foundation for a future centralised dashboard that aggregates `plans.json` across multiple projects.

- `plans.json` shape changes from a top-level array to a top-level object: `{ project, plans }`. The `project` header has three fields: `name`, `description`, `repo`. All three are required; empty strings are allowed as stubs.
- `template/plans/plans.json` ships with an empty project stub so a fresh install has the right shape from day one.
- `template/plans/roadmap.html`: reads the new shape, uses `project.name` for the page title, falls back to parsing `STATUS.md` only if `project.name` is empty. Renders `data.plans` instead of the top-level array.
- `/plans sync`: two new drift rules (now 13 total). Rule 12 auto-creates a `{"name":"","description":"","repo":""}` stub when `plans.json` is missing the header (legacy array shape or fresh project). Rule 13 flags empty project fields so the adopter is reminded to fill them in. Step 1 reads the existing project header; Step 4 preserves it verbatim across regenerations and never overwrites non-empty values.
- `plans-json-schema.md`, `sync.md`, `drift-rules.md`, `docs/reference.md`: schema and behaviour spec rewritten for the wrapper-object shape.
- Migration for existing adopters: no manual step. Next `plans-update` brings in the new `roadmap.html` and skill; next `/plans sync` auto-stubs the project header and prints a note. Adopters then fill in the three fields in `plans.json` (or wait for sync to flag them via Rule 13).
- `web/roadmap.html` (marketing snapshot) is intentionally unchanged for this release: it has no `plans.json` and uses an inline `PLANS` array. A future release may align its title bar to the project-name pattern.

## v0.2.2

- `template/CLAUDE.md.snippet` restructured into a thin, load-bearing summary that defers to `plans/README.md` for the full convention. The snippet is pasted once into each adopter's CLAUDE.md and is not refreshed by `plans-update`, so it now carries only the rules an assistant could violate without having loaded `plans/README.md`: write plans only in `plans/active/`, never hand-edit `plans.json`, update plans before ending a session, audit drift with `/plans sync`. Frontmatter spec, two-source rule, lifecycle, and file moves are no longer duplicated in the snippet; they live in `plans/README.md`, which `plans-update` refreshes.
- New rule (added to both the snippet and `plans/README.md` Quick Rules): plan files must not be saved to AI assistant scratch or memory directories (`~/.claude/`, `~/.cursor/`, `.agents/`, `.windsurf/`, or equivalent), to plan-mode artifacts, or to loose files at the repo root. Closes a real gap where assistants defaulted to internal plan-mode scratch instead of `plans/active/`.
- `template/plans/README.md` Quick Rules: end-of-session plan-update mandate promoted from snippet-only to a Quick Rule, so it lives in the system-managed file that `plans-update` refreshes, not only in the per-adopter snippet.
- Existing adopters keep their old snippet (no auto-update path). Re-paste from `template/CLAUDE.md.snippet` to pick up the slimmer version; `plans/README.md` updates arrive automatically on the next `plans-update`.

## v0.2.1

Fixes the half-wired temporal data path. `roadmap.html` already consumed `start_date` and `eta`, and the schema already documented them, but nothing captured, derived, or enforced those fields. The result was a Gantt where every bar collapsed to a zero-width point on `last_updated`.

- `/plans new`: added a Timeline step. `start_date` is captured (press enter for today) and written to frontmatter; effort is asked as a day count and resolved to an absolute `eta: YYYY-MM-DD`. Skipping the effort estimate omits the `eta` line, which a later `/plans sync` then flags.
- `/plans sync`: `start_date` and `eta` are now explicitly derived during `plans.json` regeneration (`sync.md` Step 4) — frontmatter field first, then dated phase lines, then a documented fallback. The keys are always carried through, `null` when unresolved, so consumers can rely on their presence.
- `/plans sync`: two new drift rules (now 11 total). Rule 10 flags an active plan with no `eta` and no dated phases (the Gantt cannot draw a real span). Rule 11 proposes rolling a past `start_date` forward to today on an unstarted `active` plan, sliding any `eta` by the same delta so the planned span length is preserved; future `start_date`s and `blocked`/`paused` plans are left alone.
- `plans-json-schema.md`: `start_date` and `eta` source rows rewritten to spell out the full fallback chain.
- `template/plans/roadmap.html`: `renderGantt` gained a `planSpan` helper that degrades gracefully when a plan has no dates — derives a span from phase dates, then status (`shipped` → `last_updated`, in-flight → today), and guarantees a minimum visible width so a bar never inverts or vanishes. Belt-and-suspenders alongside the skill-side fix, so plans created before this release still render sanely.
- `template/plans/active/EXAMPLE_PLAN.md`: frontmatter gained `start_date` and `eta`, and the Phase 1 banner line carries an ETA, so a fresh install demonstrates the dated-plan convention and `/plans sync` reproduces the shipped `plans.json` dates.
- `docs/reference.md`, `template/plans/README.md`: frontmatter spec, `plans.json` field reference, and the drift-rule table updated for the two date fields and Rules 10 and 11.

## v0.2.0

- `VERSION` file added at the repo root: single source of truth for the released version, starting at `0.2.0`. `template/skills/plans/SKILL.md` carries a matching `version:` field so an installed skill is self-identifying.
- `/plans sync` gained a Step 0 version check: on each run it reads its own skill version and fetches the published `VERSION` from GitHub, printing a one-line nudge to run `plans-update` if the skill is behind. The check is best-effort and never blocks: any network failure (offline, timeout, non-200) is silent and sync proceeds normally.
- `plans-update`: after a successful skill update, prints the new skill version and reminds the user to run `/plans sync` to apply any STATUS.md structure changes.
- `template/plans/roadmap.html`: rebuilt on the deployed `web/roadmap.html` design (metric strip, Gantt with date axis and today line, dependency block-chains, plan list with phase dots and progress bars, sidebar legend). Keeps the `plans.json` / `STATUS.md` fetch layer and the `file://` error state. Drops the vis.js dependency: the dependency view is now static block-chains instead of a force-directed graph. The deployed demo (`web/`) and the adopter template no longer share a build, so this brings adopters to visual parity with the demo.
- `template/plans/roadmap.html`: STATUS.md title regex now matches the canonical `# {Project}: Project Status` colon format (also accepts dash and en dash). Previously expected only a dash, so the page title never resolved against the shipped STATUS.md template.
- `template/plans/STATUS.md`: added an `## At a glance` summary table (in flight / up next / shipped counts) and reordered the auto-generated zone to At a glance, Roadmap (Gantt), Cross-plan dependencies, In flight, Up next. Matches the read flow of the web status view. Hand-maintained sections (recently shipped, monthly log, backlog, blocked/risks) are unchanged and still outside the auto-generated markers.
- `docs/reference.md`: STATUS.md structure block and the auto-versus-hand-maintained source table updated to the new section order and the new `At a glance` section.
- `/plans` skill: `sync.md` Step 5 now lists the five auto-generated STATUS.md sections in regeneration order; Step 3 report text names all regenerated sections instead of only the two tables.
- `/plans` skill: `new-plan.md` "Up next" row template fixed to 5 columns (`Initiative | Why it matters | Effort | Depends on | Plan`); it previously emitted a 4-column row that did not match the table.
- `template/CLAUDE.md.snippet`: corrected frontmatter description from "8 fields" to "7 required fields plus an optional 8th (`in_flight`)", consistent with `docs/reference.md`.
- `examples/demo.svg`: animated SVG terminal demo added for README, showing `plans-init` output and a mini STATUS.md panel with Gantt bars.
- `docs/presentation.html`: outcome slide updated to show STATUS.md markdown format with a live link, replacing the colour panel mockup.
- README: status badges, demo SVG, screenshots, and the docs table added; GitHub Pages links repointed from the retired `examples/` paths to the `web/` deploy root.

### Earlier in this release

- `update.sh` auto-pulls the plans repo before applying updates (use `--no-pull` to skip)
- `install.sh` one-liner installer that clones the repo and symlinks `plans-init` / `plans-update` to `~/.local/bin/`
- `roadmap.html` derives page title from `STATUS.md` H1 (e.g. `# MyProject - Project Status` -> `MyProject - Roadmap`); adopters no longer need to manually edit the title
- `install.sh` URLs aligned to canonical `Plans` repo casing (was lowercase, now matches the GitHub repo name)
- `roadmap.html` derived title uses regular dash instead of em dash, consistent with the no-em-dash style convention
- `init.sh` auto-detects existing AI instruction files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`) and offers to append the plans snippet automatically. Idempotent: re-running skips files that already have the section. Use `--no-snippet` to opt out.
- `init.sh` and `update.sh`: fixed symlink resolution bug — scripts now work correctly when invoked via symlinks in `~/.local/bin/` (was resolving to symlink directory instead of real script location)
- `init.sh`: when no AI instruction file is detected, prints the snippet content inline instead of a path to the installed clone
- `roadmap.html`, `init.sh`, README: server options expanded to Python 3, Node.js (`npx serve`), and PHP (was Python-only)
- `plans/README.md` added to system files managed by `plans-update` (was user data, now updated on `plans-update` like `roadmap.html`)
- Skill renamed from `/status-sync` to `/plans-sync` throughout docs for consistency with `plans-init` / `plans-update` naming
- Uninstall instructions added to README
- `plans/superseded/` directory added to the convention: plans replaced by a different approach move here (distinct from `shipped/`, which means the work is done). `template/`, `template/CLAUDE.md.snippet`, all docs, and `update.sh` updated accordingly.
- `/plans` skill built at `template/skills/plans/` with two modes: `/plans sync` (weekly drift audit: reads frontmatter + banners, cross-references git log, regenerates `plans.json` and `STATUS.md` auto-sections, proposes diff before writing) and `/plans new` (guided creation of a correctly structured plan file). Replaces the earlier single-mode `/plans-sync` skill.
- `plans-init` now installs the `/plans` skill to the correct platform directory: `.agents/skills/plans/` for `AGENTS.md` projects (Antigravity), `.claude/skills/plans/` for all others (Claude Code, Cursor, Windsurf). Default falls back to `.claude/skills/plans/` when no instruction file is detected.
- `plans-update` now checks and offers to update the skill at both `.claude/skills/plans/` and `.agents/skills/plans/`, running skill checks before the system-file early exit so skill-only updates are never silently skipped.

## v0.1.0 (original scope, never tagged)

The initial public scope. Never cut as a standalone tag; `0.2.0` is the
first numbered release. Kept here as a record of the original feature set:

- 7-field plan frontmatter spec (`status`, `priority`, `owner`, `type`, `depends_on`, `blocks`, `last_updated`)
- `plans/` directory convention: `active/`, `shipped/`, plus `STATUS.md`, `plans.json`, `roadmap.html`
- Two-source rule (frontmatter and banner must agree)
- Idea lifecycle: backlog bullet -> plan file when committed -> shipped/ when complete
- `roadmap.html` interactive dashboard:
  - Frappe Gantt timeline with cluster-based color coding (connected components in dependency graph)
  - vis-network dependency graph with zoom controls
  - Filterable plan cards (All / Active / Shipped)
  - Today button and auto-scroll on load
  - Read-only (drag-to-edit disabled)
- `init.sh` and `update.sh` bash scripts for setup and updates
- `template/CLAUDE.md.snippet` for AI assistant integration
- Live demo at GitHub Pages, reads `examples/plans.json`
- Documentation: `README.md`, `docs/reference.md`, `docs/blog-post.md`, `docs/presentation.html`
