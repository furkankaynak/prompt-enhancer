# Data Contracts Reference

Internal artifact shapes used throughout the enhancement workflow. These define what each structured artifact looks like when passed between stages.

## RequestEnvelope

The normalized run request after parsing command arguments.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| prompt | string (non-empty) | required | Original prompt text to enhance |
| research_mode | boolean | true | Whether to run upfront research |
| strictness | "low" \| "balanced" \| "high" | "balanced" | How aggressively to rewrite |
| output_format | "full" \| "diff" \| "annotated" | "full" | Output presentation format |
| max_rounds | integer 1-3 | 3 | Maximum optimization rounds |
| auto_mode | boolean | false | Skip clarification + alignment gate |
| run_id | string | auto-generated | Format: `run_{timestamp}_{random}` |
| created_at | ISO string | auto-generated | Run start timestamp |

## LockContract

Immutable intent and constraints established at the alignment gate. Checked every round.

| Field | Type | Description |
|-------|------|-------------|
| goal | string (non-empty) | The primary objective of the enhancement run |
| must_haves | string[] | Constraints every candidate must preserve |
| forbidden_changes | string[] | Guards that must not be dropped between rounds |
| success_criteria | string[] | Outcome requirements defining acceptable completion |

## AnatomyContract

Immutable structural analysis built at the alignment gate. Identifies which Anthropic best-practice elements are present or missing in the original prompt. Flows through RoundContext to every agent.

**10-element anatomy checklist:**

| Element ID | Element Name | Description |
|------------|--------------|-------------|
| `role` | Role assignment | A clear persona or role given to Claude |
| `context_why` | Context / Why | Explanation of why the task matters or how the output will be used |
| `xml_structure` | XML structure | Semantic XML tags (`<instructions>`, `<context>`, `<input>`, etc.) |
| `output_format` | Output format spec | Explicit format, length, or structure specification for the response |
| `positive_instructions` | Positive instructions | Instructions stated as what to do, not what not to do |
| `examples` | Examples | `<example>` blocks or inline examples |
| `success_criteria` | Success criteria | Explicit conditions defining a correct/complete output |
| `self_check` | Self-check instruction | Instruction to verify/review before answering |
| `long_context_order` | Long context ordering | Data placed above query (relevant only when prompt includes longform input) |
| `agentic_action_guidance` | Agentic action guidance | Explicit act vs confirm boundary (relevant only for agentic prompts) |

