# Enhance Orchestrator Workflow

This is the core workflow for `/pe:enhance`. Execute every section in order. Do not skip sections unless explicitly marked as conditional.

## Overview

```
Parse → Confidence Check → [Clarify] → Alignment Gate → [Research] → Optimization Loop → Present
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

If the prompt is empty or missing, ask the user:
> "What prompt would you like me to enhance?"

Wait for response, then continue.

Record the parsed envelope mentally:
- `prompt`: the user's prompt text
- `research_mode`: true/false
- `strictness`: low/balanced/high
- `output_format`: full/diff/annotated
- `max_rounds`: 1-3

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

## Section 3: Clarification (Conditional — only if confidence < 0.6)

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

## Section 4: Alignment Gate (Always runs — User approval required)

Present the enhancement plan to the user for approval before optimization begins.

### Build the Lock Contract

From the prompt (and any clarification answer), extract:
- **Goal**: One sentence describing what the user wants to accomplish
- **Must-haves**: List of constraints that every candidate must preserve (technologies named, specific requirements, etc.)
- **Forbidden changes**: Things the user explicitly or implicitly requires that must not be dropped
- **Success criteria**: How to judge if the enhanced prompt is successful

### Present the Plan

Display to the user:

```
## Enhancement Plan

**Intent**: {goal — one sentence}
**Domain**: {coding|writing|data|general}
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

Proceed with enhancement? (You can adjust any setting or add constraints)
```

Use `AskUserQuestion` with options:
- "Proceed" (recommended)
- "Adjust settings"
- "Add constraints"

If the user adjusts settings or adds constraints, update the lock contract and settings accordingly, then re-present the plan. If they approve, proceed to Section 5.

---

## Section 5: Research (Conditional — only if research_mode=true)

Brief status update to user:
> "Researching prompt patterns and domain best practices..."

**Dispatch via Agent tool** (model: sonnet):

```
Task: Execute the research workflow for prompt enhancement.

Read the instructions at: ./pe/workflows/research.md

Inputs:
- User prompt: "{prompt}"
- Detected domain: "{domain}"

Execute the full research workflow (prompts.chat API search + web research).
Return a compact research brief (max 500 words) with sections:
- Sources Used
- Structural Patterns Observed
- Domain Conventions
- Constraints and Quality Standards
- Seed Inspiration

If any source fails, note degraded mode and continue with available data.
```

**Fallback**: If Agent tool is unavailable or fails, Read `./pe/workflows/research.md` and execute inline.

If `research_mode=false`, skip this section entirely and note:
> "Research skipped by user request."

---

## Section 6: Optimization Loop

Execute up to `max_rounds` rounds of generate → score/critique → synthesize.

### Round 0: Initial Generation

**Dispatch Generate via Agent tool** (model: haiku):

```
Task: Generate initial prompt candidates for optimization.

Read the instructions at: ./pe/workflows/generate.md
For full schema details, Read: ./pe/references/data-contracts.md

Inputs:
- Original prompt: "{prompt}"
- Domain: "{domain}"
- Strictness: "{strictness}"
- Research brief: "{research_brief or 'none'}"
- Round: 0

Generate exactly 4 candidates:
- c1: faithful rewrite
- c2: structural rework
- c3: creative restructuring
- c-original: original prompt verbatim (isOriginal: true)

Return each candidate as:
id: "{id}"
text: "{full prompt text}"
strategyLabel: "{strategy}"
isOriginal: {true|false}
```

Brief status update:
> "Generated 4 initial candidates. Scoring..."

**Dispatch Score/Critique via Agent tool** (model: sonnet):

```
Task: Score and critique prompt candidates using Hybrid B scoring.

Read the instructions at: ./pe/workflows/score-bundle.md
For full schema details, Read: ./pe/references/data-contracts.md

Inputs:
- Candidates: {serialized candidate array}
- Original prompt: "{prompt}"
- Domain: "{domain}"
- Lock contract: {serialized lock contract}
- Round: 0

