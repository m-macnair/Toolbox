# openscad
---
content_version: 2026-08-26.1
ai_contract: ai_assisted
inherits:
	- root_doctrine
---

## Purpose

- **NOTE** - This doctrine defines practical OpenSCAD conventions for reusable 3D and 2.5D project development.

## Libraries

- **SHOULD+** - BOSL2 SHOULD be used.

## Versioning

- **SHOULD+** - A `.scad` file SHOULD contain a version variable corresponding to its filename.
- **NOTE** - The version variable SHOULD use the filename without the `.scad` extension, followed by `_version`.
- **NOTE** - The version value SHOULD use a `v` prefix and a three-component numeric version.

For example, `dunblane_mounting_strip.scad`:

```scad
$dunblane_mounting_strip_version = "v7.1.0";
```

## Formatting

- **SHOULD** - `.scad` files SHOULD be structured to use `clang-format`.
- **NOTE** - Include blocks require `//clang-format off` immediately before the block and `//clang-format on` immediately after it.

For example:

```scad
//clang-format off
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
//clang-format on
```

## Reusable Components

- **SHOULD+** - "Module Files" SHOULD be written as first-class reusable components, and development SHOULD prioritise work within them.
- **SHOULD+** - "Script Files" SHOULD be written primarily as calling Module Files.
- **NOTE** - A reusable module SHOULD provide the component definition, while an associated script SHOULD compose and invoke the component for a particular generated result.

## Functions

- **SHOULD** - Functions SHOULD be named `get_<some_value>`.

## Script Structure

- **SHOULD** - Scripts SHOULD declare the variables that affect the structure being generated at the top of the file.
- **SHOULD** - The variables that affect the generated structure SHOULD appear under a `/* main variables */` heading.
- **SHOULD** - Derived variables SHOULD appear in the next section under a `/* derived */` heading.
	- **MAY** - Derived variables MAY use functions to establish their values.
- **SHOULD** - Subheadings SHOULD be used where they improve the organisation of the script.
- **SHOULD** - Functions SHOULD be used to establish derived variable values where doing so improves clarity or reuse.

## Colours

- **SHOULD** - `RGBCMY` SHOULD be the canonical colour vocabulary for OpenSCAD projects.
- **NOTE** - `R`, `G`, `B`, `C`, `M`, and `Y` are the canonical text identifiers corresponding respectively to red, green, blue, cyan, magenta, and yellow.
- **NOTE** - The canonical OpenSCAD `color("string")` values corresponding to `RGBCMY` are:
	- `R` -> `color("red")`
	- `G` -> `color("green")`
	- `B` -> `color("blue")`
	- `C` -> `color("cyan")`
	- `M` -> `color("magenta")`
	- `Y` -> `color("yellow")`

### Cubic 3D

- **NOTE** - For a cubic 3D shape, the `RGBCMY` colours represent:
	- `R` -> `Y+`
	- `G` -> `X+`
	- `B` -> `Y-`
	- `C` -> `X-`
	- `M` -> `Z+`
	- `Y` -> `Z-`

### 2.5D

- **NOTE** - 2.5D means shapes composed of 2D objects stacked above or in front of each other.
- **SHOULD** - For 2.5D shapes, the `RGBCMY` sequence SHOULD proceed from `R` at the bottom through `Y` at the top.

The sequence is:

```text
R
G
B
C
M
Y
```

### Three-Part 2.5D Projects

- **NOTE** - For three-part 2.5D projects, the `RGB` convention represents the bottom frame, mounting, and contents being mounted respectively.
- **NOTE** - `R` represents the bottom frame.
- **NOTE** - `G` represents the mounting.
- **NOTE** - `B` represents the contents being mounted.
- **NOTE** - `C` represents the combination of the `G` and `B` layers.
- **NOTE** - `M` represents the `R`, `G`, and `B` layers arranged so that they can be laser cut from a single sheet.
- **NOTE** - `C` and `M` are derived fabrication representations rather than additional physical layers in the normal 2.5D stack.
