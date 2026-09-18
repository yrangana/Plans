# Hook setup (project-local Claude Code deliveries only)

Registers the two plans hooks in the project's `.claude/settings.json`, so
a project-local install gets the same enforcement the plugin delivery has.

## When to offer this

Offer only when all three hold:

1. The delivery rule in SKILL.md resolved to **project-local** and this
   SKILL.md's path contains `.claude/skills`. An `.agents/skills` path
   (Antigravity) or any non-Claude-Code assistant gets no offer: they have
   no Stop hook. Say so in one line and move on.
2. `<root>/.claude/skills/plans/hooks/plans-stop-guard.sh` exists.
3. Neither hook command path already appears in `<root>/.claude/settings.json`.

If `/plans:plans` is also listed among this session's skills, the plugin is
installed and already supplies both hooks. Report that and skip: two
registrations would fire the guard twice.

## What to say

Show the exact block that will be added, then ask once:

```text
Register the plans hooks in .claude/settings.json?

  SessionStart  records a per-session marker in your temp directory
  Stop          if a session changes code while an in-flight plan exists
                and no plan file was touched, asks once for the plan update
                before the session ends

This writes only to .claude/settings.json in this project. Nothing runs
against your repository, and removing the two entries undoes it. (y/N)
```

Decline is the default. Never write without an explicit yes.

## What to write

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "sh \"$CLAUDE_PROJECT_DIR\"/.claude/skills/plans/hooks/plans-context.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh \"$CLAUDE_PROJECT_DIR\"/.claude/skills/plans/hooks/plans-stop-guard.sh"
          }
        ]
      }
    ]
  }
}
```

Rules for the write:

- If `.claude/settings.json` does not exist, create it with exactly the
  object above.
- If it exists, merge: keep every existing key, add `hooks` if absent, and
  within `hooks` append to the `SessionStart` and `Stop` arrays rather than
  replacing them. If `hooks` exists but has no `SessionStart` or `Stop` key
  yet (for example a file with only `PreToolUse`), create that array first,
  then append the entry to it. Preserve the file's existing indentation.
- `Stop` takes no `matcher` field. Do not add one.
- After writing, read the file back and confirm both command paths are
  present. If the write did not go through, say so plainly and print the
  block for the user to paste. Never report success you did not verify.

## Removing it

Tell the user, in one line, that deleting the two entries from
`.claude/settings.json` disables the hooks with no other cleanup.
