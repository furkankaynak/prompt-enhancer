# Scoring Rubric Reference

Domain-adaptive rubric dimensions for Hybrid B scoring. Use this reference when evaluating candidate prompts.

## Scoring Method

Each candidate is scored on two axes:
1. **Eval-set score** (0-1): Would this prompt reliably elicit correct behavior across test scenarios?
2. **Rubric score** (0-1): How well does the prompt text score against quality dimensions?
3. **Total score**: `0.5 * evalSetScore + 0.5 * rubricScore`

## Domain Detection

Classify the prompt into one domain based on keywords and intent:
- **Coding**: function, class, API, endpoint, implement, algorithm, database, TypeScript, Python, etc.
- **Writing**: write, essay, article, blog, story, content, tone, audience, narrative, etc.
- **Data**: data, CSV, JSON, table, analyze, transform, aggregate, report, metric, etc.
- **General**: anything that doesn't clearly match the above

## Eval Scenarios by Domain

### Coding
| Scenario | Expected Behavior | Weight |
|----------|-------------------|--------|
| Valid input processing | Correctly processes well-formed input and returns expected output type | 0.30 |
| Edge case handling | Handles boundary conditions (empty input, single element, max size) | 0.25 |
| Error input handling | Rejects or handles malformed input with clear error messaging | 0.25 |
| Large input scalability | Maintains correctness and reasonable performance with large inputs | 0.20 |

### Writing
| Scenario | Expected Behavior | Weight |
|----------|-------------------|--------|
| Main topic coverage | Addresses the primary subject thoroughly and accurately | 0.30 |
| Tone and voice consistency | Maintains appropriate tone throughout the output | 0.25 |
| Key points coverage | Covers all essential points mentioned or implied | 0.25 |
| Audience appropriateness | Content is suitable for the intended audience level | 0.20 |

### Data
| Scenario | Expected Behavior | Weight |
|----------|-------------------|--------|
| Data accuracy | Produces accurate results matching source data | 0.30 |
| Format correctness | Output follows the specified format exactly | 0.25 |
| Completeness | All requested data fields present with no omissions | 0.25 |
| Missing data handling | Handles missing or null values without crashing | 0.20 |

### General
| Scenario | Expected Behavior | Weight |
|----------|-------------------|--------|
| Primary request fulfillment | Directly addresses the core request | 0.30 |
| Ambiguity handling | Makes reasonable assumptions or asks for clarification | 0.25 |
| Actionable output | Produces concrete, actionable results | 0.25 |
| Completeness | Covers the full scope without significant gaps | 0.20 |

## Rubric Dimensions by Domain

### Coding
| Dimension | Description | 1.0 | 0.5 | 0.0 | Weight |
|-----------|-------------|-----|-----|-----|--------|
| Clarity | How clear and unambiguous the instructions are | Every requirement is explicit with no room for interpretation | Some requirements are clear but others need inference | Vague or contradictory instructions | 0.30 |
| Completeness | Whether all necessary requirements are covered | All inputs, outputs, constraints, and edge cases specified | Core requirements present but gaps in edge cases or constraints | Missing fundamental requirements | 0.25 |
| Edge-case coverage | Whether boundary conditions are addressed | Explicit handling for empty, null, overflow, and error inputs | Some edge cases mentioned but not comprehensive | No edge case consideration | 0.25 |
| Error handling | Whether error scenarios are specified | Clear error types, messages, and recovery strategies | Error handling mentioned but not specific | No error handling specified | 0.20 |

### Writing
| Dimension | Description | 1.0 | 0.5 | 0.0 | Weight |
|-----------|-------------|-----|-----|-----|--------|
| Voice consistency | Whether tone/voice is established | Specific tone, register, and style guidelines given | General tone indicated but not detailed | No voice guidance | 0.25 |
| Structure | Whether structural guidance is provided | Clear sections, flow, and length expectations | Some structure implied but incomplete | No structural guidance | 0.25 |
| Clarity | How clear the instructions are | Unambiguous with specific expectations | Mostly clear but some open questions | Vague or confusing | 0.25 |
| Audience fit | Whether target audience is specified | Specific audience with knowledge level and needs | General audience mentioned | No audience context | 0.25 |

### Data
| Dimension | Description | 1.0 | 0.5 | 0.0 | Weight |
|-----------|-------------|-----|-----|-----|--------|
| Accuracy | Whether accuracy requirements are specified | Precision, validation rules, and source constraints defined | General accuracy expectation stated | No accuracy requirements | 0.30 |
| Completeness | Whether all fields and transforms are specified | Every field, transformation, and aggregation detailed | Core fields present but gaps in transformations | Missing fundamental data requirements | 0.25 |
| Format correctness | Whether output format is precise | Exact format with examples and delimiters | Format type mentioned but not detailed | No format specification | 0.25 |
| Validation | Whether data validation rules are specified | Input validation, type checking, and constraint rules | Some validation mentioned | No validation specified | 0.20 |

### General
| Dimension | Description | 1.0 | 0.5 | 0.0 | Weight |
|-----------|-------------|-----|-----|-----|--------|
| Relevance | How directly it addresses the core need | Laser-focused on the primary objective | Related but includes tangential elements | Off-target or too broad | 0.25 |
| Clarity | How clear the instructions are | Crystal clear, no ambiguity | Mostly clear with minor gaps | Vague or confusing | 0.25 |
| Actionability | Whether it produces actionable results | Specific, executable instructions | General guidance that needs interpretation | Abstract with no clear actions | 0.25 |
| Completeness | Whether it covers all aspects | Full coverage of the request scope | Partial coverage with notable gaps | Major aspects missing | 0.25 |
