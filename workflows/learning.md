# Learning Workflow

Capture user choices across runs and maintain aggregate preferences to bias future optimization.

## Inputs
- Run metadata (domain, originalPrompt snippet, winnerStrategy, userPick, strictness, rounds, topScore, originalScore, auto_mode)
- History file path: `.pe/history.json`

## Step 1: Read Existing History

Read `.pe/history.json` if it exists. If it doesn't exist or is malformed, start with an empty structure:

```json
{
  "runs": [],
  "preferences": {
    "preferred_strategies": {},
    "avg_score_lift": 0,
    "typical_domain": "general",
    "typical_strictness": "balanced",
    "runs_total": 0
  }
}
```

## Step 2: Record the Run

Append a new entry to the `runs` array:

```json
{
  "id": "run_{timestamp}",
  "timestamp": "{ISO 8601 timestamp}",
  "domain": "{domain}",
  "originalPrompt": "{first 200 chars of original prompt}",
  "winnerStrategy": "{strategy label of the winner candidate}",
  "userPick": "{winner|altA|altB|original|none}",
  "strictness": "{strictness}",
  "rounds": {rounds_completed},
  "topScore": {top_score},
  "originalScore": {original_score},
  "autoMode": {true|false}
}
```

**Cap**: Keep only the last 50 runs. If `runs` exceeds 50, remove the oldest entries.

## Step 3: Map User Pick to Strategy

Determine which strategy the user actually chose:

| userPick | Strategy to credit |
|----------|--------------------|
| winner | winnerStrategy from run metadata |
| altA | strategy label of Alt A candidate |
| altB | strategy label of Alt B candidate |
| original | "original" |
| none | no credit (skip preference update) |

## Step 4: Update Aggregate Preferences

Recalculate `preferences` from the full `runs` array:

### preferred_strategies
Count how many times each strategy was picked (excluding `none` picks):
```json
"preferred_strategies": {
  "structural_rework": 5,
  "faithful_rewrite": 2,
  "creative_restructuring": 1,
  "crossover": 1,
  "original": 0
}
```

Strategy labels are normalized to snake_case for consistency: strip `(r1: ...)` suffixes, collapse whitespace, lowercase.

### avg_score_lift
Average of `(topScore - originalScore)` across all runs where `userPick != "none"`.

### typical_domain
Most frequent domain across all runs.

### typical_strictness
Most frequent strictness across all runs.

### runs_total
Total number of runs recorded.

## Step 5: Write Updated History

Write the updated structure back to `.pe/history.json`.

Ensure the `.pe/` directory exists before writing. Create it if missing.

## How Preferences Are Used

The orchestrator passes `learning_preferences` to the generation stage (Section 6). The generation workflow uses `preferred_strategies` to bias candidate generation:

- If a strategy has **3x+ picks** over the next most-picked strategy, generate 2 candidates with that strategy instead of 1, dropping the least-preferred strategy
- If `avg_score_lift < 0.05` across the last 5 runs, the system could benefit from `--quick` mode (note this in status output but don't force it)
- If user consistently picks "original" (3+ times in last 5 runs), note in status: "Your recent prompts have been strong — consider using --quick for lighter optimization"

## Privacy

- Only the first 200 characters of each prompt are stored
- History is per-project (`.pe/history.json` in project root)
- User can reset with `/pe:settings reset-history`
- No data leaves the local machine
