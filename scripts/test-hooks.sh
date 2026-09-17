#!/usr/bin/env bash
# Tests for the plans hook scripts. Run from anywhere; resolves its own repo root.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_DIR="$REPO_ROOT/template/skills/plans/hooks"
CONTEXT="$HOOK_DIR/plans-context.sh"
GUARD="$HOOK_DIR/plans-stop-guard.sh"

PASS=0
FAIL=0

pass() { echo "ok: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; echo "      $2"; FAIL=$((FAIL + 1)); }

check_eq() {
  # check_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "expected [$2] got [$3]"; fi
}

check_contains() {
  # check_contains <label> <needle> <haystack>
  case "$3" in
    *"$2"*) pass "$1" ;;
    *) fail "$1" "expected to contain [$2] got [$3]" ;;
  esac
}

check_empty() {
  # check_empty <label> <actual>
  if [ -z "$2" ]; then pass "$1"; else fail "$1" "expected empty, got [$2]"; fi
}

echo "=== hook scripts exist and are runnable under sh ==="

if [ -f "$CONTEXT" ]; then pass "plans-context.sh exists in skill tree"; else fail "plans-context.sh exists in skill tree" "$CONTEXT not found"; fi

echo "=== SessionStart marker ==="

ss_fixture() {
  # ss_fixture <dir>; creates a git repo with plans/
  mkdir -p "$1/plans/active" "$1/src"
  printf '# Status\n' > "$1/plans/STATUS.md"
  printf 'x\n' > "$1/src/app.js"
  git -C "$1" init -q
  git -C "$1" add . >/dev/null 2>&1
  git -C "$1" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
}

ss_stdin() {
  # ss_stdin <session_id> <scratchpad_dir>
  printf '{"session_id":"%s","scratchpad_dir":"%s","cwd":"/x","hook_event_name":"SessionStart","source":"startup"}' "$1" "$2"
}

# Pin CLAUDE_PROJECT_DIR unset for every hook invocation below. Otherwise a
# value inherited from the environment this suite happens to run in (for
# example, running it from inside a project that has itself adopted the
# convention) would resolve _root to that outer project instead of the
# fixture, turning several of these checks into false passes.
run_hook() {
  env -u CLAUDE_PROJECT_DIR sh "$CONTEXT"
}

T1="$(mktemp -d)"; MK1="$(mktemp -d)"
ss_fixture "$T1"
OUT=$(cd "$T1" && ss_stdin sess1 "$MK1" | run_hook)
check_contains "SessionStart still emits ambient rules" "plans/ convention" "$OUT"
if [ -f "$MK1/sess1" ]; then pass "marker created"; else fail "marker created" "$MK1/sess1 not found"; fi
check_eq "marker holds HEAD" "$(git -C "$T1" rev-parse HEAD)" "$(cat "$MK1/sess1" 2>/dev/null)"

# second fire must not rewrite it
touch -t 202601010000 "$MK1/sess1"
BEFORE=$(ls -l "$MK1/sess1")
(cd "$T1" && ss_stdin sess1 "$MK1" | run_hook) >/dev/null
check_eq "marker not rewritten on second fire" "$BEFORE" "$(ls -l "$MK1/sess1")"

# no plans/ means no marker and no output
T2="$(mktemp -d)"; MK2="$(mktemp -d)"
git -C "$T2" init -q
OUT=$(cd "$T2" && ss_stdin sess2 "$MK2" | run_hook)
check_empty "no plans/ means no output" "$OUT"
if [ -f "$MK2/sess2" ]; then fail "no plans/ means no marker" "marker was created"; else pass "no plans/ means no marker"; fi

# non-git project still gets a marker, with empty content
T3="$(mktemp -d)"; MK3="$(mktemp -d)"
mkdir -p "$T3/plans/active"; printf '# Status\n' > "$T3/plans/STATUS.md"
(cd "$T3" && ss_stdin sess3 "$MK3" | run_hook) >/dev/null
if [ -f "$MK3/sess3" ]; then pass "non-git project gets a marker"; else fail "non-git project gets a marker" "not found"; fi
check_empty "non-git marker is empty" "$(cat "$MK3/sess3" 2>/dev/null)"

# scratchpad_dir absent. Task 1 proved Claude Code 2.1.274 does not send
# this field at all, so the TMPDIR fallback is the production path and must
# be covered directly.
T4="$(mktemp -d)"; TB4="$(mktemp -d)"
ss_fixture "$T4"
OUT=$(cd "$T4" && printf '{"session_id":"sess4","cwd":"/x","hook_event_name":"SessionStart","source":"startup"}' | TMPDIR="$TB4" run_hook)
check_contains "no scratchpad_dir still emits rules" "plans/ convention" "$OUT"
if [ -f "$TB4/plans-hook/sess4" ]; then pass "marker falls back to TMPDIR"; else fail "marker falls back to TMPDIR" "$TB4/plans-hook/sess4 not found"; fi
check_eq "fallback marker holds HEAD" "$(git -C "$T4" rev-parse HEAD)" "$(cat "$TB4/plans-hook/sess4" 2>/dev/null)"

