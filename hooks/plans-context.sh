#!/bin/sh
# SessionStart hook for the plans plugin.
#
# hookSpecificOutput.additionalContext is a documented mechanism: Claude
# Code's official hooks reference states that the string is wrapped in a
# system reminder and inserted into the model's context at the point the
# hook fires, capped at 10,000 characters. This payload is well under
# that cap (about 760 characters).
#
# This hook must be fast and side-effect free. It runs at the start of
# every session and on resume, clear, and compact (see hooks.json), so
# it never prompts, never writes, and always exits 0.
set -u

# Only inject the plans/ rules when this project has adopted the
# convention. Guard on the project root, not the process cwd: a
# SessionStart hook can run from any working directory, and
# CLAUDE_PROJECT_DIR is the documented way to reference the project root
# regardless of where the session started. Without this guard, a
# subdirectory session would miss the rules, and an unrelated directory
# that happens to contain a plans/ folder would get them injected, which
# is the context pollution this guard exists to prevent.
if [ ! -d "${CLAUDE_PROJECT_DIR:-.}/plans" ]; then
  exit 0
fi

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"This project uses the plans/ convention for tracking work. Read plans/STATUS.md at the start of the session for current state. Write new plans only into plans/active/, never to an assistant scratch or memory directory, plan-mode artifacts, or the repo root. plans/plans.json is generated; never hand-edit it. Before ending a session that touched code covered by an active plan, update that plan's ## Status banner and last_updated in its frontmatter. Audit drift periodically with /plans:plans sync, reconciling plans against git log and regenerating plans.json and STATUS.md auto-sections. The convention itself is documented in plans/README.md; defer to it for anything not covered here. Skill modes are invoked as /plans:plans <mode> (init, sync, new, update)."}}
JSON

exit 0
