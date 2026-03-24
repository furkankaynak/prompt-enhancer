# Contextify — Project Guide for Claude Code

## What Contextify Is

Contextify is a prompt-only, multi-round prompt-to-context transformation system. Zero compiled code — all logic is markdown workflow instructions executed by the LLM. Runs as slash commands (`/contextify:enhance`, `/contextify:settings`) inside AI coding assistants. Takes any prompt, runs iterative optimization (generate → score/critique → synthesize), and outputs a ranked portfolio: winner + safe alternative + exploratory alternative + change log + scoring summary.

## Folder Structure

**Source repo layout** (this repo):

```
commands/                        # Entry points — installed to .claude/commands/contextify/
├── enhance.md                   # /contextify:enhance — loads orchestrator only + Agent tool
└── settings.md                  # /contextify:settings — per-project defaults (.contextify/settings.json)
agents/                          # Named subagents — installed to .claude/agents/
├── contextify-researcher.md     # Data gathering (prompts.chat + web) — self-contained
├── contextify-research-synth.md # Research brief synthesis — self-contained
├── contextify-generator.md      # Candidate generation (learning-biased) — self-contained
├── contextify-scorer.md         # Hybrid B scoring + critique — self-contained
├── contextify-synthesizer.md    # Crossover + mutation from survivors — self-contained
├── contextify-presenter.md      # Portfolio selection + output formatting — self-contained
└── contextify-learner.md        # Cross-run learning capture — self-contained
workflows/                       # Stage instructions — installed to .claude/contextify/workflows/
├── enhance-orchestrator.md      # Master flow — sections 1-8, compact subagent dispatch
├── research.md                  # Dual-source research (includes API reference)
├── generate.md                  # 3 strategy variants + original anchor = 4 candidates (learning-biased)
├── score-bundle.md              # Scoring + rubric tables (merged)
├── synthesize.md                # Crossover + mutation from survivors
├── select-present.md            # Portfolio selection + output templates (merged)
└── learning.md                  # Cross-run learning (capture user picks, update preferences)
references/                      # On-demand — installed to .claude/contextify/references/
└── data-contracts.md            # Full schema shapes for internal artifacts
.docs/                           # Product docs (PRD.md, PRODUCT-DESIGN.md)
README.md                        # User-facing overview and quick start
INSTALL.md                       # GitHub-based installation instructions
```

**Installed layout in user's project** (all under `.claude/` — no pollution of project root):

```
.claude/
├── commands/contextify/
│   ├── enhance.md
│   └── settings.md
├── agents/
│   └── contextify-*.md  (7 files)
└── contextify/
    ├── workflows/        (7 files)
    ├── references/
    │   └── data-contracts.md
    └── README.md
.contextify/              (runtime data — created at first run, gitignored)
├── settings.json
└── history.json
```

## System Workflow

```
  /contextify:enhance "prompt" ──► Parse Args (+ load .contextify/history.json preferences)
                              │
                    ┌─────────▼──────────┐
                    │ Confidence Check    │ Score 5 dimensions (0-1 each)
                    │ (specificity,       │ Confidence = average
                    │  output clarity,    │
                    │  audience, constr., │
                    │  success criteria)  │
                    └─────────┬──────────┘
                              │
              ┌───── --auto? ─┤
              │               │
         conf < 0.3?    conf < 0.6?
          YES ──► Ask   YES ──► Ask ONE clarification ──┐
           NO ──────────►NO ───────────────────────────►│
                              │◄────────────────────────┘
                    ┌─────────▼──────────┐
                    │ Alignment Gate      │ Build LockContract
              ┌─────│ --auto: skip gate   │ Normal: present plan + domain confirm
              │     │ Normal: USER APPROVES│ User can fix domain/settings/constraints
              │     └─────────┬──────────┘
              │               │
              └──────────────►│
                              │
                 research enabled?
                  YES ──► Research (prompts.chat + web) ──┐
                   NO ───────────────────────────────────►│
                              │◄──────────────────────────┘
                    ┌─────────▼──────────┐
                    │ OPTIMIZATION LOOP   │ Up to 3 rounds
                    │                     │
                    │  Generate ──────►   │ Round 0: 3 variants + original
                    │  (learning-biased)  │ (biased by preferred_strategies)
                    │  Score/Critique ►   │ Hybrid B + lock check + critique
                    │  Synthesize ────►   │ Crossover + mutation from survivors
                    │                     │
                    │  Convergence? ──►   │ < 1% improvement at round >= 2 → stop
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │ Select & Present    │ Winner + Alt A (safe) + Alt B (exploratory)
                    │                     │ + change log + scoring summary
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │ Learning Capture    │ Ask user pick → update .contextify/history.json
                    │                     │ → update preferred_strategies
                    └─────────────────────┘
```

