# Output Package Templates

Use the template matching the requested `output_format`.

## Format: full (default)

```markdown
---

## Enhanced Prompt (Winner)

{winner_prompt_text}

### Why This Won
{2-3 sentence rationale referencing score highlights and key improvements over alternatives}

---

## Alternative A (Safe)

{alt_a_prompt_text}

> {1-sentence rationale: why this is the conservative, low-risk choice}

## Alternative B (Exploratory)

{alt_b_prompt_text}

> {1-sentence rationale: why this is the high-upside, creative choice}

---

## Change Log

| Change | Rationale | Round |
|--------|-----------|-------|
| {description of change} | {why this improvement was made} | {which round} |
| ... | ... | ... |

## Scoring Summary

| Candidate | Strategy | Eval | Rubric | Total | Rank |
|-----------|----------|------|--------|-------|------|
| Winner | {strategy} | {eval_score} | {rubric_score} | {total} | 1 |
| Alt A | {strategy} | {eval_score} | {rubric_score} | {total} | {rank} |
| Alt B | {strategy} | {eval_score} | {rubric_score} | {total} | {rank} |

## Run Metadata
- Rounds completed: {n} ({converged|completed|stopped})
- Research: {enabled|disabled} {(sources used)}
- Strictness: {low|balanced|high}
- Domain detected: {coding|writing|data|general}
{- Note: degraded mode — {reason} (only if applicable)}

---
```

## Format: diff

```markdown
---

## Changes from Original

### Added
- {list each new element added to the prompt}

### Modified
- {list each element that was reworded or restructured}

### Removed
- {list anything removed, if applicable, with reason}

### Original
{original_prompt_text}

### Enhanced (Winner)
{winner_prompt_text}

---
```

## Format: annotated

```markdown
---

## Enhanced Prompt (Annotated)

{The winner prompt with inline annotations. Use bold tags to mark changes:}

**[ADDED: {category}]** {new text that was added}

**[MODIFIED: {what changed}]** {reworded text}

**[ORIGINAL]** {unchanged text from the original}

{Example:}
**[ADDED: role context]** You are a senior TypeScript developer.
**[ORIGINAL]** Write a function that sorts an array
**[ADDED: specificity]** of objects by a configurable key,
**[ADDED: constraint]** returning a new array without mutating the input.
**[ADDED: edge cases]** Handle empty arrays and single-element arrays gracefully.

---
```
