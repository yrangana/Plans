#!/bin/sh
# Stop hook for the plans plugin.
#
# Blocks the stop, once, when this session changed code while an in-flight
# plan exists and nothing under plans/ was updated. The block carries a
# reason telling the model how to satisfy the guard; stop_hook_active
# guarantees the second stop always passes, so the cost is at most one
# extra turn.
#
# The stop_hook_active check is mandatory, not a nicety. Claude Code caps
# consecutive Stop-hook blocks (9 in build 2.1.274) and force-overrides
# past that, so a hook that ignores the flag would block repeatedly and
# then silently stop enforcing. Returning success as soon as the flag is
# true keeps this guard at exactly one block per turn, well under the cap.
#
# Fails open everywhere. Any missing input, missing tool, or unexpected
# error exits 0 silently, because a hook bug must never trap a user in a
# session they cannot end.
#
# Reads the session marker written by plans-context.sh: mtime is the
# session start, content is the starting HEAD.
set -u

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
# plans-context.sh rather than factored into a shared file. Hook scripts
# run standalone under sh, invoked from two different roots (SessionStart
# vs Stop), and sourcing a shared file would add a path-resolution
# failure mode to scripts whose entire contract is to fail open. Keep the
# two copies identical; if one changes, change the other the same way.
_json_str() {
  # Extract a flat string field from _stdin. No jq dependency.
  printf '%s' "${_stdin}" \
    | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" \
    | head -n 1
}

_json_bool() {
  # Extract a flat boolean field from _stdin. No jq dependency. Two
  # separate patterns instead of one \(true\|false\) alternation: BSD
  # sed (the default /usr/bin/sed on macOS, where these hooks also run)
  # does not support \| inside a basic regular expression, only GNU sed
  # does, so a single alternated pattern matches nothing under BSD sed
  # and stop_hook_active would never be detected, defeating the loop
  # guard entirely.
  _val=$(printf '%s' "${_stdin}" \
    | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\(true\).*/\1/p" \
    | head -n 1)
  if [ -z "${_val}" ]; then
    _val=$(printf '%s' "${_stdin}" \
      | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\(false\).*/\1/p" \
      | head -n 1)
  fi
  printf '%s' "${_val}"
}

# 1. Loop guard. The second stop of a turn always passes.
[ "$(_json_bool stop_hook_active)" = "true" ] && exit 0

# 2. Resolve the project root the same way plans-context.sh does.
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
[ -z "${_root}" ] && exit 0

# 3. Locate the marker. No marker means no known session boundary.
_marker_dir=$(_json_str scratchpad_dir)
[ -z "${_marker_dir}" ] && _marker_dir="${TMPDIR:-/tmp}/plans-hook"
_session=$(_json_str session_id)
if [ -z "${_session}" ]; then
  # Mirror plans-context.sh's fallback naming exactly, including its
  # abs-path resolution, so a Stop event missing session_id still finds
  # the same marker name a SessionStart event without one would have
  # written. Resolving to an absolute path first avoids collapsing the
  # "." root candidate down to a literal dot.
  _abs_root=$(cd "${_root}" 2>/dev/null && pwd) || _abs_root="${_root}"
  _session=$(printf '%s' "${_abs_root}" | sed 's|/|_|g; s|^_||')
fi
_marker="${_marker_dir}/${_session}"
[ -f "${_marker}" ] || exit 0

# 4. In-flight gate. Silent in projects with nothing marked in flight.
_inflight=$(find "${_root}/plans/active" -name '*.md' -type f \
  -exec grep -l '^in_flight:[[:space:]]*true' {} + 2>/dev/null \
  | sed 's|.*/||' | sort | tr '\n' ' ')
[ -z "${_inflight}" ] && exit 0

# 5. Did anything under plans/ change this session? mtime, not git, because
# plans/ is normally git-excluded.
_touched=$(find "${_root}/plans/active" "${_root}/plans/shipped" \
  "${_root}/plans/superseded" "${_root}/plans/STATUS.md" \
  -newer "${_marker}" 2>/dev/null | head -n 1)
[ -n "${_touched}" ] && exit 0

# 6. Did git-visible code change this session?
git -C "${_root}" rev-parse --git-dir >/dev/null 2>&1 || exit 0
_sha=$(cat "${_marker}" 2>/dev/null) || _sha=""
if [ -n "${_sha}" ] && git -C "${_root}" rev-parse --verify --quiet "${_sha}^{commit}" >/dev/null 2>&1; then
  _changed=$( { git -C "${_root}" diff --name-only "${_sha}" 2>/dev/null;
                git -C "${_root}" ls-files --others --exclude-standard 2>/dev/null; } \
              | grep -v '^plans/' | sort -u )
else
  _changed=$(git -C "${_root}" status --porcelain 2>/dev/null \
              | sed 's/^...//' | grep -v '^plans/' | sort -u )
fi
[ -z "${_changed}" ] && exit 0

# 7. Block.
_count=$(printf '%s\n' "${_changed}" | grep -c .)
_sample=$(printf '%s\n' "${_changed}" | head -n 3 | tr '\n' ' ')

_escape() {
  # Escape backslashes and double quotes for embedding in a JSON string.
  printf '%s' "$1" | sed 's|\\|\\\\|g; s|"|\\"|g'
}

_reason="Plans stop guard: this session changed ${_count} file(s) ($(_escape "${_sample}")) but nothing under plans/ was updated. In-flight plans: $(_escape "${_inflight}"). Before stopping, either update the covering plan's Status banner and last_updated in its frontmatter (and move its row in plans/STATUS.md if a phase changed), or say explicitly that no active plan covers this work. This guard fires at most once per turn."

printf '{"decision":"block","reason":"%s"}\n' "${_reason}"
exit 0
