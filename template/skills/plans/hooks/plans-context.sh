#!/bin/sh
# SessionStart hook for the plans plugin.
#
# hookSpecificOutput.additionalContext is a documented mechanism: Claude
# Code's official hooks reference states that the string is wrapped in a
# system reminder and inserted into the model's context at the point the
# hook fires, capped at 10,000 characters. This payload is well under
# that cap (under 900 characters).
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
#
# Guard the stdin read: Claude Code pipes JSON and closes the pipe, so a
# plain `cat` is safe there, but this script can also run by hand, under a
# different harness, or under a future build that does not close stdin. A
# blocking read here would hang the whole session with no way out, which
# is the one failure mode this hook cannot have. `[ -t 0 ]` (stdin is a
# terminal) skips the read entirely; a non-terminal stdin that is simply
# empty still returns immediately at EOF.
if [ -t 0 ]; then
  _stdin=""
else
  _stdin=$(cat 2>/dev/null) || _stdin=""
fi

# _json_str is duplicated verbatim between this file and
# plans-stop-guard.sh rather than factored into a shared file. Hook
# scripts run standalone under sh, invoked from two different roots
# (SessionStart vs Stop), and sourcing a shared file would add a
# path-resolution failure mode to scripts whose entire contract is to
# fail open. Keep the two copies identical; if one changes, change the
# other the same way.
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
  # session id is absent. Resolve _root to an absolute path first: the
  # third candidate above can leave _root as the literal "." and the
  # transform below would otherwise collapse it to just ".", which never
  # satisfies the [ ! -e ] check and silently disables the write.
  _abs_root=$(cd "${_root}" 2>/dev/null && pwd) || _abs_root="${_root}"
  _session=$(printf '%s' "${_abs_root}" | sed 's|/|_|g; s|^_||')
fi

_marker_path="${_marker_dir}/${_session}"

# [ ! -e ] alone follows symlinks, so a dangling symlink pre-placed at
# _marker_path would test false (the link exists but its target does not),
# bypass the write-once guard, and let the printf below follow the link
# and truncate whatever it points at. [ ! -L ] closes that: a dangling
# symlink fails this check too, so the write is skipped. A symlink that
# resolves to an existing file is already covered by [ ! -e ] (it reads
# as "existing", so nothing is written).
if mkdir -p "${_marker_dir}" 2>/dev/null \
  && [ ! -e "${_marker_path}" ] \
  && [ ! -L "${_marker_path}" ]; then
  # SessionStart also fires on resume, clear, and compact. Writing only when
  # absent keeps the marker pinned to the true session start, so a compact
  # does not erase the earlier part of the session from the guard's view.
  _head=$(git -C "${_root}" rev-parse HEAD 2>/dev/null) || _head=""
  # Redirect stderr before the file redirect: redirections apply left to
  # right, so putting 2>/dev/null first ensures a "cannot create" failure
  # from opening _marker_path never reaches the real stderr either.
  printf '%s' "${_head}" 2>/dev/null > "${_marker_path}" || true
fi

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"This project uses the plans/ convention for tracking work. Read plans/STATUS.md at the start of the session for current state. Write new plans only into plans/active/, never to an assistant scratch or memory directory, plan-mode artifacts, or the repo root. plans/plans.json is generated; never hand-edit it. Before ending a session that touched code covered by an active plan, update that plan's ## Status banner and last_updated in its frontmatter. Audit drift periodically with /plans:plans sync, reconciling plans against git log and regenerating plans.json and STATUS.md auto-sections. The convention itself is documented in plans/README.md; defer to it for anything not covered here. A Stop guard will ask once for a plan update if this session changes code while a plan is in flight and no plan file is touched. Skill modes are invoked as /plans:plans <mode> (init, sync, new, update)."}}
JSON

exit 0