## How Execution Works

- **Entry**: `/contextify:enhance "prompt"` → `.claude/commands/contextify/enhance.md` loads only the orchestrator via `@` reference
- **Orchestrator is master**: `.claude/contextify/workflows/enhance-orchestrator.md` controls the entire flow — sections 1-4 run inline, sections 5-8 dispatch named subagents
- **Named subagents**: 7 subagent definitions in `agents/` (installed to `.claude/agents/`). Each has a pre-configured model, restricted tool access, and self-contained instructions embedded directly in its system prompt. The orchestrator dispatches by name with just inputs — no embedded prompt blocks. Workflow files serve as fallback path and documentation (kept in sync via comments).
- **Model selection**: Generate/Synthesize/Research-gather/Learn use haiku (lightweight). Research-synth/Score/Present use sonnet (analytical depth).
- **Fallback**: If named subagent unavailable → generic Agent tool with compact inline prompt. If Agent tool unavailable → Read workflow files and execute inline.
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
| **RunHistoryEntry** | Single run record for learning | domain, winnerStrategy, userPick, topScore |
| **LearningPreferences** | Aggregated cross-run preferences | preferred_strategies, avg_score_lift, runs_total |

**Scoring formula**: `totalScore = 0.5 * evalSetScore + 0.5 * rubricScore` (displayed to 2 decimal places)

**Survivor policy**: Top 4 by score. Original (`c-original`) always survives. Lock violators excluded.

**Domains**: `coding`, `writing`, `data`, `general` — each has its own eval scenarios and rubric dimensions in `score-bundle.md`.

## Do

- Follow `enhance-orchestrator.md` sections in order — never skip or reorder
- Always get user approval at the alignment gate (Section 4) before optimization — unless `--auto` or `--quick` is set
- In auto mode, still override and ask ONE question if confidence < 0.3 (extremely vague prompt)
- Re-inject the original prompt as `c-original` every round — it never leaves the pool
- Check every candidate against the lock contract every round — exclude violators as tombstones
- Stop early on convergence (< 1% score improvement between rounds, round >= 2)
- Continue in degraded mode if research sources fail — note it, don't block
- Present 3 portfolio choices (winner + safe + exploratory) with change log and scoring
- Keep round carry-forward compact — only `RoundContext` fields survive between rounds
- Capture user choice after presenting portfolio (Section 8) — feeds cross-run learning
- Load `.contextify/history.json` preferences at parse time and pass to generation for strategy bias
- Show detected domain in the alignment gate plan — let user correct if wrong

## Don't

- Don't skip the alignment gate in normal mode — user must approve the enhancement plan
- Don't ask more than ONE clarification question (single-question ceiling)
- Don't carry raw research content, full critique history, or eliminated candidate texts between rounds
- Don't copy retrieved research content verbatim — extract patterns only
- Don't eliminate the original prompt from the candidate pool — it always survives
- Don't exceed 3 optimization rounds
- Don't present lock-violating candidates in the final portfolio
- Don't modify workflow files during execution — they are the source of truth
- Don't preload reference files into context — subagents have self-contained instructions
- Don't bypass named subagent dispatch unless subagents are genuinely unavailable (fall back to generic Agent, then inline)
- Don't store full prompt text in history — only first 200 characters
