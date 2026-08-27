# 01-doctrine_format
---
ai_contract: ai_assisted
content_version: 2026-08-26.3
--- 

## Document Structure

- **SHOULD+** - A doctrine name SHOULD have a prefix when doctrine sequencing is significant.
- **SHOULD+** - A doctrine document SHOULD contain exactly one first-level heading naming the doctrine.
- **SHOULD+** - A doctrine document filename SHOULD consist of the doctrine name followed by the corresponding dotted file-format suffix.
- **SHOULD** - All subsequent headings SHOULD form a hierarchical tree beneath the root level heading.
- **SHOULD+** - Heading numbers SHOULD NOT be used.
- **SHOULD+** - Headings SHOULD remain independently reorderable without requiring renumbering.


## Doctrine Elements

- **MUST** - Each normative doctrine element MUST be represented as an individual Markdown list item.
- **MUST** - Each normative doctrine element MUST begin with its normative level in bold Markdown.
- **SHOULD** - The normative level SHOULD be followed by `-` and then the normative statement.
- **SHOULD** - Each doctrine element SHOULD express one coherent rule.
- **SHOULD** - Supporting explanation SHOULD be kept separate from the normative statement where practical.

## Normative Levels

Doctrine elements are ordered from strongest to weakest as follows:

1. `MUST NOT`
2. `MUST`
3. `SHOULD NOT+`
4. `SHOULD+`
5. `SHOULD NOT`
6. `SHOULD`
7. `MAY`
8. `NOTE`

- **MUST** - `MUST` denotes an absolute requirement.
- **MUST NOT** - `MUST NOT` denotes an absolute prohibition.
- **SHOULD+** - `SHOULD+` denotes the prescribed requirement. Deviation requires a documented exception decision.
- **SHOULD NOT+** - `SHOULD NOT+` denotes the prescribed prohibition. Deviation requires a documented exception decision.
- **SHOULD** - `SHOULD` denotes the prescribed default. Deviation is permitted through engineering judgement.
- **SHOULD NOT** - `SHOULD NOT` denotes the prescribed default prohibition. Deviation is permitted through engineering judgement.
- **MAY** - `MAY` denotes something that is explicitly permitted but optional.
- **NOTE** - `NOTE` provides information, rationale, reminders, or guidance relevant to the heading under which it appears. A `NOTE` does not itself impose a normative requirement.

## Normative Ordering

- **SHOULD** - Doctrine elements SHOULD be ordered by normative level from strongest to weakest within each section.
- **SHOULD** - The ordering SHOULD follow `MUST NOT`, `MUST`, `SHOULD NOT+`, `SHOULD+`, `SHOULD NOT`, `SHOULD`, `MAY`, then `NOTE`.
- **SHOULD** - Elements with the same normative level SHOULD be grouped together where practical.
- **SHOULD** - `NOTE` elements SHOULD follow the normative elements to which they relate.
- **SHOULD** - A `NOTE` that applies only to a single normative element SHOULD be indented beneath that element.
- **SHOULD** - A `NOTE` that applies to multiple normative elements SHOULD be positioned after those elements without indentation.


## Purpose

- **SHOULD** - Doctrine documents SHOULD provide a consistent, composable format for expressing rules and their supporting context.
- **SHOULD+** - Doctrine documents SHOULD be independently composable into larger documents without requiring structural interpretation or manual restructuring.
- **NOTE** - Doctrines are primarily to define acceptable AI behaviour, but are also written for human use.

## Pseudo Front Matter

- **MUST** - Pseudo front matter MUST immediately follow the heading to which it applies.
- **SHOULD+** - Document metadata concerning revision, inheritance, provenance, and other document-level properties SHOULD be represented using pseudo front matter.
- **SHOULD+** - Pseudo front matter SHOULD use YAML front matter syntax with the use of tabs for indentation as a mandatory deviation.
- **MUST** - Pseudo front matter MUST permit tab characters for indentation, including indentation of lists.
- **MAY** - Pseudo front matter MAY occur after headings other than the root level heading where metadata associated with that heading is useful.
- **SHOULD** - A document SHOULD use pseudo front matter only where document or section metadata is required.

### Document Metadata

- **SHOULD+** - The document revision MUST be represented by the `content_version` key in the pseudo front matter.
- **SHOULD+** - `content_version` SHOULD use the non-functional document version format defined by the Root Coding Doctrine.
- **SHOULD** - A document SHOULD restart its daily revision sequence at `1` when the revision date changes.

### Inheritance

- **SHOULD+** - Doctrine inheritance SHOULD be declared explicitly in pseudo front matter using the `inherits` key.
- **SHOULD** - A doctrine SHOULD inherit from a single doctrine where practical.
- **MAY** - A doctrine MAY inherit from multiple doctrines where required.
- **MUST** - When multiple doctrines are inherited, the inheritance list MUST be ordered from least specific to most specific.
- **SHOULD** - Later inherited doctrines SHOULD override earlier inherited doctrines where their rules conflict.

For example:

```yaml
---
content_version: 2026-08-26.1
inherits:
  - root_doctrine
  - perl_doctrine
---
```

The resulting order of specificity is:

```text
root_doctrine -> perl_doctrine -> project_doctrine
```


## Sections

- **SHOULD** - Sections SHOULD group related doctrine elements by subject matter.
- **SHOULD** - A section SHOULD contain doctrine elements with a coherent subject rather than exist solely to create additional heading depth.
- **SHOULD** - A `NOTE` SHOULD relate to the heading under which it appears.

## Exceptions

- **MUST** - A documented exception to a `SHOULD+` or `SHOULD NOT+` rule MUST identify the rule being excepted and the reason for the exception.
- **SHOULD** - An exception decision SHOULD be recorded close to the code or document to which it applies.
- **SHOULD** - An exception SHOULD describe the decision sufficiently for the reason to remain understandable after the original decision-maker is no longer involved.

## Composition

- **SHOULD+** - A conforming doctrine document SHOULD be independently composable with other conforming doctrine documents.
- **SHOULD+** - Concatenating conforming doctrine documents SHOULD NOT require manual heading renumbering.
- **SHOULD+** - Each root level heading and its associated pseudo front matter SHOULD remain a self-contained document unit when documents are concatenated.
- **SHOULD** - Concatenated doctrine documents SHOULD retain their individual inheritance and revision metadata.
- **MUST** - Pseudo front matter MUST remain associated with the heading immediately preceding it when a document is concatenated with another document.

## Versioning

- **SHOULD+** - Non-functional documents SHOULD use an ISO 8601 date followed by a dot and a revision number for that date.
- **SHOULD+** - Code versions SHOULD use three numeric components in the form `BREAKING.FEATURE.FIX`.
- **SHOULD** - The document revision date SHOULD identify the date on which that revision was produced.
- **SHOULD** - The daily document revision number SHOULD begin at `1` and increment for subsequent revisions on the same date.
 
