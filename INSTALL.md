# PE Installation Guide

PE (Prompt Enhancer) is a prompt-only system — all markdown files, no compiled code.

## Preferred: Script Installation

Run from the PE source directory:

```sh
chmod +x pe/install.sh
./pe/install.sh /path/to/your/project
```

If you're already inside the target project and have the PE source elsewhere:

```sh
/path/to/pe/install.sh .
```

The script is idempotent — safe to run multiple times to update.

## Manual Installation

If the script is unavailable, copy files manually:

### Step 1: Copy command files

Copy all `.md` files from `pe/commands/` to `<project>/.claude/commands/pe/`:

```
pe/commands/enhance.md  →  <project>/.claude/commands/pe/enhance.md
pe/commands/settings.md →  <project>/.claude/commands/pe/settings.md
```

### Step 2: Copy PE resources

Copy these directories to `<project>/pe/`:

```
pe/workflows/   →  <project>/pe/workflows/
pe/references/  →  <project>/pe/references/
pe/README.md    →  <project>/pe/README.md
```

### Step 3: Do NOT copy

Skip `install.sh` and `INSTALL.md` — they are not needed in the target project.

## Verification

After installation, confirm the following exist in your project:

- `.claude/commands/pe/enhance.md`
- `.claude/commands/pe/settings.md`
- `pe/workflows/` (contains orchestrator, research, generate, score-bundle, synthesize, select-present)
- `pe/references/` (contains data-contracts)

Then open Claude Code in the project and run `/pe:enhance` — the command should be available.

## How It Works

The command file in `.claude/commands/pe/enhance.md` references only `@./pe/workflows/enhance-orchestrator.md`. The orchestrator dispatches subagents that Read workflow files on-demand. All paths resolve relative to the project root, which is why the `pe/` directory must sit at the project root.
