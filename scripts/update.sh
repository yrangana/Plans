#!/usr/bin/env bash
# update.sh - update system files in an existing plans/ installation
#
# Usage:
#   plans-update                           # update plans/ in current directory
#   plans-update /path/to/project          # update plans/ in given directory
#   plans-update --no-pull /path/to/proj   # skip git pull (use local source as-is)
#
# What it updates (system files, overwrite-safe):
#   plans/roadmap.html, plans/README.md, .claude/skills/plans/, .agents/skills/plans/
#
# What it preserves (user-owned, never touched):
#   plans/STATUS.md, plans.json, active/, shipped/, superseded/, anything else

set -e

SELF="$0"
while [ -L "$SELF" ]; do SELF="$(readlink "$SELF")"; done
SCRIPT_DIR="$(cd "$(dirname "$SELF")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse args
PULL=1
TARGET_DIR=""
for arg in "$@"; do
  case "$arg" in
    --no-pull) PULL=0 ;;
    -h|--help)
      sed -n '2,11p' "$SELF" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) TARGET_DIR="$arg" ;;
  esac
done
TARGET_DIR="${TARGET_DIR:-$(pwd)}"
SOURCE="$REPO_DIR/template"

# Auto-pull from origin if this is a git clone (and not --no-pull)
if [ "$PULL" = "1" ] && [ -d "$REPO_DIR/.git" ]; then
  echo "Pulling latest from plans repo..."
  if (cd "$REPO_DIR" && git pull --quiet 2>/dev/null); then
    echo "OK: plans repo is up to date."
  else
    echo "Warning: git pull failed (offline, dirty tree, or no remote). Using local source."
  fi
  echo ""
fi

if [ ! -d "$TARGET_DIR/plans" ]; then
  echo "Error: $TARGET_DIR/plans does not exist."
  echo "Run plans-init first to set up plans/ in this project."
  exit 1
fi

if [ ! -f "$SOURCE/plans/roadmap.html" ]; then
  echo "Error: cannot find source template at $SOURCE/plans/roadmap.html"
  exit 1
fi

# System files that update.sh manages
UPDATE_FILES=(
  "plans/roadmap.html"
  "plans/README.md"
)

echo "Plans system update for: $TARGET_DIR/plans"
echo ""
echo "Will check these system files for updates:"
for f in "${UPDATE_FILES[@]}"; do
  echo "  - $f"
done
echo ""
echo "User data is never touched: STATUS.md, plans.json, active/, shipped/, superseded/"
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
    diff -u "$dest_file" "$src_file" | head -40 | sed 's/^/    /' || true
    echo ""
    HAS_CHANGES=1
  fi
done

# Update the /plans skill (check both Claude Code and Antigravity locations)
SKILL_SRC="$REPO_DIR/template/skills/plans"

# Skill version, read from SKILL.md frontmatter (empty if not found)
SKILL_VERSION="$(sed -n 's/^version: *//p' "$SKILL_SRC/SKILL.md" 2>/dev/null | head -1)"

update_skill() {
  local dest="$1"
  if [ ! -d "$dest" ]; then
    return
  fi
  echo ""
  if diff -rq "$SKILL_SRC" "$dest" > /dev/null 2>&1; then
    echo "= $dest (already up to date)"
  else
    echo "~ $dest (skill update available)"
    read -p "Update /plans skill at $dest? (y/n) " skill_confirm
    if [ "$skill_confirm" = "y" ]; then
      cp -r "$SKILL_SRC/." "$dest/"
      echo "Updated:   $dest"
      if [ -n "$SKILL_VERSION" ]; then
        echo "Skill updated to v$SKILL_VERSION. Run /plans sync to apply any STATUS.md structure changes."
      else
        echo "Run /plans sync to apply any STATUS.md structure changes."
      fi
    else
      echo "Skipped skill update."
    fi
  fi
}

update_skill "$TARGET_DIR/.claude/skills/plans"
update_skill "$TARGET_DIR/.agents/skills/plans"

if [ "$HAS_CHANGES" = "0" ]; then
  echo ""
  echo "Nothing to update. You are current."
  exit 0
fi

echo ""
echo "Note: if you customized roadmap.html (e.g., colors), those changes will be lost."
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
