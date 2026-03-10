#!/bin/sh
# PE (Prompt Enhancer) Installation Script
# Copies PE files into a target project so slash commands and workflows work.
# Usage: ./pe/install.sh [target-directory]

set -e

# Resolve source directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Target project directory (default: current directory)
TARGET="${1:-.}"
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

echo "Installing PE into: $TARGET"

# Create target directories
mkdir -p "$TARGET/.claude/commands/pe"
mkdir -p "$TARGET/pe/workflows"
mkdir -p "$TARGET/pe/references"
mkdir -p "$TARGET/pe/templates"

# Copy command files → .claude/commands/pe/
for f in "$SCRIPT_DIR/commands/"*.md; do
  [ -f "$f" ] && cp "$f" "$TARGET/.claude/commands/pe/"
done

# Copy workflows, references, templates → pe/
for f in "$SCRIPT_DIR/workflows/"*.md; do
  [ -f "$f" ] && cp "$f" "$TARGET/pe/workflows/"
done

for f in "$SCRIPT_DIR/references/"*.md; do
  [ -f "$f" ] && cp "$f" "$TARGET/pe/references/"
done

for f in "$SCRIPT_DIR/templates/"*.md; do
  [ -f "$f" ] && cp "$f" "$TARGET/pe/templates/"
done

# Copy README
[ -f "$SCRIPT_DIR/README.md" ] && cp "$SCRIPT_DIR/README.md" "$TARGET/pe/README.md"

echo ""
echo "PE installed successfully!"
echo ""
echo "Installed structure:"
echo "  $TARGET/.claude/commands/pe/  (slash commands)"
echo "  $TARGET/pe/                   (workflows, references, templates)"
echo ""
echo "Usage: In Claude Code, run /pe:enhance or /pe:settings"
