# Enhance Orchestrator Workflow

This is the core workflow for `/pe:enhance`. Execute every section in order. Do not skip sections unless explicitly marked as conditional.

## Overview

```
Parse → Confidence Check → [Clarify] → Alignment Gate → [Research] → Optimization Loop → Present → [Learn]
```

---

## Inline Schemas

These compact schemas define the key contracts used throughout orchestration. Subagents can Read `references/data-contracts.md` for full details.

### LockContract
```
goal: string           — primary objective of the enhancement run
must_haves: string[]   — constraints every candidate must preserve
forbidden_changes: string[] — guards that must not be dropped
success_criteria: string[]  — outcome requirements for acceptable completion
```

### RoundContext (carry-forward between rounds — ONLY these fields travel)
```
round: integer >= 0
survivors: [{candidateId, text, totalScore, rationale (max 200 chars)}]
tombstones: [{candidateId, reason (max 100 chars)}]
originalPrompt: string
lockContract: LockContract
```

### Candidate
```
id: string             — e.g. "c1", "c2", "c-original"
text: string           — full prompt text
strategyLabel: string  — human-readable strategy
isOriginal: boolean    — true only for original anchor
```

### ScoreBreakdown
```
evalSetScore: 0-1, rubricScore: 0-1, totalScore: 0.5*eval + 0.5*rubric
```

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

**Load project settings**: Read `.pe/settings.json` if it exists. Project settings fill in any flag not explicitly provided. Command flags > project settings > schema defaults.

**Load learning preferences**: Read `.pe/history.json` if it exists. Extract `preferences` for use in Section 6 (generation bias).

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

Decision:
- If confidence >= 0.6: proceed to Section 4 (skip clarification)
- If confidence < 0.6: proceed to Section 3 (clarification)

---

## Section 3: Clarification (Conditional)

**Skip conditions**:
- If `auto_mode=true` AND confidence >= 0.3: skip entirely, proceed to Section 4
- If `auto_mode=true` AND confidence < 0.3: ask ONE question (extremely vague prompt override)
- If `auto_mode=false` AND confidence >= 0.6: skip entirely, proceed to Section 4
- If `auto_mode=false` AND confidence < 0.6: ask ONE question

**Single-question ceiling**: Ask exactly ONE targeted clarification question. Never ask more than one.

Identify the **lowest-scoring dimension** from Section 2. Ask a clarification question targeting that specific gap:

| Lowest Dimension | Question Template |
|------------------|-------------------|
| Specificity | "Could you be more specific about what you want? For example: {2-3 concrete options based on the prompt}" |
| Output clarity | "What format should the output be in? For example: {relevant format options for this domain}" |
| Audience/context | "Who is this for / what's the context? For example: {relevant context options}" |
| Constraints | "Are there any specific constraints or requirements? For example: {relevant constraints for this domain}" |
| Success criteria | "How will you know the result is good? What would a successful output look like?" |

Use `AskUserQuestion` to present the question with 2-4 relevant options plus the ability to type a custom answer.

After receiving the answer, incorporate it into the working prompt context. Then proceed to Section 4.

**Important**: Even if the answer is vague, do NOT ask another question. One question maximum, then move on.

---

## Section 4: Alignment Gate

### Build the Lock Contract

From the prompt (and any clarification answer), extract:
- **Goal**: One sentence describing what the user wants to accomplish
- **Must-haves**: List of constraints that every candidate must preserve (technologies named, specific requirements, etc.)
- **Forbidden changes**: Things the user explicitly or implicitly requires that must not be dropped
- **Success criteria**: How to judge if the enhanced prompt is successful

### Auto Mode Path (auto_mode=true)

Auto-build the lock contract from the prompt without user interaction. Display a brief confirmation:

