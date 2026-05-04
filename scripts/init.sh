#!/usr/bin/env bash
# init.sh - bootstrap the plans/ directory in a target project
#
# Usage:
#   ./init.sh                    # set up plans/ in the current directory
#   ./init.sh /path/to/project   # set up plans/ in the given directory

set -e

TARGET_DIR="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

echo ""
echo "OK: scaffolded $TARGET_DIR/plans/"
echo ""
echo "Next steps:"
echo "  1. Read $TARGET_DIR/plans/README.md"
echo "  2. Append $SOURCE/CLAUDE.md.snippet to your CLAUDE.md (or AGENTS.md / .cursorrules)"
echo "  3. Replace plans/active/EXAMPLE_PLAN.md with your real first plan"
echo "  4. Open the dashboard:"
echo "     cd $TARGET_DIR && python -m http.server 8080"
echo "     # then visit http://localhost:8080/plans/roadmap.html"
