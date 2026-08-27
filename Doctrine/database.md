# Database Doctrine
---
content_version: 2026-08-26.1
ai_contract: ai_assisted
inherits:
	- root_doctrine
---

## Purpose

- **NOTE** - This doctrine provides a small set of sensible defaults for SQL and database usage.
- **NOTE** - Application code SHOULD generally contain programming logic, with the database primarily serving as a data store.

## Naming

- **SHOULD** - SQL identifiers SHOULD use `snake_case`.
- **SHOULD** - Table names SHOULD use the singular form of the entity name.
- **SHOULD** - Possessive relationships SHOULD combine the singular table names with `_`.
- **SHOULD** - Intermediate relationship tables SHOULD use `_to_` to explicitly represent the relationship.

For example:

```text
project
asset
project_asset
inventory
project_asset_to_inventory
```

## Values

- **SHOULD+** - SQL statements SHOULD use placeholders for values rather than interpolating values directly into SQL.

## Formatting

- **SHOULD+** - SQL SHOULD use an overbuilt, vertically structured format that makes the logical components of a statement visually explicit.
- **SHOULD+** - SQL field and value lists SHOULD contain no more than four fields or values per line.
- **SHOULD** - Lists SHOULD continue on subsequent lines when they exceed four fields or values.
- **SHOULD** - Major SQL clauses SHOULD begin on separate lines.
- **SHOULD** - Lists of selected columns, tables, conditions, and similar expressions SHOULD be formatted to remain visually distinct and easy to scan.

For example:

```sql
SELECT
	a, b, c, d,
	e, f, g, h
FROM
	project
WHERE
	a = ?
	AND b = ?
	AND c = ?
	AND d = ?
```

## Application and Database Responsibilities

- **SHOULD** - Business logic SHOULD generally remain in application code rather than being moved into the database.
- **SHOULD** - The database SHOULD generally be used as a data store rather than as the primary programming environment.
