# Contributing to Plans

Thanks for the interest. Plans is a small, opinionated convention: changes that keep it small and add real value are welcome; changes that grow the surface area for hypothetical use cases get pushed back on.

Read [CLAUDE.md](CLAUDE.md) first if you want the maintenance philosophy in detail. The short version: this is a convention, not a framework.

---

## Where contributions are most welcome

### Skill ports to other AI assistants

The convention itself is platform-neutral. The `/plans` skill ships for Claude Code, Antigravity, and Cursor today. Ports to other assistants are the highest-leverage contribution.

Concrete asks:

- **Cline skill port.** The skill body lives in [template/skills/plans/SKILL.md](template/skills/plans/SKILL.md). Cline uses a similar slash-command pattern; the port is mostly moving one file and adjusting the trigger. Roughly 30 lines of work.
- **Windsurf workflow port.** Windsurf uses workflows (`.windsurf/workflows/`) rather than slash commands. Map the `/plans sync` and `/plans new` modes to two workflow files.
- **aider integration.** Aider doesn't have a skill format per se, but a documented prompt template that an aider user can paste into their session would close the gap.

### Roadmap dashboard improvements

[template/plans/roadmap.html](template/plans/roadmap.html) is the dashboard adopters get. It reads `plans.json` and renders a Gantt + dependency graph + filterable cards. It's one self-contained HTML file with no build step, that's a hard constraint, don't add bundlers or npm.

Open ideas:

- **Mermaid export.** A button that exports the current dependency graph as Mermaid syntax, so it can be pasted into a doc, GitHub issue, or notion page. Small, self-contained.
- **CSV / Notion / Linear export.** A `plans-export` script (parallel to `plans-init` / `plans-update`) that dumps `plans.json` into a format another tool can import. Useful for adopters who want to switch off Plans or sync to a team tool. Define the schema before writing the script.
- **Print stylesheet.** The dashboard prints badly today. A focused `@media print` block that produces a one-page roadmap PDF would be welcome.

### Doc clarifications and bug fixes

- Fixing typos, broken links, or markdown lint issues in any doc: send a PR, no issue needed.
- Reproducible bug in `roadmap.html`, the install script, or the `/plans` skill: open an issue with the steps to reproduce.

---

## Where we'll push back

Per the maintenance philosophy in [CLAUDE.md](CLAUDE.md):

- **New frontmatter fields.** The 7-field schema is fixed for a reason. New fields fragment what adopters write and break the cross-project shape the dashboard depends on. Open an issue to discuss before opening a PR.
- **Config flags.** If you want different behaviour, fork. Plans avoids config because every flag is a maintenance burden and a surface for "but in my setup…" bug reports.
- **Tooling rewrites.** `init.sh` is bash on purpose. Don't propose rewriting it in Node or Python.
- **Renaming existing fields or paths.** Backwards compatibility for adopters matters. Adding new things is fine; renaming what's already shipped is not.
- **AI-first framing.** The primary audience is the human doing the work. AI readability is a side effect. Doc PRs that invert this framing won't merge.

---

## Proposing a substantive change

For anything beyond a typo or a self-contained bug fix:

1. Open an issue first describing the problem and your proposed approach.
2. Wait for a brief discussion. Most ideas get resolved (yes / no / different shape) within a day or two.
3. Once aligned, open the PR.

This saves you writing a PR that won't merge, and saves the maintainer from a hard decline on work you've already done.

---

## Local development

Repo layout and test recipes are in [CLAUDE.md](CLAUDE.md). The short version:

```bash
# Test the init script
rm -rf /tmp/test-plans && mkdir /tmp/test-plans
cd /tmp/test-plans && git init
bash "$OLDPWD/scripts/init.sh"

# Serve the demo site locally
(cd web && python -m http.server 8080)
```

Run both before opening a PR that touches `scripts/`, `template/`, or `web/`.

---

## Reporting bugs

Open a GitHub issue with:

- What you ran (exact command)
- What you expected to happen
- What actually happened (paste output)
- Your OS and shell

Bugs in `roadmap.html` are easier to reproduce if you can share the offending `plans.json` (or a minimal version of it).

---

## License

By contributing, you agree your contribution is licensed under the project's [MIT License](LICENSE).
