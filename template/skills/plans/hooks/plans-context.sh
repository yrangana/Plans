#!/bin/sh
# SessionStart hook for the plans plugin.
#
# hookSpecificOutput.additionalContext is a documented mechanism: Claude
# Code's official hooks reference states that the string is wrapped in a
# system reminder and inserted into the model's context at the point the
# hook fires, capped at 10,000 characters. This payload is well under
# that cap (about 760 characters).
#
# This hook must be fast and side-effect free apart from one write: when
# the project has adopted the convention, it records a per-session marker
# file (mtime = session start, content = starting HEAD) that the Stop
# guard reads to scope "what changed this session". The marker lives in
# the session scratchpad when one is supplied, otherwise in TMPDIR. It is
# written once per session and never read by anything else. The hook
# never prompts, never touches the project tree, and always exits 0.
set -u

# Only inject the plans/ rules when this project has adopted the
# convention. Guard on the project root, not the process cwd: a
# SessionStart hook can run from any working directory. The convention
# always places plans/ at the repository root, so resolve that root by
# trying three candidates in order, using the first one whose directory
# actually contains plans/:
#
#   1. $CLAUDE_PROJECT_DIR, when it is set and non-empty. This is the
#      documented way to reference the project root, but it is not
#      reliably set to the repo root in every session shape.
#   2. The git repository root (`git rev-parse --show-toplevel`), run
#      from the current directory. This is the reliable case: adopters
#      are in git repos, and the convention lives at that repo's root.
#      Git's stderr is discarded and a nonzero exit (not a git repo, or
#      git missing) is handled without failing the hook.
#   3. The current directory, preserving the original behavior as a
#      last resort for non-git projects.
#
# If none of the three yields a directory containing plans/, emit
# nothing. An unrelated directory that happens to contain a plans/
# folder only matches via step 3, same as before this fix.
_root=""

if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}/plans" ]; then
  _root="${CLAUDE_PROJECT_DIR}"
fi

if [ -z "${_root}" ]; then
  _git_root=$(git rev-parse --show-toplevel 2>/dev/null) || _git_root=""
  if [ -n "${_git_root}" ] && [ -d "${_git_root}/plans" ]; then
    _root="${_git_root}"
  fi
fi

if [ -z "${_root}" ] && [ -d "./plans" ]; then
  _root="."
fi

if [ -z "${_root}" ]; then
  exit 0
fi

# Record the session marker. Best effort: any failure here is swallowed so
# the ambient rules are still emitted.
_stdin=$(cat 2>/dev/null) || _stdin=""

_json_str() {
  # Extract a flat string field from _stdin. No jq dependency.
  printf '%s' "${_stdin}" \
    | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" \
    | head -n 1
}

_marker_dir=$(_json_str scratchpad_dir)
if [ -z "${_marker_dir}" ]; then
  _marker_dir="${TMPDIR:-/tmp}/plans-hook"
fi

_session=$(_json_str session_id)
if [ -z "${_session}" ]; then
  # Fall back to a per-project name so the guard still works when the
  # session id is absent.
  _session=$(printf '%s' "${_root}" | sed 's|/|_|g; s|^_||')
fi

if mkdir -p "${_marker_dir}" 2>/dev/null && [ ! -e "${_marker_dir}/${_session}" ]; then
  # SessionStart also fires on resume, clear, and compact. Writing only when
  # absent keeps the marker pinned to the true session start, so a compact
  # does not erase the earlier part of the session from the guard's view.
  _head=$(git -C "${_root}" rev-parse HEAD 2>/dev/null) || _head=""
  printf '%s' "${_head}" > "${_marker_dir}/${_session}" 2>/dev/null || true
fi

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"This project uses the plans/ convention for tracking work. Read plans/STATUS.md at the start of the session for current state. Write new plans only into plans/active/, never to an assistant scratch or memory directory, plan-mode artifacts, or the repo root. plans/plans.json is generated; never hand-edit it. Before ending a session that touched code covered by an active plan, update that plan's ## Status banner and last_updated in its frontmatter. Audit drift periodically with /plans:plans sync, reconciling plans against git log and regenerating plans.json and STATUS.md auto-sections. The convention itself is documented in plans/README.md; defer to it for anything not covered here. Skill modes are invoked as /plans:plans <mode> (init, sync, new, update)."}}
JSON

exit 0
