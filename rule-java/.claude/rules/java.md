---
description: Java style: Sun Checkstyle naming/formatting, JSpecify nullability, JDK 21 idioms
paths:
  - "**/*.java"
---

# Java Style Rules

Apply these conventions when writing or refactoring Java code.

## Naming
- Types (classes, interfaces, enums, records, annotations): `UpperCamelCase`
- Methods and variables: `lowerCamelCase`
- Constants (`static final`): `UPPER_SNAKE_CASE`
- Packages: all lowercase, no underscores

## Imports
- No wildcard imports
- Regular imports before static imports; alphabetical within each group

## Formatting
- Opening brace on same line; always use braces for `if`/`for`/`while`/`do`
- Max 100 characters per line; one statement per line

## Nullability (JSpecify)
- Apply `@NullMarked` at package level (`package-info.java`) or class level; all unannotated reference types are then non-null by default
- Annotate nullable fields and parameters explicitly with `@Nullable`

## Final Keyword
- Declare classes `final` unless explicitly designed for extension (abstract classes are exempt)
- Declare method parameters `final`
- Declare instance and static fields `final` where possible

## JDK 21 Idioms
- Prefer switch expressions (`case X -> value`) over switch statements
- Use `var` when the type is obvious from the initializer (`var map = new HashMap<String, Integer>()`)
- Use records for simple immutable data carriers
- Use sealed classes/interfaces for closed type hierarchies
- Use pattern matching (`if (obj instanceof Foo f)`) instead of cast-after-instanceof
- Use text blocks for multi-line string literals
