# CLAUDE.md, plans repo

This file is for AI assistants (Claude Code, Antigravity, Cursor) and human contributors working on the `plans` repo itself, not for projects that adopt the system.

Maintainers may keep additional personal context in a `CLAUDE.local.md` next to this file. That file is gitignored and overrides nothing here, it just adds local conveniences (paths, preferences) on top.

---

## What this repo is

A shareable spec-driven planning convention. The repo contains:

- **Documentation** explaining the system (`README.md`, `docs/`)
- **A drop-in template** users copy into their own projects (`template/plans/`)
- **A bootstrap script** that automates the copy (`scripts/init.sh`)
- **A live demo** rendered by GitHub Pages (`examples/`)

This repo does **not** itself adopt the planning convention by default. It's the system, not a user of the system. (See "Using the system on this repo" below if you change your mind.)

---

## Repo structure

```
plans/
├── README.md                    # Top-level pitch + quick start
├── LICENSE                      # MIT
├── CLAUDE.md                    # This file
├── docs/                        # Standalone guide for adopters
│   ├── reference.md             # Full technical spec
│   ├── blog-post.md             # Narrative explanation
│   └── presentation.html        # Slideshow
├── template/                    # What users copy into their projects
│   ├── CLAUDE.md.snippet        # Section adopters paste into their CLAUDE.md
│   └── plans/                   # The directory adopters drop into their repo
│       ├── README.md            # Onboarding for adopters
│       ├── STATUS.md            # Empty front-door template
│       ├── plans.json           # Empty starter
│       ├── roadmap.html         # Interactive dashboard
│       ├── active/              # With EXAMPLE_PLAN.md showing the format
│       └── shipped/
├── scripts/
│   └── init.sh                  # Copies template/plans into a target dir
└── examples/                    # GitHub Pages demo
    ├── index.html               # Mirror of template/plans/roadmap.html
    └── plans.json               # Demo data with fictional plans
```

---

## Mirror files (keep in sync)

These pairs must stay identical except for their data source:

| File A | File B | What's different |
|---|---|---|
| `template/plans/roadmap.html` | `examples/index.html` | Identical, just deployed in two places |
| `template/plans/plans.json` | `examples/plans.json` | Template = single example plan; examples = realistic demo data |

When you fix a bug in `roadmap.html`, copy the fix to both. Same for any visual or behaviour changes.

---

## Style rules

- **No project-specific content.** This repo is generic by definition. Don't add references to specific projects, codebases, or company-specific terminology in the templates or docs.
- **Markdown lint clean.** Tables use `| --- | --- |` (with spaces). Code fences specify a language (` ```bash `, ` ```yaml `, ` ```text ` for ASCII). No bold-as-heading.
- **Plain text in CLI output.** No emojis in script output unless explicitly requested. No colour codes.
- **Templates start empty.** STATUS.md and plans.json in `template/` should reflect a fresh project, not the maintainer's project.

The maintainer may layer additional style preferences in `CLAUDE.local.md`. Follow those when working in this repo, but don't propagate them to forks or contributor-facing docs.

---

## Testing changes

Before pushing:

Run these from the repo root.

1. **Test the init script:**
   ```bash
   rm -rf /tmp/test-plans && mkdir /tmp/test-plans
   cd /tmp/test-plans && git init
   bash "$OLDPWD/scripts/init.sh"
   # verify plans/ exists, .git/info/exclude has plans/, roadmap.html opens
   ```

2. **Test the demo locally:**
   ```bash
   (cd examples && python -m http.server 8080)
   # open http://localhost:8080/ and verify the gantt, dep graph, and plan cards render
   ```

3. **Lint check:** open the changed `.md` files in VSCode and confirm no warnings in the Problems panel.

---

## Release process

1. Make changes locally
2. Test as above
3. Commit with a clear message (no `git mv` needed since `plans/` isn't excluded here)
4. Push to `main`
5. GitHub Pages auto-deploys within 1 to 2 minutes
6. Verify: `https://yrangana.github.io/Plans/examples/`

If working with an AI assistant: the maintainer typically handles all `git commit` and `git push` operations themselves. Don't run them from the assistant unless explicitly asked.

---

## Maintenance philosophy

- **Small and opinionated.** This is a convention, not a framework. Resist scope creep.
- **Don't add config flags.** If users want different behaviour, they fork. The 7-field frontmatter is fixed; the lifecycle is fixed.
- **Optional > required.** New features (skills, scripts, exports) should be additive and skippable.
- **Backwards compatibility for adopters.** Don't rename existing fields or change existing file paths once published. New fields are fine.
- **Docs are first-class.** Every behavioural change updates `docs/reference.md` in the same commit.

---

## Using the system on this repo (optional)

The convention says `plans/` is git-excluded. That's the default for adopters. For this repo:

- **You can opt out and track plans in git** if you want this repo to demo its own use of the system.
- **Or keep them excluded** and treat this repo purely as a tooling project.

If you opt in:

1. Create `plans/active/` and add real plans (e.g., `STATUS_SYNC_SKILL_PLAN.md`, `CURSOR_PORT_PLAN.md`)
2. **Don't** add `plans/` to `.git/info/exclude` for this repo
3. Note in the README that this repo eats its own dog food
4. Document the divergence in this CLAUDE.md so adopters aren't confused

Either choice is valid. Decide deliberately, document the decision.

---

## What this repo is not

- Not a CLI tool (init.sh is a 30-line bash script, not a Node/Python package)
- Not a GitHub action or hook (could be added if requested)
- Not opinionated about your AI assistant choice (works with any)
- Not a replacement for project management tools (see scope in `README.md`)
