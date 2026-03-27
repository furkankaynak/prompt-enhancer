# Enhance Orchestrator Workflow

This is the core workflow for `/contextify:enhance`. Execute every section in order. Do not skip sections unless explicitly marked as conditional.

## Overview

```
Parse → Confidence Check → Clarify (2-3 Qs) → Alignment Gate → [Research] → Optimization Loop → Present → [Learn]
```

## Data Contracts

Full schemas in `references/data-contracts.md`. Key shapes: ClarificationContext (answers, enriched_terms, question_count), LockContract (goal, must_haves, forbidden_changes, success_criteria), AnatomyContract (elements_present, elements_missing, priority_gaps, domain, agentic_prompt), RoundContext (round, survivors, tombstones, originalPrompt, lockContract, anatomyContract), Candidate (id, text, strategyLabel, isOriginal), ScoreBreakdown (evalSetScore, rubricScore, anatomyScore, totalScore = 0.40*eval + 0.35*rubric + 0.25*anatomy).

## Fallback Policy

If a named subagent is unavailable:
1. Use generic Agent tool with listed inputs, instruct it to Read the corresponding workflow file
2. If Agent tool unavailable, Read the workflow file and execute inline

Workflow paths: `research.md`, `generate.md`, `score-bundle.md`, `synthesize.md`, `select-present.md`, `learning.md`

---

## Section 1: Parse and Validate Arguments

Extract from `$ARGUMENTS`:

1. **prompt** (required): The text between quotes or the entire argument string if no quotes. Must be non-empty.
2. **--no-research**: If present, set `research_mode=false`. Otherwise `research_mode=true`.
3. **--strictness=<level>**: One of `low`, `balanced`, `high`. Default: `balanced`.
4. **--rounds=<n>**: Integer 1-3. Default: `3`.
5. **--output=<format>**: One of `full`, `diff`, `annotated`. Default: `full`.
6. **--auto**: If present, set `auto_mode=true`. Skips clarification (unless confidence < 0.3) and alignment gate.
7. **--quick**: Convenience alias. If present, set: `auto_mode=true`, `research_mode=false`, `max_rounds=1`, `output_format=diff`. Explicit flags override quick defaults.

If the prompt is empty or missing, ask the user:
> "What prompt would you like me to enhance?"

Wait for response, then continue.

**Load project settings**: Read `.contextify/settings.json` if it exists. Project settings fill in any flag not explicitly provided. Command flags > project settings > schema defaults.

**Load learning preferences**: Read `.contextify/history.json` if it exists. Extract `preferences` for use in Section 6 (generation bias).

Record the parsed envelope mentally:
- `prompt`: the user's prompt text
- `research_mode`: true/false
- `strictness`: low/balanced/high
- `output_format`: full/diff/annotated
- `max_rounds`: 1-3
- `auto_mode`: true/false
- `learning_preferences`: preferences object from history.json (or null if no history)

---

## Section 2: Context Confidence Assessment

Assess the user's prompt for completeness and clarity. Score these 5 dimensions (each 0-1):

1. **Specificity**: How specific is the request? (word count, technical terms, named technologies)
   - 0.0: 1-3 vague words | 0.5: moderate detail | 1.0: precise and detailed
2. **Output clarity**: Is the expected output format clear?
   - 0.0: no indication | 0.5: implied | 1.0: explicitly stated
3. **Audience/context**: Is the target context clear?
   - 0.0: no context | 0.5: some context | 1.0: clear audience/use case
4. **Constraints**: Are constraints or requirements stated?
   - 0.0: none | 0.5: some implicit | 1.0: explicit constraints
5. **Success criteria**: Can you tell when the output is "done"?
   - 0.0: no way to judge | 0.5: partially inferrable | 1.0: explicit criteria

**Confidence score** = average of all 5 dimensions.

**Domain detection**: Classify the prompt as `coding`, `writing`, `data`, or `general` based on keywords and intent.

Decision: always proceed to Section 3 (clarification determines its own question count based on confidence and mode).

---

## Section 3: Interactive Clarification

### Skip Conditions

- If `auto_mode=true` AND confidence >= 0.3: skip entirely, set `clarification_context = null`, proceed to Section 4
- If `auto_mode=true` AND confidence < 0.3: ask **1 question** only (extremely vague prompt override), then proceed to Section 4

### Normal Mode: Adaptive Clarification (2-3 questions, one at a time)

Determine question count based on confidence:

| Confidence | Questions | Focus |
|-----------|-----------|-------|
| >= 0.8 | 2 | **Widening** — explore what the user didn't mention. The prompt is already clear; surface hidden assumptions and unexplored dimensions. |
| 0.4 to 0.8 | 3 | **Mixed** — fill the biggest gap first, then widen. Balance gap-filling with exploration. |
| < 0.4 | 3 | **Gap-filling first** — address the weakest dimensions, then widen once basics are covered. |

Initialize: `clarification_context = { answers: [], enriched_terms: [], question_count: 0 }`

### Question Generation

