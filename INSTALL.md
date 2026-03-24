# Contextify Installation Guide

Contextify is a prompt-only system — all markdown files, no compiled code.

## Preferred: Script Installation

Run from the Contextify source directory:

```sh
chmod +x contextify/install.sh
./contextify/install.sh /path/to/your/project
```

If you have the Contextify source elsewhere:

```sh
/path/to/contextify/install.sh .
```

The script is idempotent — safe to run multiple times to update.

## Manual Installation

If the script is unavailable, copy files manually:

### Step 1: Copy command files

Copy all `.md` files from `contextify/commands/` to `<project>/.claude/commands/contextify/`:

```
contextify/commands/enhance.md  →  <project>/.claude/commands/contextify/enhance.md
contextify/commands/settings.md →  <project>/.claude/commands/contextify/settings.md
```

### Step 2: Copy Contextify resources

Copy these directories to `<project>/contextify/`:

```
contextify/workflows/   →  <project>/contextify/workflows/
contextify/references/  →  <project>/contextify/references/
contextify/README.md    →  <project>/contextify/README.md
```

### Step 3: Do NOT copy

Skip `install.sh` and `INSTALL.md` — they are not needed in the target project.

## Verification

After installation, confirm the following exist in your project:

- `.claude/commands/contextify/enhance.md`
- `.claude/commands/contextify/settings.md`
- `contextify/workflows/` (contains orchestrator, research, generate, score-bundle, synthesize, select-present)
- `contextify/references/` (contains data-contracts)

Then open Claude Code in the project and run `/contextify:enhance` — the command should be available.

## How It Works

The command file in `.claude/commands/contextify/enhance.md` references only `@./contextify/workflows/enhance-orchestrator.md`. The orchestrator dispatches subagents that Read workflow files on-demand. All paths resolve relative to the project root, which is why the `contextify/` directory must sit at the project root.
