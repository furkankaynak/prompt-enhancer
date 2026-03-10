---
name: pe:settings
description: View and update default settings for prompt enhancement runs. Settings persist per-project in .pe/settings.json.
argument-hint: "[view|set|reset] [--strictness=low|balanced|high] [--research=true|false] [--rounds=1-3] [--output=full|diff|annotated]"
allowed-tools:
  - Read
  - Write
  - AskUserQuestion
---

<objective>
Manage per-project default settings for /pe:enhance. Settings are stored in .pe/settings.json in the project root and override schema defaults. Command-line flags on /pe:enhance override project settings.

Precedence: command flags > project settings > schema defaults.
</objective>

<context>
Arguments: $ARGUMENTS

Subcommands:
- view (default if no args): Display current effective settings
- set: Update one or more settings
- reset: Reset all settings to schema defaults (deletes .pe/settings.json)

Schema defaults:
- research_mode: true
- strictness: "balanced"
- max_rounds: 3
- output_format: "full"
</context>

<process>
1. Parse the subcommand from arguments (default: view).

2. For "view":
   - Read .pe/settings.json if it exists
   - Display effective settings (merged with schema defaults)
   - Show which values come from project settings vs schema defaults

3. For "set":
   - Parse the flags from arguments
   - Validate each value:
     - strictness must be low|balanced|high
     - research must be true|false
     - rounds must be integer 1-3
     - output must be full|diff|annotated
   - Read existing .pe/settings.json (or start from empty)
   - Merge new values
   - Write updated .pe/settings.json
   - Display the updated effective settings

4. For "reset":
   - Ask user to confirm: "Reset all settings to defaults?"
   - If confirmed, delete .pe/settings.json
   - Display schema defaults

Example usage:
- /pe:settings -> show current settings
- /pe:settings set --strictness=high --rounds=2
- /pe:settings reset
</process>
