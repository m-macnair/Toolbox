# Python Development Doctrine
---
content_version: 2026-08-26.1
ai_contract: ai_assisted
inherits:
	- root_doctrine
---

## Purpose

- **NOTE** - The guiding principle is: Keep Python readable, modular, explicit, and unsurprising.
- **NOTE** - These conventions are intended for both human development and AI-assisted coding. They should be followed by default unless a specific reason requires an exception.
- **NOTE** - This doctrine inherits `root_doctrine`. Through that inheritance, it also inherits `doctrine_format`.

## Indentation

- **MUST** - Python code MUST use tabs for indentation.
- **MUST NOT** - Tabs and spaces MUST NOT be mixed for indentation.

For example:

```python
def example():
	if condition:
		do_something()
```

## Project Modules

- **SHOULD** - Modules belonging to the project SHOULD use the `PM_` alias convention.
- **SHOULD** - Methods SHOULD be accessed through the project module alias.

For example:

```python
import rass_blender.blender_headless as PM_bh
import rass_blender.blender_operations as PM_bo

PM_bh.import_stl(filename)
PM_bo.apply_operation(obj, operation)
```

## External Modules

- **SHOULD** - Modules supplied externally SHOULD use the `EM_` alias convention.
- **SHOULD** - An external module SHOULD only be imported directly when there is a specific reason not to place the required functionality behind a project module.
- **MUST** - The reason for directly importing an external module MUST be documented immediately before the import.

For example:

```python
# CSV is a generic interchange format and requires no project abstraction.
import csv as EM_csv
```

- **NOTE** - External module methods SHOULD then be accessed through the `EM_` alias.

For example:

```python
reader = EM_csv.reader(csvfile)
```

- **NOTE** - `EM_` explicitly marks an intentional boundary between project-owned and externally supplied code.
- **SHOULD NOT** - `EM_` SHOULD NOT be used merely as an alternative naming style.

## Individual Method Imports

- **SHOULD** - The default SHOULD be to import a project module and access its methods through the `PM_` alias.
- **SHOULD NOT** - Individual methods SHOULD NOT normally be imported from a `PM_` module.
- **MUST** - If there is a specific reason to import one or more methods directly, the reason MUST be documented immediately before the import.
- **NOTE** - The comment should explain why the normal module-alias convention is being broken, rather than merely describing what is being imported.

For example:

```python
# These functions form the small public API required by this module;
# direct imports make their repeated use clearer.
from rass_blender.foo import bar, baz
```

## Module Responsibilities

- **SHOULD** - Where practical, lower-level or implementation-specific functionality SHOULD be moved into its own project module.
- **SHOULD** - Calls to external libraries and APIs SHOULD be isolated behind project modules.
- **NOTE** - For example:

```text
csv_scene.py
	↓
blender_operations.py
	↓
blender_headless.py
	↓
bpy
```

- **NOTE** - Higher-level operational code should not need to know the details of an underlying API where those details can be isolated.

## Keep It Pragmatic

- **SHOULD** - Simple modules SHOULD be preferred.
- **SHOULD** - Straightforward functions SHOULD be preferred.
- **SHOULD** - Explicit dependencies SHOULD be preferred.
- **SHOULD** - Clear module boundaries SHOULD be preferred.
- **SHOULD** - Readable control flow SHOULD be preferred.
- **SHOULD NOT** - Unnecessary abstraction or cleverness SHOULD be avoided.
- **SHOULD** - Python SHOULD be used pragmatically rather than forcing the code to conform to Python idioms for their own sake.
- **NOTE** - The objective is maintainable, readable code.

## Exceptions Must Be Deliberate

- **SHOULD** - When an exception is appropriate, the exception SHOULD be made explicit.
- **SHOULD** - The reason for an exception SHOULD be documented immediately before the relevant import or construct.
- **SHOULD** - An exception SHOULD be kept as narrow as practical.
- **NOTE** - The code should make it possible for a future developer - human or AI - to understand not only what was done, but why the normal convention was not followed.
