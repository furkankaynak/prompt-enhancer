---
name: pe:enhance
description: Enhance any prompt using multi-round agentic optimization. Produces a ranked output package with winner, safe alternative, exploratory alternative, change log, and scoring rationale. Use when you want to improve a prompt before starting a coding task.
argument-hint: "<prompt> [--auto] [--quick] [--no-research] [--strictness=low|balanced|high] [--rounds=1-3] [--output=full|diff|annotated]"
allowed-tools:
  - Read
  - Write
  - WebFetch
  - WebSearch
  - AskUserQuestion
  - Glob
  - Grep
  - Agent
---

<objective>
Take a user-provided prompt and enhance it through iterative optimization into a high-signal, execution-ready prompt package. The process preserves the user's original intent while improving clarity, structure, constraints, and evaluability through multi-round refinement inspired by PromptWizard methodology.

Output: Winner prompt + Safe alternative + Exploratory alternative + Change log + Scoring summary.
</objective>

<execution_context>
@./pe/workflows/enhance-orchestrator.md
</execution_context>

<context>
Arguments: $ARGUMENTS

Defaults (if flags not provided):
- research_mode: true (use --no-research to disable)
- strictness: balanced
- max_rounds: 3
- output_format: full
- auto_mode: false (use --auto to skip clarification + alignment gate)

The prompt text is the main positional argument. It can be quoted or unquoted.

Flags:
- --auto: Skip clarification and alignment gate. Auto-builds LockContract. Perfect for vibe coders who want results fast.
- --quick: Convenience alias for --auto --no-research --rounds=1 --output=diff. Quick prompt clinic mode.

Examples:
- /pe:enhance "Write a function that sorts an array"
- /pe:enhance Build a REST API for user management --strictness=high
- /pe:enhance "Explain async/await in TypeScript" --no-research --output=diff
- /pe:enhance "Create a React dashboard component" --rounds=2 --output=annotated
- /pe:enhance "Build a todo app" --auto
- /pe:enhance "Sort an array" --quick
</context>

<process>
Execute the enhance orchestrator workflow from @./pe/workflows/enhance-orchestrator.md end-to-end.

Subagent dispatch uses named PE subagents (pe-researcher, pe-research-synth, pe-generator, pe-scorer, pe-synthesizer, pe-presenter, pe-learner) defined in .claude/agents/. If named subagents are unavailable, falls back to generic Agent tool dispatch.

Follow every section in order:
1. Parse and validate arguments (including --auto and --quick flags)
2. Assess context confidence
3. Ask one clarification question (if confidence < 0.6 AND auto_mode=false; if auto_mode=true, only ask if confidence < 0.3)
4. Present enhancement plan and get user approval (alignment gate) — skipped if auto_mode=true
5. Run research (if enabled) — via pe-researcher + pe-research-synth subagents
6. Execute optimization loop (generate > score/critique > synthesize, up to max_rounds) — via pe-generator, pe-scorer, pe-synthesizer subagents
7. Select portfolio and present output package — via pe-presenter subagent
8. Capture user choice for cross-run learning — via pe-learner subagent

Do not skip the alignment gate (Section 4) unless --auto or --quick is set. The user must approve before optimization begins in normal mode.
</process>
