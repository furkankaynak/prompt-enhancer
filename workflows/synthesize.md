# Synthesis Workflow

Produce the next round of candidates from survivors using crossover and mutation strategies. This is the evolutionary step that drives improvement between rounds.

## Inputs
- Survivors from previous round (with scores and critique notes)
- Tombstones (eliminated candidates — avoid repeating their approaches)
- Original user prompt (for re-injection)
- Current round number
- Strictness level
- Lock contract (all new candidates must stay within bounds)

## Synthesis Strategies

### 1. Crossover (1 candidate)

Combine the best traits of the top 2 survivors into a new hybrid candidate:
- Identify what each top survivor does best (from critique strengths)
- Merge those strengths into a single candidate
- Resolve any conflicts by favoring the higher-scored survivor's approach

ID: `c{round}-cross`
Strategy label: `"crossover (r{round}: {survivor1_id} x {survivor2_id})"`

### 2. Mutation (1 candidate per non-original survivor)

For each surviving candidate (except the original anchor):
- Read the critique weaknesses and improvement suggestion
- Apply the specific suggested improvement
- Address the identified weaknesses while preserving strengths
- Do NOT change what already works — targeted refinement only

ID: `c{round}-mut-{n}`
Strategy label: `"mutation (r{round}: refined {source_id})"`

### 3. Original Re-injection (always)

The original user prompt is always re-injected as `c-original`:
- Text: original prompt verbatim
- `isOriginal: true`
- Strategy label: `"original (reference anchor)"`

## Strictness Influence on Synthesis

- **low**: Mutations should be minimal — fix only the stated weakness, preserve everything else
- **balanced**: Mutations can be moderate — address weakness and make one additional improvement
- **high**: Mutations can be aggressive — rework significant portions if the critique warrants it

## Anti-Repetition Rules

Before producing each new candidate, check against tombstones:
- Do NOT recreate an approach that was already eliminated
- If a crossover or mutation would produce something very similar to a tombstoned candidate, pivot to a different approach
- The tombstone list grows across rounds — respect all of them

## Lock Contract Compliance

Every new candidate MUST:
1. Address the stated goal from the lock contract
2. Include all must_haves
3. Preserve all forbidden_changes guards
4. Align with success_criteria

If a synthesis would violate any lock constraint, adjust the candidate to comply before including it in the pool. Never produce a candidate that knowingly violates the lock.

## Output

A new candidate pool containing:
- 1 crossover candidate
- N mutation candidates (1 per non-original survivor)
- 1 original anchor (re-injected)

Total candidates per round: typically 4-5 (depending on survivor count).

Each candidate formatted as:
```
id: "{id}"
text: "{full prompt text}"
strategyLabel: "{strategy description}"
isOriginal: {true|false}
```
