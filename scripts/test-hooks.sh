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

T1="$(mktemp -d)"; MK1="$(mktemp -d)"
ss_fixture "$T1"
OUT=$(cd "$T1" && ss_stdin sess1 "$MK1" | sh "$CONTEXT")
check_contains "SessionStart still emits ambient rules" "plans/ convention" "$OUT"
if [ -f "$MK1/sess1" ]; then pass "marker created"; else fail "marker created" "$MK1/sess1 not found"; fi
check_eq "marker holds HEAD" "$(git -C "$T1" rev-parse HEAD)" "$(cat "$MK1/sess1" 2>/dev/null)"

# second fire must not rewrite it
touch -t 202601010000 "$MK1/sess1"
BEFORE=$(ls -l "$MK1/sess1")
(cd "$T1" && ss_stdin sess1 "$MK1" | sh "$CONTEXT") >/dev/null
check_eq "marker not rewritten on second fire" "$BEFORE" "$(ls -l "$MK1/sess1")"

# no plans/ means no marker and no output
T2="$(mktemp -d)"; MK2="$(mktemp -d)"
git -C "$T2" init -q
OUT=$(cd "$T2" && ss_stdin sess2 "$MK2" | sh "$CONTEXT")
check_empty "no plans/ means no output" "$OUT"
if [ -f "$MK2/sess2" ]; then fail "no plans/ means no marker" "marker was created"; else pass "no plans/ means no marker"; fi

# non-git project still gets a marker, with empty content
T3="$(mktemp -d)"; MK3="$(mktemp -d)"
mkdir -p "$T3/plans/active"; printf '# Status\n' > "$T3/plans/STATUS.md"
(cd "$T3" && ss_stdin sess3 "$MK3" | sh "$CONTEXT") >/dev/null
if [ -f "$MK3/sess3" ]; then pass "non-git project gets a marker"; else fail "non-git project gets a marker" "not found"; fi
check_empty "non-git marker is empty" "$(cat "$MK3/sess3" 2>/dev/null)"

# scratchpad_dir absent. Task 1 proved Claude Code 2.1.274 does not send
# this field at all, so the TMPDIR fallback is the production path and must
# be covered directly.
T4="$(mktemp -d)"; TB4="$(mktemp -d)"
ss_fixture "$T4"
OUT=$(cd "$T4" && printf '{"session_id":"sess4","cwd":"/x","hook_event_name":"SessionStart","source":"startup"}' | TMPDIR="$TB4" sh "$CONTEXT")
check_contains "no scratchpad_dir still emits rules" "plans/ convention" "$OUT"
if [ -f "$TB4/plans-hook/sess4" ]; then pass "marker falls back to TMPDIR"; else fail "marker falls back to TMPDIR" "$TB4/plans-hook/sess4 not found"; fi
check_eq "fallback marker holds HEAD" "$(git -C "$T4" rev-parse HEAD)" "$(cat "$TB4/plans-hook/sess4" 2>/dev/null)"

rm -rf "$T1" "$T2" "$T3" "$T4" "$MK1" "$MK2" "$MK3" "$TB4"

echo "=== summary ==="
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
