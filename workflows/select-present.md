# Selection and Presentation Workflow

Assemble the final output package from the last round's scoreboard. Select the portfolio (winner + safe alt + exploratory alt) and format according to the requested output format.

Reference: `@./pe/templates/output-package.md` for format templates.

## Inputs
- Final scoreboard (all candidates scored and ranked)
- All survivors with full text
- Lock contract
- Change log entries accumulated across rounds
- Output format (full/diff/annotated)
- Original user prompt
- Run metadata (rounds completed, convergence status, research status, strictness, domain)

## Step 1: Portfolio Selection

### Winner
- The candidate with the **highest total score** in the final round
- Must NOT be the original prompt (if original scores highest, promote the next candidate as winner)
- Must have passed all lock checks

### Alt A (Safe)
- The candidate most **similar to the original prompt** in structure and wording
- Should have a solid score but prioritize low behavioral risk
- Think: "if the user is nervous about changes, this is the safe choice"
- Cannot be the same candidate as the winner

### Alt B (Exploratory)
- The candidate with the most **meaningfully different strategy** from the winner
- Should have reasonable scores but prioritize creative divergence
- Think: "if the user wants to try something bold, this is the option"
- Cannot be the same candidate as the winner or Alt A

If fewer than 3 non-original candidates survive, adjust:
- With 2 candidates: winner + 1 alternative (label as "Alternative")
- With 1 candidate: present the single enhanced candidate + original for comparison

## Step 2: Build Change Log

Compile changes across all rounds into a summary table:

For each significant modification from original to winner:
- **Change**: What was added, modified, or restructured
- **Rationale**: Why this improvement was made
- **Round**: Which optimization round introduced it

Order by impact (most significant changes first). Aim for 3-8 entries. Avoid trivial wording changes.

## Step 3: Build Scoring Summary

Create a compact scoring table showing the portfolio candidates:

| Candidate | Strategy | Eval Score | Rubric Score | Total | Rank |
|-----------|----------|------------|-------------|-------|------|
| Winner | {strategy} | {score} | {score} | {score} | {rank} |
| Alt A | {strategy} | {score} | {score} | {score} | {rank} |
| Alt B | {strategy} | {score} | {score} | {score} | {rank} |
| Original | reference anchor | {score} | {score} | {score} | {rank} |

Always include the original prompt's scores for comparison.

## Step 4: Format Output

Apply the template from `@./pe/templates/output-package.md` matching the requested format:

### full (default)
- Winner with full text and "Why This Won" rationale
- Alt A with text and 1-sentence rationale
- Alt B with text and 1-sentence rationale
- Change log table
- Scoring summary table
- Run metadata

### diff
- Lists of Added, Modified, Removed changes
- Original prompt text
- Winner prompt text
- Compact format for quick comparison

### annotated
- Winner prompt with inline `[ADDED]`, `[MODIFIED]`, `[ORIGINAL]` annotations
- Each annotation explains what changed and why
- Useful for understanding exactly what the enhancer did

## Step 5: Degraded Mode Notes

If the run used degraded mode (research sources unavailable), append a note:

```
Note: This enhancement ran in degraded mode ({which sources were unavailable}).
Results are based on {what was available: internal generation only / partial research}.
```

## Presentation Guidelines

- Lead with the winner — it's the primary output
- Make alternatives clearly secondary (indented or visually distinct)
- Keep rationales concise — 1-3 sentences max
- Scoring summary should be scannable at a glance
- Run metadata goes last — it's informational, not the main event