# dangling symlink at the marker path must not be followed. [ ! -e ] alone
# reads a dangling link (the link exists, its target does not) as "absent",
# bypasses the write-once guard, and lets the write follow the link and
# create or truncate whatever it points at. The target must not exist yet
# for this to be the dangling case under test; if it already existed,
# [ ! -e ] alone would already (correctly) skip the write and the test
# would pass without exercising the fix.
T5="$(mktemp -d)"; MK5="$(mktemp -d)"
ss_fixture "$T5"
ln -s "$MK5/canary" "$MK5/sess5"
if [ -e "$MK5/canary" ]; then fail "canary absent before hook runs" "setup invariant violated"; else pass "canary absent before hook runs"; fi
OUT=$(cd "$T5" && ss_stdin sess5 "$MK5" | run_hook)
check_contains "symlink case still emits ambient rules" "plans/ convention" "$OUT"
if [ -e "$MK5/canary" ]; then fail "dangling symlink target is not created" "$MK5/canary was created"; else pass "dangling symlink target is not created"; fi
if [ -L "$MK5/sess5" ]; then pass "dangling symlink at marker path is left alone"; else fail "dangling symlink at marker path is left alone" "symlink was replaced"; fi

# _root resolving through the "." candidate (no CLAUDE_PROJECT_DIR, no git
# repo, plans/ found via the cwd) combined with an absent session_id must
# still produce a marker instead of silently collapsing the fallback name
# to ".".
T6="$(mktemp -d)"; MK6="$(mktemp -d)"
mkdir -p "$T6/plans/active"; printf '# Status\n' > "$T6/plans/STATUS.md"
(cd "$T6" && printf '{"scratchpad_dir":"%s","cwd":"/x","hook_event_name":"SessionStart","source":"startup"}' "$MK6" | run_hook) >/dev/null
MARKER_NAME=$(ls -A "$MK6" 2>/dev/null)
COUNT=$(printf '%s\n' "$MARKER_NAME" | grep -c .)
check_eq "dot-root fallback still produces exactly one marker" "1" "$COUNT"
if [ "$MARKER_NAME" = "." ]; then fail "dot-root fallback session name is not the literal dot" "marker named ."; else pass "dot-root fallback session name is not the literal dot"; fi

rm -rf "$T1" "$T2" "$T3" "$T4" "$T5" "$T6" "$MK1" "$MK2" "$MK3" "$TB4" "$MK5" "$MK6"

echo "=== Stop guard ==="

# Fixture mtime stamps for the guard's `find -newer marker` comparison.
# PRE-DATE is stamped onto everything meant to look like it existed
# before the session started; POST-DATE is stamped onto anything a test
# deliberately touches after the marker to simulate an in-session edit.
# Fixed calendar stamps, not "rely on real elapsed time" or `sleep 1`:
# an earlier version instead relied on the natural creation order of
# fixture writes versus the marker file, which depends on the real
# clock and on sub-second mtime resolution actually being available.
# The reviewer reproduced the flake directly by forcing the marker and
# a post-marker file to share a whole-second mtime (simulating a
# one-second-granularity filesystem): `find -newer` is strictly-greater,
# so a tie reads as "not touched" and pass-expected tests failed. These
# two fixed stamps hold for any real clock between 2000 and 2090, at
# any mtime resolution, because they no longer depend on measuring
# elapsed real time at all.
PRE_DATE=200001010000
POST_DATE=209001010000

guard_fixture() {
  # guard_fixture <dir> <in_flight>; git repo, plans/, one active plan.
  # Every plans/ artifact created here is stamped to PRE_DATE: it
  # represents the project's state before the session started, and must
  # read as older than the marker regardless of the real clock.
  mkdir -p "$1/plans/active" "$1/plans/shipped" "$1/plans/superseded" "$1/src"
  printf '# Status\n' > "$1/plans/STATUS.md"
  cat > "$1/plans/active/FEATURE.md" <<EOF
---
status: active
priority: high
owner: yash
type: feature
depends_on: []
blocks: []
in_flight: $2
last_updated: 2026-09-01
---

## Status
EOF
  printf 'x\n' > "$1/src/app.js"
  git -C "$1" init -q
  git -C "$1" add src >/dev/null 2>&1
  git -C "$1" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
  touch -t "$PRE_DATE" "$1/plans/STATUS.md" "$1/plans/active" \
    "$1/plans/shipped" "$1/plans/superseded" "$1/plans/active/FEATURE.md"
}