Execute full scoring pipeline:
1. Generate eval scenarios for this domain
2. Score each candidate (evalSetScore + rubricScore → totalScore)
3. Rank candidates
4. Intent lock check against lock contract
5. Select top 4 survivors (c-original always survives)
6. Critique top 2-3 non-original survivors

Return:
- Scoreboard table (Rank | ID | Strategy | Eval | Rubric | Total)
- Survivors list (candidateId, text, totalScore, rationale)
- Tombstones list (candidateId, reason)
- Critique notes per top survivor
- convergence_delta: N/A (round 0)
- converged: false
```

Record the initial scoreboard and critique notes.

### Rounds 1 to max_rounds: Optimization

For each round:

**1. Dispatch Synthesize via Agent tool** (model: haiku):

```
Task: Synthesize new prompt candidates from survivors.

Read the instructions at: ./pe/workflows/synthesize.md
For full schema details, Read: ./pe/references/data-contracts.md

Inputs:
- Survivors: {serialized survivors with scores and critique notes}
- Tombstones: {serialized tombstones}
- Original prompt: "{prompt}"
- Round: {round_number}
- Strictness: "{strictness}"
- Lock contract: {serialized lock contract}

Produce:
- 1 crossover candidate from top 2 survivors
- 1 mutation per non-original survivor
- 1 original anchor (re-injected verbatim)

Return each candidate as:
id: "{id}"
text: "{full prompt text}"
strategyLabel: "{strategy}"
isOriginal: {true|false}
```

**2. Dispatch Score/Critique via Agent tool** (model: sonnet):

Same format as Round 0 scoring, but with:
- New candidates from synthesis
- Current round number
- Previous round's top score (for convergence calculation)

**3. Convergence check** (round >= 2 only):
- If improvement < 0.01 (1%): stop early with reason "score plateau"
- Report convergence to user

**4. Status update**:
> "Round {n}/{max_rounds} complete. Top score: {score}. {survivors_count} candidates advancing."

**5.** If converged, break out of the loop.

### After Loop Completes

Record:
- Total rounds completed
- Whether convergence occurred (and reason)
- Final scoreboard
- Accumulated change log entries (what changed from original across all rounds)

---

## Section 7: Final Output

**Dispatch Select/Present via Agent tool** (model: sonnet):

```
Task: Select the final portfolio and format the output package.

Read the instructions at: ./pe/workflows/select-present.md
For full schema details, Read: ./pe/references/data-contracts.md

Inputs:
- Final scoreboard: {serialized scoreboard}
- All survivors with full text: {serialized survivors}
- Lock contract: {serialized lock contract}
- Change log entries: {accumulated changes across rounds}
- Output format: "{output_format}"
- Original prompt: "{prompt}"
- Run metadata:
  - Rounds completed: {n}
  - Convergence: {yes/no, reason}
  - Research: {enabled/disabled, sources status}
  - Strictness: {level}
  - Domain: {domain}

Execute full selection and presentation:
1. Select winner (highest scoring, not original)
2. Select Alt A (safe — closest to original)
3. Select Alt B (exploratory — most different strategy)
4. Build change log
5. Build scoring summary
6. Format using the "{output_format}" template

Return the complete formatted output package ready to display to the user.
```

Display the returned output package to the user verbatim.

**Fallback**: If Agent tool is unavailable, Read `./pe/workflows/select-present.md` and execute inline.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty prompt | Ask user for prompt text |
| All candidates fail lock check in a round | Stop optimization, present best compliant candidate from previous round |
| Research fails | Continue in degraded mode with note |
| WebFetch/WebSearch unavailable | Skip research, note degraded mode |
| Agent tool unavailable | Read workflow file directly and execute inline (fallback mode) |
| Only 1 candidate survives all rounds | Present single enhanced prompt + original for comparison |
| Original prompt scores highest | Still present enhanced alternatives, note that original was strong |

## Context Management

To prevent context rot across rounds:
- Carry forward only: survivors (text + score + rationale), tombstones (id + reason), original prompt, lock contract
- Do NOT carry raw research content, full critique history, or eliminated candidate texts into later rounds
- Each round starts with the compact round context, not the full history
- Subagents load their own instructions — main thread stays lean
