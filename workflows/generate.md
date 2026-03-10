# Candidate Generation Workflow

Generate prompt candidate variants for the optimization pool. This stage produces the raw material that scoring, critique, and synthesis operate on.

## Inputs
- Original user prompt text
- Detected domain (coding/writing/data/general)
- Strictness level (low/balanced/high)
- Research brief (if research was performed)
- Round number (0 = initial generation)

## Round 0: Initial Baseline Generation

Produce exactly **3 strategy variants + 1 original anchor** (4 candidates total).

### Candidate 1: Faithful Rewrite (`c1`)
- Preserve the user's intent exactly
- Improve clarity: remove ambiguity, add specificity
- Add missing output format expectations
- Keep the overall structure close to the original
- Strategy label: `"faithful rewrite"`

### Candidate 2: Structural Rework (`c2`)
- Reorganize the prompt into clear sections
- Add explicit sections: Task, Requirements, Constraints, Expected Output
- Extract implicit constraints and make them explicit
- Add success criteria if missing
- Strategy label: `"structural rework"`

### Candidate 3: Creative Restructuring (`c3`)
- Try a meaningfully different framing approach:
  - Role-based setup ("You are a senior {domain} expert...")
  - Chain-of-thought scaffolding ("First analyze..., then implement..., finally verify...")
  - Few-shot pattern (provide an example of desired output)
  - Constraint-first ordering (lead with what NOT to do, then what to do)
- Choose the framing most appropriate for the detected domain
- Strategy label: `"creative restructuring"`

### Candidate 4: Original Anchor (`c-original`)
- The original user prompt, verbatim, unchanged
- This always survives every round as a reference baseline
- Strategy label: `"original (reference anchor)"`
- `isOriginal: true`

## Strictness Influence

Adjust generation aggressiveness based on strictness level:

- **low**: Stay very close to the original. Minimal additions. Preserve wording where possible. Candidate 3 should be a moderate variation, not a radical departure.
- **balanced** (default): Moderate rewriting. Add missing constraints, restructure for clarity, but keep the core message recognizable.
- **high**: Aggressive restructuring permitted. Creative departures encouraged. Candidate 3 can use a substantially different approach. Add comprehensive constraints, edge cases, and success criteria even if the original didn't hint at them.

## Research Seeding

If a research brief is available, use extracted patterns to **enhance** the generated candidates:
- Apply structural patterns observed in high-quality prompts to Candidate 2
- Use domain conventions to inform Candidate 1's specificity improvements
- Let seed inspiration points influence Candidate 3's creative direction
- Never copy research content verbatim — use as inspiration only

If no research brief is available, generate all candidates purely from internal analysis of the original prompt.

## Candidate Format

Each candidate must include:
```
id: "{id}"
text: "{full prompt text}"
strategyLabel: "{human-readable strategy description}"
isOriginal: {true|false}
```

## Quality Standards for Generated Candidates

Every non-original candidate must:
1. Preserve the user's core intent (what they want to accomplish)
2. Not introduce requirements the user didn't ask for (unless strictness=high)
3. Be a complete, runnable prompt (not a fragment or outline)
4. Be meaningfully different from the other candidates (no near-duplicates)
5. Be better than the original in at least one scoring dimension
