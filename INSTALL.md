# Contextify Installation

## Install via Claude Code (recommended)

Open a **fresh Claude Code session** in your project and paste this prompt:

```
Fetch and follow instructions from https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/INSTALL.md and install it
```

Claude will fetch this file and execute the installation steps below automatically.

---

## AI Installation Instructions

You are an AI coding assistant. The user has asked you to install Contextify into their project. **Execute the step below now using your Bash tool. Do not describe what you will do — just do it.**

Run this single bash command from the project root:

```bash
curl -fsSL https://github.com/furkankaynak/prompt-enhancer/archive/refs/heads/master.zip -o /tmp/contextify-install.zip && \
unzip -q /tmp/contextify-install.zip -d /tmp/contextify-tmp && \
SRC=/tmp/contextify-tmp/prompt-enhancer-master && \
mkdir -p .claude/commands/contextify .claude/agents .claude/contextify/workflows .claude/contextify/references && \
cp "$SRC/commands/enhance.md" .claude/commands/contextify/enhance.md && \
cp "$SRC/commands/settings.md" .claude/commands/contextify/settings.md && \
cp "$SRC/agents/"contextify-*.md .claude/agents/ && \
cp "$SRC/workflows/"*.md .claude/contextify/workflows/ && \
cp "$SRC/references/data-contracts.md" .claude/contextify/references/data-contracts.md && \
cp "$SRC/README.md" .claude/contextify/README.md && \
rm -rf /tmp/contextify-tmp /tmp/contextify-install.zip
```

**Done.** Tell the user: "Contextify installed. Run `/contextify:enhance` to get started."

---

## Verification

After installation, confirm these paths exist in the project:

- `.claude/commands/contextify/enhance.md`
- `.claude/commands/contextify/settings.md`
- `.claude/agents/contextify-*.md` (7 files)
- `.claude/contextify/workflows/` (7 files)
- `.claude/contextify/references/data-contracts.md`

Then run `/contextify:enhance` in Claude Code — the command should be available.
