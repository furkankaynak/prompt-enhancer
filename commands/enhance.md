---
name: pe:enhance
description: Enhance any prompt using multi-round agentic optimization. Produces a ranked output package with winner, safe alternative, exploratory alternative, change log, and scoring rationale. Use when you want to improve a prompt before starting a coding task.
argument-hint: "<prompt> [--no-research] [--strictness=low|balanced|high] [--rounds=1-3] [--output=full|diff|annotated]"
allowed-tools:
  - Read
  - Write
  - WebFetch
  - WebSearch
  - AskUserQuestion
  - Glob
  - Grep
---

<objective>
Take a user-provided prompt and enhance it through iterative optimization into a high-signal, execution-ready prompt package. The process preserves the user's original intent while improving clarity, structure, constraints, and evaluability through multi-round refinement inspired by PromptWizard methodology.

Output: Winner prompt + Safe alternative + Exploratory alternative + Change log + Scoring summary.
</objective>

<execution_context>
@./pe/workflows/enhance-orchestrator.md
@./pe/references/scoring-rubric.md
@./pe/references/data-contracts.md
@./pe/references/prompts-chat-api.md
@./pe/templates/output-package.md
@./pe/workflows/research.md
@./pe/workflows/generate.md
@./pe/workflows/score-critique.md
@./pe/workflows/synthesize.md
@./pe/workflows/select-present.md
</execution_context>

<context>
Arguments: $ARGUMENTS

Defaults (if flags not provided):
- research_mode: true (use --no-research to disable)
- strictness: balanced
- max_rounds: 3
- output_format: full

The prompt text is the main positional argument. It can be quoted or unquoted.

Examples:
- /pe:enhance "Write a function that sorts an array"
- /pe:enhance Build a REST API for user management --strictness=high
- /pe:enhance "Explain async/await in TypeScript" --no-research --output=diff
- /pe:enhance "Create a React dashboard component" --rounds=2 --output=annotated
</context>

<process>
Execute the enhance orchestrator workflow from @./pe/workflows/enhance-orchestrator.md end-to-end.

Follow every section in order:
1. Parse and validate arguments
2. Assess context confidence
3. Ask one clarification question (if confidence < 0.6)
4. Present enhancement plan and get user approval (alignment gate)
5. Run research (if enabled)
6. Execute optimization loop (generate > score/critique > synthesize, up to max_rounds)
7. Select portfolio and present output package

Do not skip the alignment gate (Section 4). The user must approve before optimization begins.
</process>