```
Auto mode: enhancing prompt as "{domain}" domain. Starting optimization...
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

**Enhancement strategies**:
1. Faithful rewrite — improve clarity while preserving structure
2. Structural rework — reorganize into sections with explicit requirements
3. Creative restructuring — different framing approach for better results

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

If the user changes the domain, re-classify and update eval scenarios/rubric dimensions accordingly. If they adjust settings or add constraints, update the lock contract and settings accordingly, then re-present the plan. If they approve, proceed to Section 5.

---

## Section 5: Research (Conditional — only if research_mode=true)

Brief status update to user:
> "Researching prompt patterns and domain best practices..."

**Dispatch A** — Use `pe-researcher` subagent:
- Inputs: prompt={prompt}, domain={domain}
- Returns: JSON with promptsChatResults, webResults, degradedSources

**Dispatch B** — Use `pe-research-synth` subagent:
- Inputs: gathered_data={output from A}, prompt={prompt}, domain={domain}
- Returns: 500-word research brief

**Fallback**: If named subagent is unavailable, use generic Agent tool with the inputs above and instruct it to Read `./pe/workflows/research.md`. If Agent tool is also unavailable, Read `./pe/workflows/research.md` and execute inline.

If `research_mode=false`, skip this section entirely and note:
> "Research skipped by user request."

---

## Section 6: Optimization Loop

Execute up to `max_rounds` rounds of generate → score/critique → synthesize.

### Round 0: Initial Generation

**Dispatch Generate** — Use `pe-generator` subagent:
- Inputs: prompt={prompt}, domain={domain}, strictness={strictness}, research_brief={research_brief or "none"}, round=0, learning_preferences={learning_preferences or "none"}
- Returns: 4 candidates (c1, c2, c3, c-original)

Brief status update:
> "Generated 4 initial candidates. Scoring..."

**Dispatch Score/Critique** — Use `pe-scorer` subagent:
- Inputs: candidates={candidates}, prompt={prompt}, domain={domain}, lock_contract={lock_contract}, round=0
- Returns: scoreboard, survivors, tombstones, critique notes, converged=false

Record the initial scoreboard and critique notes. Display all scores to 2 decimal places (not 3).

### Rounds 1 to max_rounds: Optimization

For each round:

**1. Dispatch Synthesize** — Use `pe-synthesizer` subagent:
- Inputs: survivors={survivors with scores and critique}, tombstones={tombstones}, prompt={prompt}, round={round_number}, strictness={strictness}, lock_contract={lock_contract}
- Returns: crossover + mutations + original anchor

**2. Dispatch Score/Critique** — Use `pe-scorer` subagent:
- Inputs: candidates={new candidates}, prompt={prompt}, domain={domain}, lock_contract={lock_contract}, round={round_number}, previous_top_score={previous top score}
- Returns: scoreboard, survivors, tombstones, critique notes, convergence_delta, converged

**3. Convergence check** (round >= 2 only):
- If converged (improvement < 0.01): stop early with reason "score plateau"
- Report convergence to user

**4. Status update**:
> "Round {n}/{max_rounds} complete. Top score: {score}. {survivors_count} candidates advancing."

**5.** If converged, break out of the loop.

**Fallback**: If named subagents are unavailable, use generic Agent tool with compact inline prompts instructing each to Read its workflow file. If Agent tool is also unavailable, Read workflow files and execute inline.

### After Loop Completes

Record:
- Total rounds completed
- Whether convergence occurred (and reason)
- Final scoreboard
- Accumulated change log entries (what changed from original across all rounds)

---

## Section 7: Final Output

**Dispatch Select/Present** — Use `pe-presenter` subagent:
- Inputs: scoreboard={final scoreboard}, survivors={all survivors with full text}, lock_contract={lock_contract}, change_log={accumulated changes}, output_format={output_format}, prompt={prompt}, run_metadata={rounds, convergence, research status, strictness, domain}
- Returns: complete formatted output package

Display the returned output package to the user verbatim.

**Fallback**: If named subagent is unavailable, use generic Agent tool. If Agent tool is unavailable, Read `./pe/workflows/select-present.md` and execute inline.

---

## Section 8: Learning Capture (Always runs after output)

After presenting the portfolio, ask the user which version they will use:

Use `AskUserQuestion` with options:
- "Winner"
- "Alt A (Safe)"
- "Alt B (Exploratory)"
- "Original (no enhancement needed)"
- "Skip (deciding later)"

**Dispatch Learning** — Use `pe-learner` subagent:
- Inputs: domain={domain}, originalPrompt={first 200 chars}, winnerStrategy={strategy}, userPick={winner|altA|altB|original|none}, strictness={strictness}, rounds={rounds_completed}, topScore={top_score}, originalScore={original_score}, auto_mode={auto_mode}, history_path=.pe/history.json
- Writes: .pe/history.json

**Fallback**: If named subagent is unavailable, use generic Agent tool. If Agent tool is unavailable, Read `./pe/workflows/learning.md` and execute inline.

If the user picks "Skip", still record the run with `userPick: "none"`.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty prompt | Ask user for prompt text |
| All candidates fail lock check in a round | Stop optimization, present best compliant candidate from previous round |
| Research fails | Continue in degraded mode with note |
| WebFetch/WebSearch unavailable | Skip research, note degraded mode |
| Named subagent unavailable | Fall back to generic Agent tool with compact inline prompt |
| Agent tool unavailable | Read workflow file directly and execute inline (fallback mode) |
| Only 1 candidate survives all rounds | Present single enhanced prompt + original for comparison |
| Original prompt scores highest | Still present enhanced alternatives, note that original was strong |

## Context Management

To prevent context rot across rounds:
- Carry forward only: survivors (text + score + rationale), tombstones (id + reason), original prompt, lock contract
- Do NOT carry raw research content, full critique history, or eliminated candidate texts into later rounds
- Each round starts with the compact round context, not the full history
- Subagents load their own instructions — main thread stays lean
