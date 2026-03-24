# Contextify

Multi-round prompt-to-context transformation for AI coding assistants. Takes any prompt and produces a ranked output package with winner, safe alternative, exploratory alternative, change log, and scoring rationale.

## Quick Start

### Claude Code

Open a fresh Claude Code session in your project and paste:

```
Fetch and follow instructions from https://raw.githubusercontent.com/furkankaynak/prompt-enhancer/refs/heads/master/INSTALL.md and install it
```

Then run: `/contextify:enhance "your prompt here"`

### Usage

```
/contextify:enhance "I want to build a zombie tower defense game with React.js"
/contextify:enhance "Write a REST API for user management" --strictness=high
/contextify:enhance "Explain async/await" --no-research --output=diff
/contextify:enhance "Build a todo app" --auto
/contextify:enhance "Sort an array" --quick
/contextify:settings set --strictness=high --rounds=2
/contextify:settings set --auto=true
/contextify:settings reset-history
```

### Flags

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--auto` | — | off | Skip clarification + alignment gate (fast path) |
| `--quick` | — | off | Alias for `--auto --no-research --rounds=1 --output=diff` |
| `--no-research` | — | research on | Skip external research |
| `--strictness` | low, balanced, high | balanced | How aggressively to rewrite |
| `--rounds` | 1-3 | 3 | Maximum optimization rounds |
| `--output` | full, diff, annotated | full | Output format |

## How It Works

```
User Prompt → Confidence Check → [Clarify] → Alignment Gate → [Research] → Optimization Loop → Output Package → Learning Capture
```

1. **Confidence check** — scores the prompt on 5 dimensions (specificity, output clarity, audience, constraints, success criteria)
2. **Clarification** — if confidence is low, asks exactly one targeted question (auto mode: only if confidence < 0.3)
3. **Alignment gate** — presents enhancement plan for user approval (skipped in auto/quick mode)
4. **Research** — dual-source retrieval from prompts.chat API and web search (optional, default on)
5. **Optimization loop** — up to 3 rounds of generate → score/critique → synthesize with convergence detection
6. **Output** — winner + safe alternative + exploratory alternative + change log + scoring summary
7. **Learning capture** — records which option you pick; biases future runs toward your preferred strategies

## Architecture

Installs entirely under `.claude/` — no files added to your project root:

```
.claude/
├── commands/contextify/
│   ├── enhance.md        # /contextify:enhance — main transformation command
│   └── settings.md       # /contextify:settings — project defaults management
├── agents/
│   └── contextify-*.md   # 7 named subagents (researcher, generator, scorer, …)
└── contextify/
    ├── workflows/         # Stage instructions — source of truth for subagents
    │   ├── enhance-orchestrator.md
    │   ├── research.md
    │   ├── generate.md
    │   ├── score-bundle.md
    │   ├── synthesize.md
    │   ├── select-present.md
    │   └── learning.md
    └── references/
        └── data-contracts.md
.contextify/               # Runtime data (auto-created, gitignored)
├── settings.json
└── history.json
```

## Key Concepts

- **Prompt-driven** — no compiled code; the LLM follows structured instructions in workflow files
- **Intent lock** — every round verifies candidates preserve the user's original intent and constraints
- **Hybrid B scoring** — combines behavioral eval-set scoring with rubric quality judging
- **Convergence detection** — stops early if scores plateau (< 1% improvement between rounds)
- **Degraded mode** — continues gracefully if external research sources are unavailable
- **Original anchor** — the user's original prompt always survives as a reference baseline
- **Cross-run learning** — remembers which alternatives you pick, biases future generation toward your preferred strategies
- **Named subagents** — each optimization stage runs as a dedicated subagent with pre-configured model and tools, keeping the orchestrator lean
- **Auto/Quick modes** — `--auto` skips gates for fast results; `--quick` is a single-round prompt clinic

## Inspired By

- [PromptWizard](https://arxiv.org/abs/2405.18369) — iterative prompt optimization through generate/evaluate/critique/synthesize loops
- Context engineering principles — high-signal, compact context over verbose prompting
- Prompt anatomy framework — task + context + examples + rules + success criteria
