#!/usr/bin/env bash
# SessionStart hook for the plans plugin.
#
# Verified by manual test on a clean VM (not documented clearly by Claude
# Code's official docs): a SessionStart hook's JSON output field
# hookSpecificOutput.additionalContext is genuinely read into the model's
# context for that session. Treat this mechanism as verified-by-test.
#
# This hook must be fast and side-effect free. It runs at the start of
# every session, so it never prompts, never writes, and always exits 0.
set -u

# Only inject the plans/ rules when this project has adopted the
# convention. Without this guard, every session in every unrelated
# project would get these rules injected, which is context pollution.
if [ ! -d "plans" ]; then
  exit 0
fi

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"This project uses the plans/ convention for tracking work. Read plans/STATUS.md at the start of the session for current state. Write new plans only into plans/active/, never to an assistant scratch or memory directory, plan-mode artifacts, or the repo root. plans/plans.json is generated; never hand-edit it. Before ending a session that touched code covered by an active plan, update that plan's ## Status banner and last_updated in its frontmatter. The convention itself is documented in plans/README.md; defer to it for anything not covered here. Skill modes are invoked as /plans:plans <mode> (init, sync, new, update)."}}
JSON

exit 0
