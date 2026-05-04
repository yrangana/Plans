#!/usr/bin/env bash
# install.sh - bootstrap the plans system on a developer's machine
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/yrangana/Plans/main/install.sh | bash
#
# Or with custom install location:
#   PLANS_DIR=/opt/plans curl -sSL https://raw.githubusercontent.com/yrangana/Plans/main/install.sh | bash
#
# What it does:
#   1. Clone (or pull if exists) the plans repo to ~/.local/share/plans
#   2. Symlink plans-init and plans-update commands into ~/.local/bin/
#   3. Print usage instructions

set -e

REPO_URL="${PLANS_REPO:-https://github.com/yrangana/Plans.git}"
INSTALL_DIR="${PLANS_DIR:-$HOME/.local/share/plans}"
BIN_DIR="${PLANS_BIN:-$HOME/.local/bin}"

echo "Plans system installer"
echo ""

# Check git is available
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required. Install git first."
  exit 1
fi

# Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "Plans already installed at $INSTALL_DIR. Pulling latest..."
  (cd "$INSTALL_DIR" && git pull --quiet) || {
    echo "Warning: git pull failed. Using existing local copy."
  }
else
  echo "Cloning plans into $INSTALL_DIR..."
  git clone --quiet "$REPO_URL" "$INSTALL_DIR"
fi

# Make scripts executable
chmod +x "$INSTALL_DIR/scripts/"*.sh

# Symlink to bin
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/scripts/init.sh"   "$BIN_DIR/plans-init"
ln -sf "$INSTALL_DIR/scripts/update.sh" "$BIN_DIR/plans-update"

echo ""
echo "Installed to $INSTALL_DIR"
echo "Symlinks:    $BIN_DIR/plans-init, $BIN_DIR/plans-update"
echo ""

# PATH check
if ! echo ":$PATH:" | grep -q ":$BIN_DIR:"; then
  echo "Note: $BIN_DIR is not in your PATH. Add this to your shell rc:"
  echo ""
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
  echo ""
fi

echo "Usage:"
echo "  plans-init [/path/to/project]      # set up plans/ in a project"
echo "  plans-update [/path/to/project]    # update an existing plans/"
echo ""
echo "Re-run this installer any time to update the plans system itself."