guard_marker() {
  # guard_marker <markerdir> <session> <dir>; writes the marker with its
  # natural creation mtime. That mtime always lands after guard_fixture's
  # PRE_DATE-stamped writes and before any test's POST_DATE-stamped
  # touch, for any real clock between 2000 and 2090, so the marker
  # itself needs no explicit stamp.
  mkdir -p "$1"
  git -C "$3" rev-parse HEAD > "$1/$2" 2>/dev/null || : > "$1/$2"
}

guard_stdin() {
  # guard_stdin <session_id> <scratchpad_dir> <stop_hook_active>
  printf '{"session_id":"%s","scratchpad_dir":"%s","cwd":"/x","hook_event_name":"Stop","stop_hook_active":%s}' "$1" "$2" "$3"
}

run_guard() {
  # run_guard <dir> <session> <markerdir> [stop_hook_active]
  (cd "$1" && guard_stdin "$2" "$3" "${4:-false}" | sh "$GUARD")
}

# 1. loop guard
D="$(mktemp -d)"; M="$(mktemp -d)"
guard_fixture "$D" true; guard_marker "$M" s "$D"
printf 'changed\n' >> "$D/src/app.js"
check_empty "stop_hook_active true passes" "$(run_guard "$D" s "$M" true)"

# 2. no plans/ directory
D2="$(mktemp -d)"; git -C "$D2" init -q
check_empty "no plans/ passes" "$(run_guard "$D2" s "$M")"

# 3. no marker
D3="$(mktemp -d)"; M3="$(mktemp -d)"
guard_fixture "$D3" true
printf 'changed\n' >> "$D3/src/app.js"
check_empty "missing marker passes" "$(run_guard "$D3" s "$M3")"

# 4. no in-flight plan
D4="$(mktemp -d)"; M4="$(mktemp -d)"
guard_fixture "$D4" false; guard_marker "$M4" s "$D4"
printf 'changed\n' >> "$D4/src/app.js"
check_empty "no in_flight plan passes" "$(run_guard "$D4" s "$M4")"

# 5. plan file touched this session
D5="$(mktemp -d)"; M5="$(mktemp -d)"
guard_fixture "$D5" true; guard_marker "$M5" s "$D5"
printf 'changed\n' >> "$D5/src/app.js"
touch -t "$POST_DATE" "$D5/plans/active/FEATURE.md"
check_empty "touched plan passes" "$(run_guard "$D5" s "$M5")"

# 6. plan moved to shipped/
D6="$(mktemp -d)"; M6="$(mktemp -d)"
guard_fixture "$D6" true; guard_marker "$M6" s "$D6"
printf 'changed\n' >> "$D6/src/app.js"
mv "$D6/plans/active/FEATURE.md" "$D6/plans/shipped/FEATURE.md"
touch -t "$POST_DATE" "$D6/plans/active" "$D6/plans/shipped"
check_empty "plan moved to shipped passes" "$(run_guard "$D6" s "$M6")"

# 7. uncommitted code change, no plan touched -> BLOCK
D7="$(mktemp -d)"; M7="$(mktemp -d)"
guard_fixture "$D7" true; guard_marker "$M7" s "$D7"
printf 'changed\n' >> "$D7/src/app.js"
OUT=$(run_guard "$D7" s "$M7")
check_contains "uncommitted change blocks" '"decision":"block"' "$OUT"
check_contains "block names the in-flight plan" "FEATURE.md" "$OUT"
check_contains "block names the changed file" "src/app.js" "$OUT"

# 8. committed code change, no plan touched -> BLOCK
D8="$(mktemp -d)"; M8="$(mktemp -d)"
guard_fixture "$D8" true; guard_marker "$M8" s "$D8"
printf 'changed\n' >> "$D8/src/app.js"
git -C "$D8" add src >/dev/null 2>&1
git -C "$D8" -c user.email=t@t -c user.name=t commit -qm work >/dev/null 2>&1
check_contains "committed change blocks" '"decision":"block"' "$(run_guard "$D8" s "$M8")"

# 9. new untracked file -> BLOCK
D9="$(mktemp -d)"; M9="$(mktemp -d)"
guard_fixture "$D9" true; guard_marker "$M9" s "$D9"
printf 'new\n' > "$D9/src/new.js"
check_contains "untracked file blocks" '"decision":"block"' "$(run_guard "$D9" s "$M9")"

# 10. only plans/ changed in git (tracked-plans adopter) -> pass
D10="$(mktemp -d)"; M10="$(mktemp -d)"
guard_fixture "$D10" true
git -C "$D10" add plans >/dev/null 2>&1
git -C "$D10" -c user.email=t@t -c user.name=t commit -qm plans >/dev/null 2>&1
guard_marker "$M10" s "$D10"
printf 'note\n' >> "$D10/plans/active/FEATURE.md"
touch -t "$POST_DATE" "$D10/plans/active/FEATURE.md"
check_empty "only plans/ changed passes" "$(run_guard "$D10" s "$M10")"