Generate each question **dynamically** by analyzing:
1. The original prompt text
2. The confidence dimension scores from Section 2 (which dimensions are weak?)
3. All previous clarification answers (for questions 2 and 3)
4. The detected domain

**Do NOT use rigid templates.** Use the category table below as guidance for what kind of question to ask, not as a fixed mapping:

| Category | When to use | Example shape |
|----------|------------|---------------|
| `purpose` | context_why or success_criteria scored low | "What will you use this for? e.g., [A] production deployment, [B] learning/exploration, [C] prototype" |
| `scope` | specificity scored low or prompt is broad | "How comprehensive should this be? e.g., [A] minimal viable, [B] production-ready with edge cases, [C] comprehensive with docs" |
| `audience` | audience/context scored low | "Who will interact with this? e.g., [A] just me, [B] my team, [C] end users / public" |
| `constraints` | constraints scored low or domain has common tradeoff axes | "What matters more? e.g., [A] simplicity over completeness, [B] completeness over simplicity, [C] balanced" |
| `quality` | success_criteria scored low | "What does 'good' look like? e.g., [A] correctness above all, [B] readability/maintainability, [C] performance" |
| `widening` | for high-confidence prompts or after gaps are filled | "Have you considered {aspect the user didn't mention}? e.g., [A] yes include it, [B] out of scope, [C] tell me more" |

### Question Loop

For each question (1 through question_count):

1. **Generate** the question based on prompt + scores + domain + all previous answers. Target the biggest information gap OR (if confidence >= 0.8 or gaps already addressed) the most impactful widening opportunity.
2. **Present** via `AskUserQuestion` with 2-4 multiple-choice options. Prefer multiple choice when the domain has natural categories; use fewer, broader options when the space is too open.
3. **Record** the answer: append `{ question, answer, category }` to `clarification_context.answers`.
4. **Extract enriched terms**: pull key phrases from the answer (named technologies, audience descriptors, scope terms, constraints) and add to `clarification_context.enriched_terms`.
5. **Next question** must build on all previous answers — never repeat or rephrase a topic the user already addressed.

### Rules

- **One question per turn**. Never bundle multiple questions into one message.
- **Accept terse answers**. If the user gives a short or vague answer, accept it and move on to the next question. Do not probe the same topic twice.
- **No over-interrogation**. The goal is to widen understanding, not to exhaust the user. If an answer is comprehensive enough to cover what later questions would ask, reduce remaining question count.
- **Multiple choice preferred** when the domain offers natural categories. Open-ended is fine when the space is too broad for meaningful options.
- **Each answer genuinely informs the next question**. Question 2 should feel like a natural follow-up to answer 1, not a disconnected survey item.

### After Clarification Completes

1. Set `clarification_context.question_count` to the number of questions actually asked.
2. Incorporate all answers into the working prompt context for Section 4 (LockContract and AnatomyContract construction).
3. Proceed to Section 4.

---

## Section 4: Alignment Gate

### Build the Lock Contract

From the prompt and all clarification answers (`clarification_context.answers`, if not null), extract:
- **Goal**: One sentence describing what the user wants to accomplish
- **Must-haves**: List of constraints that every candidate must preserve (technologies named, specific requirements, etc.)
- **Forbidden changes**: Things the user explicitly or implicitly requires that must not be dropped
- **Success criteria**: How to judge if the enhanced prompt is successful

### Build the Anatomy Contract

After the LockContract is assembled, perform anatomy analysis on the original prompt against the 10-element checklist from `references/data-contracts.md`.

For each element:
- Mark PRESENT if clearly or partially present (implied role counts; vague format hint counts as partial)
- Mark MISSING if absent

Determine `agentic_prompt`: true if the prompt describes multi-step autonomous tasks, tool use, or file system operations.

Select `priority_gaps` — the top 3 highest-impact missing elements using the domain priority order from `references/data-contracts.md`. If `agentic_prompt=true`, `agentic_action_guidance` always enters top 3 if missing.

Record: `AnatomyContract { elements_present, elements_missing, priority_gaps[3], domain, agentic_prompt }`

### Auto Mode Path (auto_mode=true)

Auto-build both contracts from the prompt without user interaction. Display a brief confirmation:

```
Auto mode: enhancing "{domain}" prompt (anatomy gaps: {gap_count}). Starting optimization...
```

Proceed directly to Section 5. No approval needed.

### Normal Mode Path (auto_mode=false)

Present the enhancement plan to the user for approval before optimization begins.

Display to the user:

```
## Enhancement Plan

**Intent**: {goal — one sentence}
**Domain**: {coding|writing|data|general} ← if this is wrong, say so and I'll re-classify

**Must-haves**: {bulleted list of constraints}

**Anatomy Analysis** ({gap_count} gaps found):
- Present: {comma-separated present elements, or "none"}
- Missing: {comma-separated missing elements, or "none"}
- Priority improvements: {priority_gaps[0]}, {priority_gaps[1]}, {priority_gaps[2]}

**Enhancement strategies**:
1. Faithful rewrite — improve clarity while preserving structure
2. Structural rework — reorganize into sections with explicit requirements
3. Anatomy-complete — fills all identified best-practice gaps ({priority_gaps[0]}, {priority_gaps[1]}, {priority_gaps[2]})

**Settings**:
- Research: {enabled|disabled}
- Strictness: {low|balanced|high}
- Max rounds: {n}
- Output format: {full|diff|annotated}

Proceed with enhancement? (You can adjust any setting, change the domain, or add constraints)
```

