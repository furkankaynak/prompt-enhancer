# prompts.chat REST API Reference

Quick reference for the two REST endpoints used in the research stage.

## Endpoints

### Search Prompts
```
GET https://prompts.chat/api/prompts?q={query}&perPage={n}
```
- No authentication required for public search
- `q`: URL-encoded search query
- `perPage`: number of results (use 5 for v1)
- Returns: array of prompt objects with `id`, `title`, `content`, and metadata

### Get Prompt by ID
```
GET https://prompts.chat/api/prompts/{id}
```
- No authentication required for public prompts
- Returns: single prompt object with full `content`

## Usage in WebFetch

**Search call:**
```
URL: https://prompts.chat/api/prompts?q={encoded_query}&perPage=5
Prompt: "Extract the id, title, and a 1-sentence summary for each result. Return as a numbered list."
```

**Get-by-ID call:**
```
URL: https://prompts.chat/api/prompts/{id}
Prompt: "Extract the full prompt content and identify: structural patterns, constraints used, sectioning approach, and tone/role setup."
```

## Guardrails

- Use retrieved prompts as **inspiration only**, never copy verbatim
- Filter results for relevance before extracting patterns
- If retrieval fails (HTTP error, empty results, timeout), continue in degraded mode
- Keep extracted patterns compact (pass distilled patterns to the loop, not raw content)
- External retrieval is supplemental — internal generation is always mandatory
