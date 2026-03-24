<!-- Source of truth. Content is embedded in agents/contextify-scorer.md. Keep in sync. -->
# Score, Critique & Rubric Bundle

Evaluate all candidates using Hybrid B scoring, then critique the top performers to guide synthesis.

## Inputs
- Candidate pool (all candidates for this round)
- Original user prompt
- Detected domain
- Lock contract (goal, must_haves, forbidden_changes, success_criteria)

## Step 1: Generate Eval Scenarios

Based on the detected domain, select eval scenarios from the tables below. For each scenario, ask: "If an AI assistant received this candidate prompt, would it reliably produce the expected behavior?"

## Step 2: Score Each Candidate

### Eval-Set Score (0-1)
For each eval scenario (weighted): score 0.0 = definitely not, 0.5 = partially, 1.0 = reliably yes. Compute weighted sum.

### Rubric Score (0-1)
For each rubric dimension (weighted, domain-specific): evaluate prompt text quality using 1.0/0.5/0.0 calibrations below. Compute weighted sum.

### Total Score
```
totalScore = 0.5 * evalSetScore + 0.5 * rubricScore
```
Round all scores to 2 decimal places.

## Step 3: Rank Candidates

Sort by totalScore descending. Dense ranks (ties get same rank).

```
Round: {round_number}
| Rank | ID | Strategy | Eval | Rubric | Total |
|------|----|----------|------|--------|-------|
```

## Step 4: Intent Lock Check

For each candidate, verify against the lock contract:
1. **Goal preservation**: Does the candidate still address the stated goal?
2. **Must-haves check**: Are all must_haves present?
3. **Forbidden changes check**: Are all guards still present?

If a candidate fails any check: mark `[LOCK VIOLATION: {which}]`, exclude from survivors, record in tombstones.

## Step 5: Select Survivors

Top 4 by total score. Rules:
- `c-original` always survives regardless of score
- If original not in top 4, replace lowest non-original with it
- Lock violators excluded before selection

Per survivor:
```
candidateId: {id} | totalScore: {score} | rationale: "{max 200 chars}"
```

Per eliminated:
```
candidateId: {id} | reason: "{max 100 chars}"
```

## Step 6: Critique Top Candidates

For top 2-3 survivors (excluding original anchor):
```
### Critique: {candidateId} ({strategyLabel})
- Strengths: {point 1}; {point 2}
- Weaknesses: {point 1}; {point 2}
- Suggested improvement: {specific actionable change}
```

## Convergence Signal

At round >= 2: compare top score to previous round. If improvement < 0.01 (1%), signal convergence.
Report: `convergence_delta: {delta}`, `converged: {true|false}`

---

## Eval Scenarios by Domain

### Coding
| Scenario | Expected Behavior | Weight |
|----------|-------------------|--------|
| Valid input processing | Correctly processes well-formed input, returns expected type | 0.30 |
| Edge case handling | Handles empty, single element, max size | 0.25 |
| Error input handling | Rejects/handles malformed input with clear messaging | 0.25 |
| Large input scalability | Maintains correctness with large inputs | 0.20 |

### Writing
| Scenario | Expected Behavior | Weight |
|----------|-------------------|--------|
| Main topic coverage | Addresses primary subject thoroughly | 0.30 |
| Tone consistency | Maintains appropriate tone throughout | 0.25 |
| Key points coverage | Covers all essential points | 0.25 |
| Audience appropriateness | Suitable for intended audience level | 0.20 |

### Data
| Scenario | Expected Behavior | Weight |
|----------|-------------------|--------|
| Data accuracy | Produces accurate results matching source | 0.30 |
| Format correctness | Output follows specified format exactly | 0.25 |
| Completeness | All requested fields present | 0.25 |
| Missing data handling | Handles nulls without crashing | 0.20 |

### General
| Scenario | Expected Behavior | Weight |
|----------|-------------------|--------|
| Primary request fulfillment | Directly addresses core request | 0.30 |
| Ambiguity handling | Reasonable assumptions or clarification | 0.25 |
| Actionable output | Concrete, actionable results | 0.25 |
| Completeness | Full scope, no significant gaps | 0.20 |

---

## Rubric Dimensions by Domain

### Coding
| Dimension | 1.0 | 0.5 | 0.0 | Weight |
|-----------|-----|-----|-----|--------|
| Clarity | Every requirement explicit, no ambiguity | Some clear, others need inference | Vague/contradictory | 0.30 |
| Completeness | All inputs, outputs, constraints, edge cases | Core present, gaps in edges | Missing fundamentals | 0.25 |
| Edge-case coverage | Explicit empty/null/overflow handling | Some mentioned, not comprehensive | None | 0.25 |
| Error handling | Clear error types, messages, recovery | Mentioned but not specific | None specified | 0.20 |

### Writing
| Dimension | 1.0 | 0.5 | 0.0 | Weight |
|-----------|-----|-----|-----|--------|
| Voice consistency | Specific tone, register, style guidelines | General tone indicated | No voice guidance | 0.25 |
| Structure | Clear sections, flow, length expectations | Some structure implied | No structural guidance | 0.25 |
| Clarity | Unambiguous with specific expectations | Mostly clear, some open questions | Vague/confusing | 0.25 |
| Audience fit | Specific audience with knowledge level | General audience mentioned | No audience context | 0.25 |

### Data
| Dimension | 1.0 | 0.5 | 0.0 | Weight |
|-----------|-----|-----|-----|--------|
| Accuracy | Precision, validation rules, source constraints | General accuracy expectation | No requirements | 0.30 |
| Completeness | Every field, transformation detailed | Core present, gaps in transforms | Missing fundamentals | 0.25 |
| Format correctness | Exact format with examples, delimiters | Format type mentioned | No format spec | 0.25 |
| Validation | Input validation, type checking, constraints | Some validation mentioned | None specified | 0.20 |

### General
| Dimension | 1.0 | 0.5 | 0.0 | Weight |
|-----------|-----|-----|-----|--------|
| Relevance | Laser-focused on primary objective | Related but tangential elements | Off-target/too broad | 0.25 |
| Clarity | Crystal clear, no ambiguity | Mostly clear, minor gaps | Vague/confusing | 0.25 |
| Actionability | Specific, executable instructions | General guidance needing interpretation | Abstract, no clear actions | 0.25 |
| Completeness | Full coverage of request scope | Partial, notable gaps | Major aspects missing | 0.25 |
