#!/bin/sh
# Contextify Installation Script
# Copies Contextify files into a target project so slash commands and workflows work.
# Usage: ./contextify/install.sh [target-directory]

set -e

# Resolve source directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Target project directory (default: current directory)
TARGET="${1:-.}"
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

echo "Installing Contextify into: $TARGET"

# Create target directories
mkdir -p "$TARGET/.claude/commands/contextify"
mkdir -p "$TARGET/.claude/agents"
mkdir -p "$TARGET/.claude/contextify/workflows"
mkdir -p "$TARGET/.claude/contextify/references"

# Copy command files → .claude/commands/contextify/
for f in "$SCRIPT_DIR/commands/"*.md; do
  [ -f "$f" ] && cp "$f" "$TARGET/.claude/commands/contextify/"
done

# Copy agent files → .claude/agents/
for f in "$SCRIPT_DIR/agents/"*.md; do
  [ -f "$f" ] && cp "$f" "$TARGET/.claude/agents/"
done

# Copy workflows, references → .claude/contextify/
for f in "$SCRIPT_DIR/workflows/"*.md; do
  [ -f "$f" ] && cp "$f" "$TARGET/.claude/contextify/workflows/"
done

for f in "$SCRIPT_DIR/references/"*.md; do
  [ -f "$f" ] && cp "$f" "$TARGET/.claude/contextify/references/"
done

# Copy README
[ -f "$SCRIPT_DIR/README.md" ] && cp "$SCRIPT_DIR/README.md" "$TARGET/.claude/contextify/README.md"

echo ""
echo "Contextify installed successfully!"
echo ""
echo "Installed structure:"
echo "  $TARGET/.claude/commands/contextify/  (slash commands)"
echo "  $TARGET/.claude/agents/               (named subagents)"
echo "  $TARGET/.claude/contextify/           (workflows, references)"
echo ""
echo "Usage: In Claude Code, run /contextify:enhance or /contextify:settings"
