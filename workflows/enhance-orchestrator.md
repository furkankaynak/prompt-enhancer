# Enhance Orchestrator Workflow

This is the core workflow for `/pe:enhance`. Execute every section in order. Do not skip sections unless explicitly marked as conditional.

## Overview

```
Parse → Confidence Check → [Clarify] → Alignment Gate → [Research] → Optimization Loop → Present
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

Execute the research workflow from `@./pe/workflows/research.md`.

Brief status update to user:
> "Researching prompt patterns and domain best practices..."

Produce a research brief. If research fails partially or fully, note degraded mode and continue.

If `research_mode=false`, skip this section entirely and note:
> "Research skipped by user request."

---

## Section 6: Optimization Loop

Execute up to `max_rounds` rounds of generate → score/critique → synthesize.

### Round 0: Initial Generation

Follow `@./pe/workflows/generate.md` to produce 4 initial candidates (3 variants + original anchor).

Brief status update:
> "Generated 4 initial candidates. Scoring..."

Follow `@./pe/workflows/score-critique.md` to score and critique the initial pool.

Record the initial scoreboard and critique notes.

### Rounds 1 to max_rounds: Optimization

For each round:

1. **Synthesize**: Follow `@./pe/workflows/synthesize.md` to produce new candidates from survivors.

2. **Score and critique**: Follow `@./pe/workflows/score-critique.md` to evaluate the new pool.

3. **Lock check**: Verify all candidates against the lock contract. Exclude violators.

4. **Convergence check** (round >= 2 only):
   - Compare top score to previous round's top score
   - If improvement < 0.01 (1%): stop early with reason "score plateau"
   - Report convergence to user

5. **Status update**:
   > "Round {n}/{max_rounds} complete. Top score: {score}. {survivors_count} candidates advancing."

6. If converged, break out of the loop.

### After Loop Completes

Record:
- Total rounds completed
- Whether convergence occurred (and reason)
- Final scoreboard
- Accumulated change log entries (what changed from original across all rounds)

---

## Section 7: Final Output

Follow `@./pe/workflows/select-present.md` to assemble and present the output package.

Use the template from `@./pe/templates/output-package.md` matching the requested output format.

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Empty prompt | Ask user for prompt text |
| All candidates fail lock check in a round | Stop optimization, present best compliant candidate from previous round |
| Research fails | Continue in degraded mode with note |
| WebFetch/WebSearch unavailable | Skip research, note degraded mode |
| Only 1 candidate survives all rounds | Present single enhanced prompt + original for comparison |
| Original prompt scores highest | Still present enhanced alternatives, note that original was strong |

## Context Management

To prevent context rot across rounds:
- Carry forward only: survivors (text + score + rationale), tombstones (id + reason), original prompt, lock contract
- Do NOT carry raw research content, full critique history, or eliminated candidate texts into later rounds
- Each round starts with the compact round context, not the full history
- Reference the scoring rubric and other files only when actively scoring (do not keep them in working memory)
