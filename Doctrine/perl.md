# perl_development_doctrine
---
content_version: 2026-08-26.1
ai_contract: ai_assisted
inherits:
	- root_doctrine
---

## Scope

- **NOTE** - This doctrine defines the coding practices for Perl development.
- **NOTE** - This doctrine inherits the Root Coding Doctrine. Root-level rules apply unless explicitly refined by this doctrine.
- **NOTE** - Because the Root Coding Doctrine inherits `doctrine_format`, this doctrine also inherits `doctrine_format` through the doctrine hierarchy.

## Language Baseline

- **SHOULD+** - Perl code SHOULD enable `strict` and `warnings`.
	- **NOTE** - This requirement is satisfied when `strict` and `warnings` are enabled by an imported module or framework.
- **SHOULD** - Subroutines SHOULD use traditional `@_` argument handling rather than Perl subroutine signatures.

## Formatting

- **SHOULD+** - Perl code SHOULD be formatted using Perl::Tidy.
- **NOTE** - The established Perl::Tidy configuration defines the expected Perl formatting style.
- **MAY** - Perl::Tidy MAY be overridden when its output breaks the code.
- **MAY** - Line length is unrestricted.

## Naming

- **SHOULD** - Package names SHOULD use UpperCamelCase.
- **SHOULD** - script names SHOULD use lower_snake_case.
- **SHOULD** - Module naming SHOULD generally follow conventions established by Moo and the surrounding Perl ecosystem.

## Variables and Scope

- **SHOULD+** - A lexical variable SHOULD NOT be declared more than once within the same scope.
- **SHOULD NOT** - Lexical variables SHOULD NOT be shadowed within an intentionally nested `CODEBLOCK:{}` scope.
- **SHOULD** - Variables SHOULD be declared and initialised together.
- **MAY** - Variables MAY be declared at first use.
- **MAY** - Explicit assignment of `undef` MAY be used.
- **NOTE** - No additional doctrine governs `our`.

## Code Blocks

- **SHOULD+** - Explicit `CODEBLOCK:{}` blocks SHOULD be used as structural and scoping tools where appropriate.
- **SHOULD** - Code blocks SHOULD be self-contained where practical.
- **SHOULD** - Scope boundaries SHOULD be visually explicit and intentional.

## Subroutines

- **SHOULD+** - A subroutine SHOULD return one value.
- **SHOULD** - Subroutines SHOULD use an explicit `return` statement.
- **SHOULD** - `return undef` SHOULD be used as the explicit convention for returning an undefined value.
- **SHOULD** - `wantarray` SHOULD be used where distinct scalar, list, or void behaviour is appropriate.
- **SHOULD** - Complex values SHOULD be passed into and out of subroutines by reference.
- **SHOULD** - A subroutine requiring more than five distinct values SHOULD accept a hash reference containing the arguments instead of individual positional arguments.
- **SHOULD** - Argument validation SHOULD be performed where appropriate.
- **MAY** - Subroutines MAY freely modify array and hash references passed to them.
- **NOTE** - When multiple pieces of information must be returned, they SHOULD be contained within a single array reference or hash reference.
- **NOTE** - Hash reference arguments SHOULD be structured so that required values can be validated efficiently.

## Higher Order Functions

- **SHOULD+** - Higher order functions that invoke a supplied subroutine SHOULD treat a true return value as the continuation signal.
- **NOTE** - For example, a CSV processing callback returning true indicates that processing SHOULD continue to the next row.

## Control Flow

- **SHOULD** - `for` SHOULD be preferred over `foreach`.
- **SHOULD** - Ternary expressions SHOULD be preferred where they improve clarity.
- **MAY** - `unless` MAY be used freely.
- **MAY** - Postfix conditionals MAY be used freely.
- **MAY** - `map`, `grep`, and `sort` MAY be used freely in all contexts.

## Definedness and Truthiness

- **MUST NOT** - `||` MUST NOT be used merely as an alternative spelling of an undefined check where false values such as `0`, `""`, or `"0"` are valid values.
- **SHOULD+** - `//` and `//=` SHOULD be used when the intended distinction is between `undef` and defined values.
- **SHOULD+** - `||` and `||=` SHOULD be used when the intended distinction is between truthy and false values.

## GOTO

- **SHOULD+** - `goto LABEL` MAY be used for explicit local control flow where appropriate.
- **SHOULD+** - `goto LABEL` SHOULD target a label within the enclosing `CODEBLOCK:{}`.
- **SHOULD+** - Labels used as `goto` targets SHOULD describe the purpose of the control-flow destination.

## Perl Special Mechanisms

- **MAY** - `AUTOLOAD` MAY be used freely.
- **MAY** - `DESTROY` MAY be used freely.
- **MAY** - `BEGIN` MAY be used freely.
- **MAY** - `CHECK` MAY be used freely.
- **MAY** - `INIT` MAY be used freely.
- **MAY** - `END` MAY be used freely.
- **NOTE** - `CHECK` and `INIT` are Perl execution-phase mechanisms worth remembering when compile-time or pre-runtime hooks are appropriate.
- **NOTE** - No additional doctrine governs `state`, `local`, `tie`, or operator overloading.

