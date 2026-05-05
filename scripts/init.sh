#!/usr/bin/env bash
# init.sh - bootstrap the plans/ directory in a target project
#
# Usage:
#   plans-init                           # set up plans/ in the current directory
#   plans-init /path/to/project          # set up plans/ in the given directory
#   plans-init --no-snippet              # skip auto-append to AI instruction file

set -e

SELF="$0"
while [ -L "$SELF" ]; do SELF="$(readlink "$SELF")"; done
SCRIPT_DIR="$(cd "$(dirname "$SELF")" && pwd)"

# Parse args
NO_SNIPPET=0
TARGET_DIR=""
for arg in "$@"; do
  case "$arg" in
    --no-snippet) NO_SNIPPET=1 ;;
    -h|--help)
      sed -n '2,7p' "$SELF" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) TARGET_DIR="$arg" ;;
  esac
done
TARGET_DIR="${TARGET_DIR:-$(pwd)}"

if [ ! -d "$SCRIPT_DIR/../template/plans" ]; then
  echo "Error: cannot find template at $SCRIPT_DIR/../template/plans"
  exit 1
fi

SOURCE="$(cd "$SCRIPT_DIR/../template" && pwd)"

if [ -d "$TARGET_DIR/plans" ]; then
  echo "Error: $TARGET_DIR/plans already exists. Aborting."
  exit 1
fi

cp -r "$SOURCE/plans" "$TARGET_DIR/plans"

# Add to git exclude (local, not committed)
if [ -d "$TARGET_DIR/.git" ]; then
  mkdir -p "$TARGET_DIR/.git/info"
  if ! grep -q "^plans/$" "$TARGET_DIR/.git/info/exclude" 2>/dev/null; then
    echo "plans/" >> "$TARGET_DIR/.git/info/exclude"
  fi
  echo "OK: plans/ added to .git/info/exclude"
fi

echo "OK: scaffolded $TARGET_DIR/plans/"
echo ""

# Detect AI instruction files and offer to append the snippet
SNIPPET_MARKER="## Project Status & Plan Management"
SNIPPET_FILE="$SOURCE/CLAUDE.md.snippet"
AI_CANDIDATES=("CLAUDE.md" "AGENTS.md" ".cursorrules" ".windsurfrules")

append_snippet_to() {
  local target="$1"
  # Strip the leading HTML comment from the snippet, append from the first ## heading onward
  echo "" >> "$target"
  awk 'found || /^## /{found=1; print}' "$SNIPPET_FILE" >> "$target"
  echo "OK: appended plans section to $target"
}

if [ "$NO_SNIPPET" = "1" ]; then
  echo "Skipping AI instruction file detection (--no-snippet)."
else
  FOUND_FILES=()
  for f in "${AI_CANDIDATES[@]}"; do
    if [ -f "$TARGET_DIR/$f" ]; then
      FOUND_FILES+=("$f")
    fi
  done

  if [ ${#FOUND_FILES[@]} -eq 0 ]; then
    echo "No AI instruction file detected ($(IFS=', '; echo "${AI_CANDIDATES[*]}"))."
    echo "When you create one, append this section to it:"
    echo "---"
    awk 'found || /^## /{found=1; print}' "$SNIPPET_FILE"
    echo "---"
    echo ""
  else
    for f in "${FOUND_FILES[@]}"; do
      target="$TARGET_DIR/$f"
      if grep -q "$SNIPPET_MARKER" "$target" 2>/dev/null; then
        echo "OK: $f already has the plans section, skipping."
        continue
      fi
      echo "Detected $f."
      read -p "Append plans section to $f? (y/n) " confirm
      if [ "$confirm" = "y" ]; then
        append_snippet_to "$target"
      else
        echo "Skipped $f."
      fi
    done
  fi
fi

echo ""
echo "Next steps:"
echo "  1. Read $TARGET_DIR/plans/README.md"
echo "  2. Replace plans/active/EXAMPLE_PLAN.md with your real first plan"
echo "  3. Open the dashboard:"
echo "     cd $TARGET_DIR && python -m http.server 8080"
echo "     # then visit http://localhost:8080/plans/roadmap.html"