**Scoring calibrations** (used by scorer's anatomyScore):
- 1.0 = element clearly and explicitly present
- 0.5 = element partially present (implied but not explicit; vague)
- 0.0 = element absent

| Field | Type | Description |
|-------|------|-------------|
| elements_present | string[] | Anatomy element IDs found in the original prompt |
| elements_missing | string[] | Anatomy element IDs absent from the original prompt |
| priority_gaps | string[] (max 3) | Top 3 highest-impact missing elements for this domain |
| domain | string | Domain this analysis was computed for |
| agentic_prompt | boolean | Whether the prompt appears to be for an agentic/multi-step task |

**Priority order by domain** (highest to lowest):
- coding: `output_format > xml_structure > role > success_criteria > examples > positive_instructions > context_why > self_check > long_context_order`
- writing: `role > context_why > output_format > examples > success_criteria > xml_structure > positive_instructions > self_check > long_context_order`
- data: `output_format > xml_structure > success_criteria > examples > role > long_context_order > context_why > positive_instructions`
- general: `context_why > role > output_format > success_criteria > examples > xml_structure > positive_instructions > self_check > long_context_order`
- For agentic prompts (any domain): `agentic_action_guidance` always enters top 3 if missing

## AnatomyGapReport

Lightweight derivation for display in the alignment gate. Not stored in RoundContext.

| Field | Type | Description |
|-------|------|-------------|
| gap_count | integer | How many elements are missing |
| present_summary | string | One-line summary of present elements |
| missing_summary | string | One-line summary of missing elements |

## Candidate

A single prompt variant in the optimization pool.

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique identifier (e.g., `c1`, `c2`, `c-original`) |
| text | string (non-empty) | Full prompt text of this candidate |
| strategyLabel | string | Human-readable generation strategy (e.g., "faithful rewrite") |
| isOriginal | boolean (default false) | Whether this is the original user prompt anchor |

## CandidatePool

Collection of candidates produced at a specific round.

| Field | Type | Description |
|-------|------|-------------|
| candidates | Candidate[] (min 1) | All candidates in this pool |
| originalPrompt | string | Original user prompt for re-injection |
| generatedAt | integer >= 0 | Round number (0 = initial generation) |

## ScoreBreakdown

Hybrid B score for a single candidate. All scores normalized to [0, 1].

| Field | Type | Description |
|-------|------|-------------|
| evalSetScore | number 0-1 | Behavioral score from eval-set scenarios |
| rubricScore | number 0-1 | Quality score from rubric dimension judging |
| anatomyScore | number 0-1 | Best-practice structure adherence score (10-element checklist) |
| totalScore | number 0-1 | Weighted composite: `0.40 * evalSetScore + 0.35 * rubricScore + 0.25 * anatomyScore` |

## ScoredCandidate

A candidate linked to its score and rank.

| Field | Type | Description |
|-------|------|-------------|
| candidateId | string | Reference to candidate id |
| label | string | Strategy label (denormalized for display) |
| scores | ScoreBreakdown | Full score breakdown |
| rank | integer >= 1 | Rank position (1 = highest) |

## Scoreboard

All candidates scored and ranked for a round.

| Field | Type | Description |
|-------|------|-------------|
| round | integer >= 0 | Round number (0 = initial baseline) |
| entries | ScoredCandidate[] | All scored entries, ordered by rank |

## SurvivorSummary

Compact carry-forward representation of a surviving candidate.

| Field | Type | Description |
|-------|------|-------------|
| candidateId | string | Reference to candidate id |
| text | string | Full prompt text |
| totalScore | number 0-1 | Total Hybrid B score |
| rationale | string (max 200 chars) | One-line survival rationale |

## Tombstone

Record of an eliminated candidate. Prevents reinventing failed approaches.

| Field | Type | Description |
|-------|------|-------------|
| candidateId | string | Reference to eliminated candidate id |
| reason | string (max 100 chars) | One-line elimination reason |

## RoundContext

Compact carry-forward between rounds. This IS the compaction discipline — only these fields travel between rounds.

| Field | Type | Description |
|-------|------|-------------|
| round | integer >= 0 | Current round number |
| survivors | SurvivorSummary[] | Surviving candidates |
| tombstones | Tombstone[] | All eliminated candidates so far |
| originalPrompt | string | Re-injected each round |
| lockContract | LockContract | Re-injected each round |
| anatomyContract | AnatomyContract | Re-injected each round — immutable once built at alignment gate |

## RunHistoryEntry

A single run record for cross-run learning. Stored in `.contextify/history.json`.

| Field | Type | Description |
|-------|------|-------------|
| id | string | Format: `run_{timestamp}` |
| timestamp | ISO string | When the run completed |
| domain | string | Detected domain |
| originalPrompt | string (max 200 chars) | Truncated original prompt |
| winnerStrategy | string | Strategy label of the winner candidate |
| userPick | "winner" \| "altA" \| "altB" \| "original" \| "none" | Which portfolio option the user chose |
| strictness | string | Strictness level used |
| rounds | integer | Rounds completed |
| topScore | number 0-1 | Highest score in final round |
| originalScore | number 0-1 | Original prompt's score in final round |
| autoMode | boolean | Whether --auto was used |

## LearningPreferences

Aggregate preferences computed from run history. Updated after each run.

| Field | Type | Description |
|-------|------|-------------|
| preferred_strategies | object | Map of strategy name → pick count |
| avg_score_lift | number | Average (topScore - originalScore) across runs with a pick |
| typical_domain | string | Most frequent domain |
| typical_strictness | string | Most frequent strictness |
| runs_total | integer | Total runs recorded |