# 11. not a git repo -> pass
D11="$(mktemp -d)"; M11="$(mktemp -d)"
mkdir -p "$D11/plans/active" "$D11/src"
printf '# Status\n' > "$D11/plans/STATUS.md"
cat > "$D11/plans/active/FEATURE.md" <<'EOF'
---
in_flight: true
---
EOF
touch -t "$PRE_DATE" "$D11/plans/STATUS.md" "$D11/plans/active" "$D11/plans/active/FEATURE.md"
mkdir -p "$M11"; : > "$M11/s"
printf 'x\n' > "$D11/src/app.js"
check_empty "non-git project passes" "$(run_guard "$D11" s "$M11")"

# 12. marker sha unknown to git -> falls back to status, still blocks
D12="$(mktemp -d)"; M12="$(mktemp -d)"
guard_fixture "$D12" true
mkdir -p "$M12"; printf '%s' "0000000000000000000000000000000000000000" > "$M12/s"
printf 'changed\n' >> "$D12/src/app.js"
check_contains "unknown marker sha still blocks" '"decision":"block"' "$(run_guard "$D12" s "$M12")"

# 13. no changes at all -> pass
D13="$(mktemp -d)"; M13="$(mktemp -d)"
guard_fixture "$D13" true; guard_marker "$M13" s "$D13"
check_empty "no changes passes" "$(run_guard "$D13" s "$M13")"

# 14. every invocation exits 0
run_guard "$D7" s "$M7" >/dev/null; check_eq "guard always exits 0" "0" "$?"

# 15. scratchpad_dir absent: the guard must find the marker under TMPDIR.
# This is the production path (Task 1 finding), not an edge case.
D14="$(mktemp -d)"; TB14="$(mktemp -d)"
guard_fixture "$D14" true
mkdir -p "$TB14/plans-hook"
git -C "$D14" rev-parse HEAD > "$TB14/plans-hook/s14"
printf 'changed\n' >> "$D14/src/app.js"
OUT=$(cd "$D14" && printf '{"session_id":"s14","cwd":"/x","hook_event_name":"Stop","stop_hook_active":false}' | TMPDIR="$TB14" sh "$GUARD")
check_contains "TMPDIR fallback marker blocks" '"decision":"block"' "$OUT"

# 16. the case-glob loop guard suffices on its own, independent of the
# sed-based _json_bool check. Shadow `sed` on PATH with a surgical stub:
# it passes every call through to the real sed unchanged EXCEPT calls
# shaped exactly like _json_bool's true/false extraction, which it makes
# produce no output. This isolates the same failure class that silently
# broke the loop guard once already (_json_bool's alternation matching
# nothing under BSD sed) without also breaking _json_str and every other
# sed-dependent step the rest of the guard needs in order to run
# normally; a stub that breaks all of sed indiscriminately would let the
# guard pass for the wrong reason (failing open elsewhere, e.g. because
# it can no longer parse scratchpad_dir/session_id at all) and the test
# would not actually be exercising the case glob. `case` is a shell
# builtin, so the glob check itself needs no external command at all.
REAL_SED="$(command -v sed)"
FAKEBIN16="$(mktemp -d)"
cat > "$FAKEBIN16/sed" <<EOF
#!/bin/sh
for _a in "\$@"; do
  if printf '%s' "\${_a}" | grep -qF '\\(true\\).' \\
     || printf '%s' "\${_a}" | grep -qF '\\(false\\).'; then
    exit 0
  fi
done
exec "${REAL_SED}" "\$@"
EOF
chmod +x "$FAKEBIN16/sed"
D16="$(mktemp -d)"; M16="$(mktemp -d)"
guard_fixture "$D16" true; guard_marker "$M16" s "$D16"
printf 'changed\n' >> "$D16/src/app.js"
OUT=$(cd "$D16" && guard_stdin s "$M16" true | PATH="$FAKEBIN16:$PATH" sh "$GUARD")
check_empty "glob loop guard alone suffices when _json_bool is broken" "$OUT"

rm -rf "$D" "$D2" "$D3" "$D4" "$D5" "$D6" "$D7" "$D8" "$D9" "$D10" "$D11" "$D12" "$D13" "$D14" "$TB14" "$D16" "$FAKEBIN16"
rm -rf "$M" "$M3" "$M4" "$M5" "$M6" "$M7" "$M8" "$M9" "$M10" "$M11" "$M12" "$M13" "$M16"

echo "=== summary ==="
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
