# Score and Critique Workflow

Evaluate all candidates using Hybrid B scoring, then critique the top performers to guide synthesis.

Reference: `@./pe/references/scoring-rubric.md` for domain-specific dimensions.

## Inputs
- Candidate pool (all candidates for this round)
- Original user prompt
- Detected domain
- Lock contract (goal, must_haves, forbidden_changes, success_criteria)

## Step 1: Generate Eval Scenarios

Based on the detected domain, select the appropriate eval scenarios from the scoring rubric reference. These are the behavioral test cases each candidate is evaluated against.

For each scenario, ask: "If an AI assistant received this candidate prompt, would it reliably produce the expected behavior?"

## Step 2: Score Each Candidate

For every candidate in the pool, evaluate two scores:

### Eval-Set Score (0-1)
For each eval scenario (weighted):
- Imagine running this prompt through an AI assistant
- Would the output reliably match the expected behavior?
- Score: 0.0 = definitely not, 0.5 = partially, 1.0 = reliably yes
- Compute weighted sum across all scenarios

### Rubric Score (0-1)
For each rubric dimension (weighted, domain-specific):
- Evaluate the prompt text quality against the dimension description
- Use the 1.0/0.5/0.0 examples from the rubric reference as calibration
- Compute weighted sum across all dimensions

### Total Score
```
totalScore = 0.5 * evalSetScore + 0.5 * rubricScore
```

Round all scores to 3 decimal places.

## Step 3: Rank Candidates

Sort all candidates by totalScore descending. Assign dense ranks (tied scores get the same rank).

Produce a scoreboard:

```
Round: {round_number}
| Rank | ID | Strategy | Eval | Rubric | Total |
|------|----|----------|------|--------|-------|
| 1 | {id} | {strategy} | {eval} | {rubric} | {total} |
| 2 | {id} | {strategy} | {eval} | {rubric} | {total} |
| ... | ... | ... | ... | ... | ... |
```

## Step 4: Intent Lock Check

For each candidate, verify against the lock contract:

1. **Goal preservation**: Does the candidate still address the stated goal? If the candidate has drifted to a different objective, flag it.
2. **Must-haves check**: Are all must_haves from the lock contract present in the candidate? Check each one explicitly.
3. **Forbidden changes check**: Are all forbidden_changes guards still present? If any guard was dropped, flag it.

If a candidate fails any lock check:
- Mark it as `[LOCK VIOLATION: {which check failed}]`
- Exclude it from survivors
- Record in tombstones with reason

## Step 5: Select Survivors

Select the **top 4 candidates** by total score, with these rules:
- The original prompt (`c-original`) always survives regardless of score
- If the original is not in the top 4, replace the lowest-ranked non-original with it
- Lock-violated candidates are excluded before selection

For each survivor, produce a summary:
```
candidateId: {id}
text: {full prompt text}
totalScore: {score}
rationale: "{max 200 chars: why this survived}"
```

For each eliminated candidate, produce a tombstone:
```
candidateId: {id}
reason: "{max 100 chars: why eliminated}"
```

## Step 6: Critique Top Candidates

For the top 2-3 survivors (excluding the original anchor), provide specific critique:

For each:
1. **Strengths**: What this candidate does better than others (1-2 points)
2. **Weaknesses**: Specific, actionable problems (1-2 points)
3. **Improvement suggestion**: One concrete change that would improve the score

These critique notes feed directly into the synthesis stage for the next round.

Format:
```
### Critique: {candidateId} ({strategyLabel})
- Strengths: {point 1}; {point 2}
- Weaknesses: {point 1}; {point 2}
- Suggested improvement: {specific actionable change}
```

## Convergence Signal

After scoring, compute the convergence signal for the orchestrator:
- If this is round >= 2: compare the top score to the previous round's top score
- If improvement < 0.01 (1%), signal convergence
- Report: `convergence_delta: {delta}` and `converged: {true|false}`
