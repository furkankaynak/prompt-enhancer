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
/pe:enhance "Build a todo app" --auto
/pe:enhance "Sort an array" --quick
/pe:settings set --strictness=high --rounds=2
/pe:settings set --auto=true
/pe:settings reset-history
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

```
pe/
├── commands/           # Command entry points (copy to .claude/commands/pe/)
│   ├── enhance.md      # /pe:enhance — main enhancement command
│   └── settings.md     # /pe:settings — project defaults management
├── agents/             # Named subagents (copy to .claude/agents/)
│   ├── pe-researcher.md          # Data gathering (prompts.chat + web)
│   ├── pe-research-synth.md      # Research brief synthesis
│   ├── pe-generator.md           # Candidate generation
│   ├── pe-scorer.md              # Hybrid B scoring + critique
│   ├── pe-synthesizer.md         # Crossover + mutation
│   ├── pe-presenter.md           # Portfolio selection + output
│   └── pe-learner.md             # Cross-run learning capture
├── workflows/          # Stage instructions — source of truth for subagents
│   ├── enhance-orchestrator.md   # Core orchestration + compact subagent dispatch
│   ├── research.md               # Dual-source research (includes API reference)
│   ├── generate.md               # Candidate generation (learning-biased strategies)
│   ├── score-bundle.md           # Hybrid B scoring + rubric tables (merged)
│   ├── synthesize.md             # Crossover/mutation for next round
│   ├── select-present.md         # Portfolio selection + output templates (merged)
│   └── learning.md               # Cross-run learning (capture + preferences)
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
- **Cross-run learning** — remembers which alternatives you pick, biases future generation toward your preferred strategies
- **Named subagents** — each optimization stage runs as a dedicated subagent with pre-configured model and tools, keeping the orchestrator lean
- **Auto/Quick modes** — `--auto` skips gates for fast results; `--quick` is a single-round prompt clinic

## Inspired By

- [PromptWizard](https://arxiv.org/abs/2405.18369) — iterative prompt optimization through generate/evaluate/critique/synthesize loops
- Context engineering principles — high-signal, compact context over verbose prompting
- Prompt anatomy framework — task + context + examples + rules + success criteria
