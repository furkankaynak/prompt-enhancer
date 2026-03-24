# Contextify Installation

## Install via Claude Code (recommended)

Open a **fresh Claude Code session** in your project and paste this prompt:

```
Fetch and follow instructions from https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/INSTALL.md and install it
```

Claude will fetch this file and execute the installation steps below automatically.

---

## AI Installation Instructions

You are an AI coding assistant. The user has asked you to install Contextify into their project. **Execute every step below now using your tools. Do not describe what you will do — just do it.**

For each numbered item: use WebFetch to download the URL, then use Write to save the exact content to the local path shown (relative to the current project root).

**Commands**

1. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/commands/enhance.md`
   → Write to `.claude/commands/contextify/enhance.md`

2. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/commands/settings.md`
   → Write to `.claude/commands/contextify/settings.md`

**Agents**

3. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/agents/contextify-researcher.md`
   → Write to `.claude/agents/contextify-researcher.md`

4. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/agents/contextify-research-synth.md`
   → Write to `.claude/agents/contextify-research-synth.md`

5. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/agents/contextify-generator.md`
   → Write to `.claude/agents/contextify-generator.md`

6. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/agents/contextify-scorer.md`
   → Write to `.claude/agents/contextify-scorer.md`

7. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/agents/contextify-synthesizer.md`
   → Write to `.claude/agents/contextify-synthesizer.md`

8. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/agents/contextify-presenter.md`
   → Write to `.claude/agents/contextify-presenter.md`

9. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/agents/contextify-learner.md`
   → Write to `.claude/agents/contextify-learner.md`

**Workflows**

10. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/workflows/enhance-orchestrator.md`
    → Write to `.claude/contextify/workflows/enhance-orchestrator.md`

11. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/workflows/research.md`
    → Write to `.claude/contextify/workflows/research.md`

12. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/workflows/generate.md`
    → Write to `.claude/contextify/workflows/generate.md`

13. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/workflows/score-bundle.md`
    → Write to `.claude/contextify/workflows/score-bundle.md`

14. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/workflows/synthesize.md`
    → Write to `.claude/contextify/workflows/synthesize.md`

15. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/workflows/select-present.md`
    → Write to `.claude/contextify/workflows/select-present.md`

16. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/workflows/learning.md`
    → Write to `.claude/contextify/workflows/learning.md`

**References and README**

17. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/references/data-contracts.md`
    → Write to `.claude/contextify/references/data-contracts.md`

18. WebFetch `https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/README.md`
    → Write to `.claude/contextify/README.md`

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
