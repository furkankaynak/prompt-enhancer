# Research Stage Workflow

Execute once-upfront dual-source research to gather domain context and prompt patterns for diversity seeding.

This stage runs only when `research_mode=true` (default). It produces a compact research brief consumed by the generation stage.

## Inputs
- User prompt text
- Detected domain (coding/writing/data/general)

## Process

### Step 1: Build Search Queries

From the user prompt, extract:
1. The core intent (what the user wants to accomplish)
2. The domain (coding, writing, data, general)
3. Key technical terms or subject keywords

Build two queries:
- **prompts.chat query**: Focus on the task type and domain. Example: for "build a React tower defense game", query = "react game development prompt"
- **Web query**: Focus on best practices and conventions. Example: "react tower defense game architecture best practices"

### Step 2: prompts.chat Retrieval

Use WebFetch to search prompts.chat:

```
URL: https://prompts.chat/api/prompts?q={url_encoded_query}&perPage=5
Prompt: "Extract the id and title for each result. Return as a numbered list with id and title."
```

From the search results, select the top 2-3 most relevant results (filter by title alignment with user intent).

For each selected result, fetch the full content:

```
URL: https://prompts.chat/api/prompts/{id}
Prompt: "Extract the full prompt content. Identify and list: (1) structural patterns used (sections, headers, numbering), (2) constraints or rules specified, (3) role/persona setup if any, (4) output format specifications."
```

**If prompts.chat fails** (HTTP error, empty results, irrelevant results):
- Record: `[prompts.chat: unavailable — {reason}]`
- Continue to web research
- Do NOT retry or block

### Step 3: Web Research

Use WebSearch with the web query to find domain best practices.

From the search results, extract:
- Common structural patterns for this type of prompt
- Domain-specific constraints and quality standards
- Conventions that experienced practitioners follow
- Anti-patterns to avoid

**If web research fails** (no useful results):
- Record: `[web research: unavailable — {reason}]`
- Continue with whatever research was gathered
- Do NOT retry or block

### Step 4: Produce Research Brief

Synthesize findings into a compact research brief (max 500 words):

```
## Research Brief

### Sources Used
- prompts.chat: {number of prompts examined} | {status}
- Web research: {number of sources examined} | {status}

### Structural Patterns Observed
- {pattern 1}
- {pattern 2}
- ...

### Domain Conventions
- {convention 1}
- {convention 2}
- ...

### Constraints and Quality Standards
- {standard 1}
- {standard 2}
- ...

### Seed Inspiration (for candidate generation)
- {inspiration point 1 — NOT a verbatim copy, a distilled pattern}
- {inspiration point 2}
- ...

{[DEGRADED MODE: {which sources were unavailable}] — only if applicable}
```

## Guardrails

- Never copy retrieved prompt content verbatim — extract patterns only
- Keep the brief under 500 words — this feeds into the context for generation
- If both sources fail, produce a minimal brief noting degraded mode and continue
- Research findings are supplemental — internal generation is always the primary source
