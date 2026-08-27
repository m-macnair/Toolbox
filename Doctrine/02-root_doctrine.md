# root_doctrine
---
content_version: 2026-08-26.1
ai_contract: ai_assisted
inherits:
	- doctrine_format
---

## Normative Terminology

The following terms have precise meanings within this doctrine:

- **MUST** - An absolute requirement. Non-compliance makes code non-conforming.
- **SHOULD+** - The prescribed requirement. Deviation is permitted only with a documented exception decision.
- **SHOULD** - The prescribed default. Deviation is permitted through engineering judgement.
- **MAY** - Explicitly permitted but optional.

### Conformance

- **NOTE** - **CONFORMING** means code that satisfies all applicable `MUST` and `MUST NOT` requirements.
- **NOTE** - **NON-CONFORMING** means code that violates one or more applicable `MUST` or `MUST NOT` requirements.

### Doctrine

- **NOTE** - **ROOT DOCTRINE** means rules applicable to all coding tasks.
- **NOTE** - **LANGUAGE DOCTRINE** means rules supplementing the Root Coding Doctrine for a particular language or ecosystem.
- **NOTE** - **PROJECT DOCTRINE** means rules supplementing the applicable doctrines for a particular project.

## Doctrine Hierarchy

- **MUST NOT** - A more specific doctrine MUST NOT contradict a broader `MUST` requirement unless compliance is impossible in the applicable language or environment.
- **MAY** - A more specific doctrine MAY refine a broader doctrine where the two are compatible.
- **NOTE** - Rules are applied in the following order:
	1. Root Doctrine
	2. Language Doctrine
	3. Project Doctrine

## Rules

### Date and Time

- **SHOULD+** - Dates SHOULD use ISO 8601 date format: `YYYY-MM-DD`.
- **SHOULD+** - Timestamps SHOULD use ISO 8601 format and represent UTC using the `Z` designator.
- **MAY** - Times that are not part of a timestamp MAY use any appropriate representation.

### Indentation

- **MUST NOT** - Spaces MUST NOT be used for indentation.
- **MUST** - Indentation MUST use tab characters.

### Identifier Naming

- **SHOULD** - Identifiers SHOULD use lower_snake_case.

### ASCII

- **SHOULD+** - Code, documentation, comments, configuration, and identifiers SHOULD use ASCII characters only. Non-ASCII characters require a documented exception decision, except where the character is specifically being represented as content.
- **SHOULD NOT** - Long dash characters, including em dash and en dash, SHOULD NOT be used. ASCII equivalents SHOULD be used instead.
- **NOTE** - Non-ASCII characters require a documented exception decision except in the case of representing specific charac.

### Markdown

- **SHOULD** - A Markdown document SHOULD have exactly one root level heading, with all subsequent headings forming a hierarchical tree beneath that root heading. This structure SHOULD be maintained so that Markdown documents can be combined into a single document without requiring structural interpretation or manual restructuring.
- **SHOULD NOT** - Markdown headings SHOULD NOT use manually assigned numeric prefixes. Heading numbers SHOULD be omitted so that sections can be reordered, inserted, or combined without requiring renumbering.

### Explicitness

- **SHOULD+** - Code SHOULD favour explicitness over concision. The structure, behaviour, scope, and intent of code SHOULD be unambiguous. Ambiguity about what code does SHOULD be treated as a failure condition.


## AI Contract

- **MUST** - `ai_contract` MUST be specified when the document's AI contract is anything other than `manual`.
- **NOTE** - When `ai_contract` is absent, the document is implicitly `manual`.
- **MUST** - When specified, `ai_contract` MUST contain one or more recognised values.
- **MUST** - Multiple `ai_contract` values MUST be comma-separated.
- **MAY** - `ai_contract` values MAY appear in any order.
- **MAY** - Any combination of recognised `ai_contract` values MAY be specified.

### AI Contract Values

- **NOTE** - `manual` means no AI was used in producing the document.
- **NOTE** - `ai_assisted` means AI was used in producing the document, but was not the only author.
- **NOTE** - `ai_generated` means AI was the only author.
- **NOTE** - `manual_only` means AI MUST NOT be used to produce or modify the document.
- **NOTE** - `ai_forbidden` means AI MUST NOT read, process, or otherwise access the document.

### AI Contract Declaration

- **MUST** - When `ai_contract` is required, it MUST be declared as early in the document as practical.
- **MUST** - The `ai_contract` declaration MUST NOT interfere with the document's normal syntax or interpretation.
- **SHOULD** - `ai_contract` SHOULD be declared using pseudo front matter where the document format supports pseudo front matter.
- **SHOULD** - Where pseudo front matter is not supported, `ai_contract` SHOULD be declared using the document format's comment mechanism.
