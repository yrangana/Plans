#!/usr/bin/env bash
# update.sh - update system files in an existing plans/ installation
#
# Usage:
#   ./update.sh                    # update plans/ in current directory
#   ./update.sh /path/to/project   # update plans/ in given directory
#
# What it updates (system files, overwrite-safe):
#   plans/roadmap.html             # the interactive dashboard
#
# What it preserves (user-owned, never touched):
#   plans/STATUS.md
#   plans/plans.json
#   plans/active/
#   plans/shipped/
#   plans/README.md                # may contain user customizations
#   anything else you've added
#
# Tip: run `git pull` in the plans repo first to get the latest source.

set -e

TARGET_DIR="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$(cd "$SCRIPT_DIR/../template" && pwd)"

if [ ! -d "$TARGET_DIR/plans" ]; then
  echo "Error: $TARGET_DIR/plans does not exist."
  echo "Run init.sh first to set up plans/ in this project."
  exit 1
fi

if [ ! -f "$SOURCE/plans/roadmap.html" ]; then
  echo "Error: cannot find source template at $SOURCE/plans/roadmap.html"
  exit 1
fi

# System files that update.sh manages
UPDATE_FILES=(
  "plans/roadmap.html"
)

echo "Plans system update for: $TARGET_DIR/plans"
echo ""
echo "Will check these system files for updates:"
for f in "${UPDATE_FILES[@]}"; do
  echo "  - $f"
done
echo ""
echo "User data is never touched: STATUS.md, plans.json, active/, shipped/, README.md"
echo ""

# Show diffs
HAS_CHANGES=0
for f in "${UPDATE_FILES[@]}"; do
  src_file="$SOURCE/$f"
  dest_file="$TARGET_DIR/$f"
  if [ ! -f "$dest_file" ]; then
    echo "+ $f (will be created)"
    HAS_CHANGES=1
    continue
  fi
  if cmp -s "$src_file" "$dest_file"; then
    echo "= $f (already up to date)"
  else
    echo "~ $f (changes available, preview:)"
    diff -u "$dest_file" "$src_file" | head -40 | sed 's/^/    /'
    echo ""
    HAS_CHANGES=1
  fi
done

if [ "$HAS_CHANGES" = "0" ]; then
  echo ""
  echo "Nothing to update. You are current."
  exit 0
fi

echo ""
echo "Note: if you customized roadmap.html (e.g., page title, colors), those changes will be lost."
echo "      A backup will be saved as <filename>.bak so you can restore."
echo ""
read -p "Apply updates? (y/n) " confirm
if [ "$confirm" != "y" ]; then
  echo "Aborted. No files changed."
  exit 0
fi

for f in "${UPDATE_FILES[@]}"; do
  src_file="$SOURCE/$f"
  dest_file="$TARGET_DIR/$f"
  if [ -f "$dest_file" ] && ! cmp -s "$src_file" "$dest_file"; then
    cp "$dest_file" "$dest_file.bak"
    echo "Backed up: $dest_file.bak"
  fi
  cp "$src_file" "$dest_file"
  echo "Updated:   $dest_file"
done

echo ""
echo "Done. Refresh your dashboard to see changes."
echo "If something looks wrong, restore from the .bak file."