Use `AskUserQuestion` with options:
- "Proceed" (recommended)
- "Adjust settings"
- "Change domain"
- "Add constraints"

If the user changes the domain, re-classify, re-run anatomy priority ordering, and update AnatomyContract accordingly. If they adjust settings or add constraints, update the lock contract and settings accordingly, then re-present the plan. If they approve, proceed to Section 5.

---

## Section 5: Research (Conditional — only if research_mode=true)

Brief status update to user:
> "Researching prompt patterns and domain best practices..."

**Pre-research enrichment**: If `clarification_context` is not null and has `enriched_terms`, these augment research query construction. The researcher uses enriched terms to build more targeted queries — e.g., if the user clarified "this is for a production microservice with high availability," the researcher incorporates "production microservice" and "high availability" into its topic/purpose extraction and may add one additional web query from these terms.

**Dispatch A** — `contextify-researcher`: inputs prompt, domain, clarification_context (or null) → returns JSON (promptsChatResults, webResults, degradedSources)

**Dispatch B** — `contextify-research-synth`: inputs gathered_data (from A), prompt, domain, clarification_context (or null) → returns 500-word research brief

If `research_mode=false`, skip this section entirely and note:
> "Research skipped by user request."

---

## Section 6: Optimization Loop

Execute up to `max_rounds` rounds of generate → score/critique → synthesize.

### Round 0: Initial Generation

**Dispatch** `contextify-generator`: inputs prompt, domain, strictness, research_brief (or "none"), round=0, learning_preferences (or "none"), anatomy_contract → returns 4 candidates (c1, c2, c3-anatomy-complete, c-original)

Brief status: > "Generated 4 initial candidates. Scoring..."

**Dispatch** `contextify-scorer`: inputs candidates, prompt, domain, lock_contract, anatomy_contract, round=0 → returns scoreboard, survivors, tombstones, critique notes, converged=false

Record the initial scoreboard and critique notes. Display all scores to 2 decimal places.

### Rounds 1 to max_rounds: Optimization

For each round:

**1. Dispatch** `contextify-synthesizer`: inputs survivors (with scores and critique), tombstones, prompt, round, strictness, lock_contract, anatomy_contract → returns crossover + mutations + anatomy mutation + original anchor

**2. Dispatch** `contextify-scorer`: inputs candidates, prompt, domain, lock_contract, anatomy_contract, round, previous_top_score → returns scoreboard, survivors, tombstones, critique notes, convergence_delta, converged

**3. Convergence check** (round >= 2 only): if converged (improvement < 0.01), stop early with reason "score plateau"

**4. Status**: > "Round {n}/{max_rounds} complete. Top score: {score}. {survivors_count} candidates advancing."

**5.** If converged, break out of the loop.

### After Loop Completes

Record: total rounds completed, whether convergence occurred (and reason), final scoreboard, accumulated change log entries.

---

## Section 7: Final Output

**Dispatch** `contextify-presenter`: inputs scoreboard, survivors (with full text), lock_contract, anatomy_contract, change_log, output_format, prompt, run_metadata (rounds, convergence, research status, strictness, domain) → returns complete formatted output package (including `outputPath`)

Display the returned output package to the user verbatim, then append:
> Saved to: {outputPath}

---

## Section 8: Learning Capture (Always runs after output)

After presenting the portfolio, ask the user which version they will use:

Use `AskUserQuestion` with options:
- "Winner"
- "Alt A (Safe)"
- "Alt B (Exploratory)"
- "Original (no enhancement needed)"
- "Skip (deciding later)"

**Dispatch** `contextify-learner`: inputs domain, originalPrompt (first 200 chars), winnerStrategy, userPick (winner|altA|altB|original|none), strictness, rounds, topScore, originalScore, auto_mode, outputPath, history_path=.contextify/history.json → writes .contextify/history.json

If the user picks "Skip", still record the run with `userPick: "none"`.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty prompt | Ask user for prompt text |
| All candidates fail lock check in a round | Stop optimization, present best compliant candidate from previous round |
| Research fails | Continue in degraded mode with note |
| WebFetch/WebSearch unavailable | Skip research, note degraded mode |
| Named subagent unavailable | Fall back per Fallback Policy above |
| Agent tool unavailable | Read workflow file directly and execute inline |
| Only 1 candidate survives all rounds | Present single enhanced prompt + original for comparison |
| Original prompt scores highest | Still present enhanced alternatives, note that original was strong |

## Context Management

To prevent context rot across rounds:
- Carry forward only: survivors (text + score + rationale), tombstones (id + reason), original prompt, lock contract, anatomy contract
- Do NOT carry raw research content, full critique history, or eliminated candidate texts into later rounds
- Each round starts with the compact round context, not the full history
- Subagents have self-contained instructions — main thread stays lean
