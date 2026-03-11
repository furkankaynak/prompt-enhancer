# Research Stage Workflow

Execute once-upfront dual-source research to gather domain context and prompt patterns for diversity seeding.

This stage runs only when `research_mode=true` (default). It produces a compact research brief consumed by the generation stage.

## Inputs
- User prompt text
- Detected domain (coding/writing/data/general)

## Process

### Step 1: Build Search Queries

From the user prompt, extract:
- `{topic}`: the main subject/technology (e.g., "react", "blog", "sql")
- `{purpose}`: what the prompt does / the output type (e.g., "game", "post", "query")
- `{type}`: the task category (e.g., "coding", "writing", "data")

**Build 3 prompts.chat queries (max 2 words each):**
- Q1: `{topic} {purpose}` — e.g., "react game"
- Q2: `{topic} {type}` — e.g., "react coding"
- Q3: `{purpose} {type}` — e.g., "game dev"

**Build 1 web query (prompt-engineering focused):**
- Format: `"{topic} {purpose} prompt patterns"` or `"{domain} prompt engineering {purpose}"`
- Focus on prompt engineering patterns, not general architecture or best practices
- Example: "react game prompt patterns" — not "react tower defense game architecture best practices"

### Step 2: prompts.chat Retrieval

For each of the 3 queries (Q1, Q2, Q3):

```
URL: https://prompts.chat/api/prompts?q={url_encoded_query}&perPage=3
Extract: id and title for each result
```

Deduplicate results by id across all 3 queries. Filter: keep only results whose title aligns with the user's intent. Select top 2-3 unique relevant results for detail fetch.

For each selected result, fetch the full content:

```
URL: https://prompts.chat/api/prompts/{id}
Extract: structural patterns, constraints, role setup, output format
```

**On failure of any individual query**: skip it, continue with results from the other queries.
**On all queries failing**: record `[prompts.chat: unavailable]` and continue.

**If prompts.chat fails entirely** (HTTP error, empty results across all queries):
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

> **Note**: This synthesis step runs on a higher-capability model. Steps 1-3 are lightweight retrieval.

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

---

## API Reference: prompts.chat

**Search**: `GET https://prompts.chat/api/prompts?q={query}&perPage=3` — no auth required. Returns array of `{id, title, content}`. Use max 2-word queries for best results.

**Get by ID**: `GET https://prompts.chat/api/prompts/{id}` — returns single prompt with full `content`.

**WebFetch usage**:
- Search: URL = `https://prompts.chat/api/prompts?q={encoded_query}&perPage=3`, extract id + title per result (run 3 separate queries, deduplicate by id)
- Detail: URL = `https://prompts.chat/api/prompts/{id}`, extract structural patterns, constraints, sectioning, tone/role setup

**Rules**: Use as inspiration only (never copy verbatim). Filter for relevance before extracting. On failure, continue in degraded mode. Keep extracted patterns compact.
