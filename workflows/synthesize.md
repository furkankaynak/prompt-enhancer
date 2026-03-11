# Synthesis Workflow

Produce next-round candidates from survivors using crossover and mutation. This is the evolutionary step driving improvement between rounds.

## Inputs
- Survivors from previous round (with scores and critique notes)
- Tombstones (eliminated candidates — avoid repeating their approaches)
- Original user prompt (for re-injection)
- Current round number
- Strictness level
- Lock contract

## Synthesis Strategies

### 1. Crossover (1 candidate)
Combine best traits of top 2 survivors into a hybrid. Identify each top survivor's strengths (from critique), merge them, resolve conflicts by favoring higher-scored approach.

ID: `c{round}-cross` | Label: `"crossover (r{round}: {survivor1_id} x {survivor2_id})"`

### 2. Mutation (1 per non-original survivor)
For each surviving candidate (except original): apply the critique's suggested improvement, address weaknesses while preserving strengths. Targeted refinement only.

ID: `c{round}-mut-{n}` | Label: `"mutation (r{round}: refined {source_id})"`

### 3. Original Re-injection (always)
Original prompt verbatim as `c-original`, `isOriginal: true`.

## Strictness Influence
- **low**: Fix only stated weakness, preserve everything else
- **balanced**: Address weakness + one additional improvement
- **high**: Aggressive rework if critique warrants it

## Anti-Repetition
Check each new candidate against tombstones. Do NOT recreate eliminated approaches. If crossover/mutation would produce something similar to a tombstoned candidate, pivot.

## Lock Contract Compliance
Every new candidate MUST: address the goal, include all must_haves, preserve forbidden_changes guards, align with success_criteria. Adjust to comply before including — never knowingly violate.

## Output
- 1 crossover + N mutations (1 per non-original survivor) + 1 original anchor
- Typically 4-5 candidates per round

```
id: "{id}"
text: "{full prompt text}"
strategyLabel: "{strategy}"
isOriginal: {true|false}
```
