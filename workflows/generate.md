# Candidate Generation Workflow

Generate prompt candidate variants for the optimization pool.

## Inputs
- Original user prompt text
- Detected domain (coding/writing/data/general)
- Strictness level (low/balanced/high)
- Research brief (if available)
- Round number (0 = initial generation)

## Round 0: Initial Baseline Generation

Produce exactly **3 strategy variants + 1 original anchor** (4 candidates total).

### c1: Faithful Rewrite
- Preserve intent exactly, improve clarity, remove ambiguity, add specificity
- Add missing output format expectations, keep structure close to original
- Strategy label: `"faithful rewrite"`

### c2: Structural Rework
- Reorganize into clear sections: Task, Requirements, Constraints, Expected Output
- Extract implicit constraints, make them explicit, add success criteria if missing
- Strategy label: `"structural rework"`

### c3: Creative Restructuring
- Try a meaningfully different framing: role-based setup, chain-of-thought scaffolding, few-shot pattern, or constraint-first ordering
- Choose framing most appropriate for the detected domain
- Strategy label: `"creative restructuring"`

### c-original: Original Anchor
- Original user prompt verbatim, unchanged. Always survives every round.
- Strategy label: `"original (reference anchor)"`, `isOriginal: true`

## Strictness Influence

- **low**: Stay close to original. Minimal additions. Candidate 3 = moderate variation.
- **balanced**: Moderate rewriting. Add missing constraints, restructure for clarity.
- **high**: Aggressive restructuring. Creative departures encouraged. Add comprehensive constraints/edge cases even if original didn't hint at them.

## Research Seeding

If research brief available: apply structural patterns to c2, domain conventions to c1, seed inspiration to c3. Never copy verbatim.

If no research: generate purely from internal analysis.

## Candidate Format

```
id: "{id}"
text: "{full prompt text}"
strategyLabel: "{strategy}"
isOriginal: {true|false}
```

## Quality Standards

Every non-original candidate must:
1. Preserve the user's core intent
2. Not introduce unrequested requirements (unless strictness=high)
3. Be a complete, runnable prompt
4. Be meaningfully different from other candidates
5. Be better than original in at least one scoring dimension