## Object Orientation

- **SHOULD** - Moo SHOULD be preferred for object-oriented Perl.
- **SHOULD NOT** - Direct use of blessed references SHOULD generally be avoided.
- **MAY** - Moose MAY be used when Moo is not suitable.
- **NOTE** - `Moo/se` is the shorthand for referring to Moo and Moose interchangeably.

### Composition

- **SHOULD NOT** - Classes SHOULD NOT accumulate behaviour that could reasonably be expressed as a reusable role.
- **SHOULD** - Roles SHOULD be preferred as reusable capabilities.
- **SHOULD** - Classes SHOULD represent useful combinations of roles for a specific purpose.
- **SHOULD** - New reusable behaviour SHOULD generally be expressed as a role.
- **SHOULD** - Classes SHOULD generally not inherit from other classes within the same project.
- **MAY** - Foreign classes MAY be inherited and modified where appropriate.

### Attributes

- **SHOULD** - Moo/se attributes SHOULD be accessed through their accessors rather than through the underlying object hash.
- **MAY** - Moo/se attributes MAY use `ro` or `rw` according to the requirements of the object.
- **SHOULD** - Lazy attributes SHOULD generally be preferred where appropriate.
- **SHOULD** - Lazy attributes SHOULD use Moo/se's conventional `_build_<attribute>` builder method without an explicit `builder` declaration where the conventional builder is sufficient.
- **NOTE** - `$self->value` SHOULD be preferred over `$self->{value}`.

For example:

```perl
has value => (
	is => 'lazy',
);

sub _build_value {
	return calculate_value();
}
```

### Moo/se Module Structure

- **SHOULD+** - Moo/se classes SHOULD contain only constructors, accessors, and subroutines.

## SQL

- **SHOULD+** - SQL statements SHOULD use placeholders for values rather than interpolating values directly into SQL.
- **SHOULD+** - Project-specific SQL and database abstractions SHOULD be used where they exist and are appropriate.
- **SHOULD** - Placeholder lists SHOULD be visually separated into groups of four.
- **SHOULD** - SQL SHOULD be preferred over an abstraction layer when SQL directly and appropriately solves the problem.
- **SHOULD** - SQL strings SHOULD use `q{}` or `qq{}` quoting where appropriate.
- **SHOULD** - SQL SHOULD favour explicit and overbuilt structure where that improves clarity.
- **NOTE** - Advanced SQL SHOULD generally be handled by project-specific code.

For example:

```text
?,?,?,?
?,?
```

## File I/O

- **SHOULD** - Three-argument `open` SHOULD be the default form of `open`.
- **SHOULD** - Buffering and flushing behaviour SHOULD be explicit when processing data in loops.
- **SHOULD** - Processing loops SHOULD use an explicit counter or other governing variable when determining buffering and flushing behaviour.
- **NOTE** - Encoding is intentionally undefined by this doctrine.

## Error Handling

- **SHOULD+** - `try {}` and `catch {}` SHOULD be the default structured exception-handling mechanism.
- **SHOULD+** - `warn` and `die` SHOULD be the default mechanisms for warnings and fatal errors.
- **SHOULD** - Explicit error handling with `die` SHOULD be preferred where an operation can fail and that failure requires handling.
- **MAY** - `confess` and `cluck` MAY be used where stack information is useful.
- **MAY** - `autodie` MAY be used, but is discouraged.
- **NOTE** - Error handling is intentionally open-ended.

## Regular Expressions

- **MAY** - Regular expressions MAY be used without artificial restrictions.

## Modules and Packages

- **SHOULD+** - Each `.pm` file SHOULD contain one package.
- **SHOULD** - A `.pl` file SHOULD contain multiple packages when those packages exist specifically to compose functionality used only by that script.
- **MAY** - CPAN modules MAY be introduced freely where they provide useful functionality.
- **SHOULD** - Useful CPAN modules SHOULD be welcomed rather than avoided for the sake of minimising dependencies.
- **NOTE** - Packages in a `.pl` file SHOULD be structured so they can be cleanly transferred into their own `.pm` file when their reuse justifies extraction.

## Comments and Documentation

- **SHOULD** - Comments SHOULD prefer explaining why code exists or why it takes a particular approach.
- **SHOULD** - Code SHOULD communicate what it does through its structure where practical.
- **SHOULD** - Explicit helper subroutines SHOULD be preferred where they make setup or intent clearer.
- **MAY** - Comments MAY explain what code does where doing so improves comprehension.
- **MAY** - `TODO` and `FIXME` comments MAY be used and are encouraged where appropriate.

### POD

- **NOTE** - A proper POD doctrine has not yet been established. This SHOULD be revisited and formally decided.

## Testing

- **NOTE** - Testing is intentionally open-ended.
- **NOTE** - No general testing methodology, framework, coverage target, or test structure is mandated by this doctrine.

## Undefined Areas

- **NOTE** - The following areas have no additional Perl doctrine unless subsequently established:
	- Perl version
	- Encoding
	- Testing methodology
	- `state`
	- `local`
	- `tie`
	- Operator overloading
	- POD conventions
