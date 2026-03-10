# PE — Prompt Enhancer

Multi-round prompt optimization for AI coding assistants. Takes any prompt and produces a ranked output package with winner, safe alternative, exploratory alternative, change log, and scoring rationale.

## Quick Start

### Claude Code

1. Copy `pe/commands/*.md` into your project's `.claude/commands/pe/` directory
2. Copy the `pe/` folder into your project root
3. Run: `/pe:enhance "your prompt here"`

### Usage

```
/pe:enhance "I want to build a zombie tower defense game with React.js"
/pe:enhance "Write a REST API for user management" --strictness=high
/pe:enhance "Explain async/await" --no-research --output=diff
/pe:settings set --strictness=high --rounds=2
```

### Flags

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--no-research` | — | research on | Skip external research |
| `--strictness` | low, balanced, high | balanced | How aggressively to rewrite |
| `--rounds` | 1-3 | 3 | Maximum optimization rounds |
| `--output` | full, diff, annotated | full | Output format |

## How It Works

```
User Prompt → Confidence Check → [Clarify] → Alignment Gate → [Research] → Optimization Loop → Output Package
```

1. **Confidence check** — scores the prompt on 5 dimensions (specificity, output clarity, audience, constraints, success criteria)
2. **Clarification** — if confidence is low, asks exactly one targeted question
3. **Alignment gate** — presents enhancement plan for user approval before optimization begins
4. **Research** — dual-source retrieval from prompts.chat API and web search (optional, default on)
5. **Optimization loop** — up to 3 rounds of generate → score/critique → synthesize with convergence detection
6. **Output** — winner + safe alternative + exploratory alternative + change log + scoring summary

## Architecture

```
pe/
├── commands/           # Command entry points (copy to .claude/commands/pe/)
│   ├── enhance.md      # /pe:enhance — main enhancement command
│   └── settings.md     # /pe:settings — project defaults management
├── workflows/          # Stage instructions — loaded by subagents on-demand
│   ├── enhance-orchestrator.md   # Core orchestration + subagent dispatch
│   ├── research.md               # Dual-source research (includes API reference)
│   ├── generate.md               # Candidate generation (3 strategies + original)
│   ├── score-bundle.md           # Hybrid B scoring + rubric tables (merged)
│   ├── synthesize.md             # Crossover/mutation for next round
│   └── select-present.md         # Portfolio selection + output templates (merged)
└── references/         # Shared reference — subagents Read on-demand
    └── data-contracts.md         # Schema shapes for internal artifacts
```

## Key Concepts

- **Prompt-driven** — no compiled code; the LLM follows structured instructions in workflow files
- **Intent lock** — every round verifies candidates preserve the user's original intent and constraints
- **Hybrid B scoring** — combines behavioral eval-set scoring with rubric quality judging
- **Convergence detection** — stops early if scores plateau (< 1% improvement between rounds)
- **Degraded mode** — continues gracefully if external research sources are unavailable
- **Original anchor** — the user's original prompt always survives as a reference baseline

## Inspired By

- [PromptWizard](https://arxiv.org/abs/2405.18369) — iterative prompt optimization through generate/evaluate/critique/synthesize loops
- Context engineering principles — high-signal, compact context over verbose prompting
- Prompt anatomy framework — task + context + examples + rules + success criteria
