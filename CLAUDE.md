# PE — Project Guide for Claude Code

## What PE Is

PE (Prompt Enhancer) is a prompt-only, multi-round prompt optimization system. Zero compiled code — all logic is markdown workflow instructions executed by the LLM. Runs as slash commands (`/pe:enhance`, `/pe:settings`) inside AI coding assistants. Takes any prompt, runs iterative optimization (generate → score/critique → synthesize), and outputs a ranked portfolio: winner + safe alternative + exploratory alternative + change log + scoring summary.

## Folder Structure

```
pe/
├── commands/                        # Entry points — copy to .claude/commands/pe/
│   ├── enhance.md                   # /pe:enhance — loads orchestrator only + Agent tool
│   └── settings.md                  # /pe:settings — per-project defaults (.pe/settings.json)
├── workflows/                       # Stage instructions — loaded by subagents on-demand
│   ├── enhance-orchestrator.md      # Master flow — sections 1-7, subagent dispatch
│   ├── research.md                  # Dual-source research (includes API reference)
│   ├── generate.md                  # 3 strategy variants + original anchor = 4 candidates
│   ├── score-bundle.md              # Scoring + rubric tables (merged)
│   ├── synthesize.md                # Crossover + mutation from survivors
│   └── select-present.md           # Portfolio selection + output templates (merged)
├── references/                      # On-demand — subagents Read when needed
│   └── data-contracts.md            # Full schema shapes for internal artifacts
├── .docs/                           # Product docs (PRD.md, PRODUCT-DESIGN.md)
├── README.md                        # User-facing overview and quick start
└── install.sh                       # POSIX installer
```

## System Workflow

```
  /pe:enhance "prompt" ──► Parse Args
                              │
                    ┌─────────▼──────────┐
                    │ Confidence Check    │ Score 5 dimensions (0-1 each)
                    │ (specificity,       │ Confidence = average
                    │  output clarity,    │
                    │  audience, constr., │
                    │  success criteria)  │
                    └─────────┬──────────┘
                              │
                 confidence < 0.6?
                  YES ──► Ask ONE clarification question ──┐
                   NO ────────────────────────────────────►│
                              │◄───────────────────────────┘
                    ┌─────────▼──────────┐
                    │ Alignment Gate      │ Build LockContract, present plan
                    │ (USER MUST APPROVE) │ User can adjust settings/constraints
                    └─────────┬──────────┘
                              │
                 research enabled?
                  YES ──► Research (prompts.chat + web) ──┐
                   NO ───────────────────────────────────►│
                              │◄──────────────────────────┘
                    ┌─────────▼──────────┐
                    │ OPTIMIZATION LOOP   │ Up to 3 rounds
                    │                     │
                    │  Generate ──────►   │ Round 0: 3 variants + original
                    │  Score/Critique ►   │ Hybrid B + lock check + critique
                    │  Synthesize ────►   │ Crossover + mutation from survivors
                    │                     │
                    │  Convergence? ──►   │ < 1% improvement at round >= 2 → stop
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │ Select & Present    │ Winner + Alt A (safe) + Alt B (exploratory)
                    │                     │ + change log + scoring summary
                    └─────────────────────┘
```

## How Execution Works

- **Entry**: `/pe:enhance "prompt"` → `commands/enhance.md` loads only the orchestrator via `@` reference
- **Orchestrator is master**: `workflows/enhance-orchestrator.md` controls the entire flow — sections 1-4 run inline, sections 5-7 dispatch subagents
- **Subagent dispatch**: Compute-heavy stages (research, generate, score, synthesize, select) run as Agent tool calls. Each subagent Reads only its needed workflow file + data-contracts.md. Main thread stays lean (~4,500 tokens).
- **Model selection**: Generate/Synthesize use haiku (lightweight). Research/Score/Select use sonnet (analytical depth).
- **Fallback**: If Agent tool unavailable, orchestrator Reads workflow files and executes inline (preserves monolithic behavior)
- **Context compaction**: Between rounds, carry forward ONLY the `RoundContext` (survivors + tombstones + original prompt + lock contract)
- **Convergence**: At round >= 2, if top score improves < 1% over previous round, stop early
- **Degraded mode**: If prompts.chat or web search fails, note it and continue — research is supplemental, never blocking

## Key Contracts

Full schemas in `references/data-contracts.md`. Essentials:

| Contract | Purpose | Key Fields |
|----------|---------|------------|
| **LockContract** | Immutable intent — checked every round | goal, must_haves, forbidden_changes, success_criteria |
| **Candidate** | A single prompt variant | id, text, strategyLabel, isOriginal |
| **RoundContext** | ALL that travels between rounds | survivors, tombstones, originalPrompt, lockContract |
| **ScoreBreakdown** | Hybrid B score per candidate | evalSetScore (0-1), rubricScore (0-1), totalScore |

**Scoring formula**: `totalScore = 0.5 * evalSetScore + 0.5 * rubricScore`

**Survivor policy**: Top 4 by score. Original (`c-original`) always survives. Lock violators excluded.

**Domains**: `coding`, `writing`, `data`, `general` — each has its own eval scenarios and rubric dimensions in `score-bundle.md`.

## Do

- Follow `enhance-orchestrator.md` sections in order — never skip or reorder
- Always get user approval at the alignment gate (Section 4) before optimization
- Re-inject the original prompt as `c-original` every round — it never leaves the pool
- Check every candidate against the lock contract every round — exclude violators as tombstones
- Stop early on convergence (< 1% score improvement between rounds, round >= 2)
- Continue in degraded mode if research sources fail — note it, don't block
- Present 3 portfolio choices (winner + safe + exploratory) with change log and scoring
- Keep round carry-forward compact — only `RoundContext` fields survive between rounds

## Don't

- Don't skip the alignment gate — user must approve the enhancement plan
- Don't ask more than ONE clarification question (single-question ceiling)
- Don't carry raw research content, full critique history, or eliminated candidate texts between rounds
- Don't copy retrieved research content verbatim — extract patterns only
- Don't eliminate the original prompt from the candidate pool — it always survives
- Don't exceed 3 optimization rounds
- Don't present lock-violating candidates in the final portfolio
- Don't modify workflow files during execution — they are the source of truth
- Don't preload reference files into context — subagents load them on-demand
- Don't bypass subagent dispatch unless Agent tool is genuinely unavailable
