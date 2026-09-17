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

echo "=== summary ==="
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
