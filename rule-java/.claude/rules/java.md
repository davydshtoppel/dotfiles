---
description: Java rules: pragmatic design, reuse, boundary validation, Checkstyle style, JSpecify, JDK 25 idioms
paths:
  - "**/*.java"
---

# Java Rules

Existing project conventions win. Don't reformat code you didn't touch.

## Design
- Solve the task at hand; no abstractions for requirements that aren't in it.
- Idioms over GoF patterns: records, enums, sealed types, lambdas and framework features first. Use a pattern only with ≥2 real variants today. Name types after the domain, not the pattern.
- Don't reinvent: before writing a helper, look for one in the project and its existing dependencies (JDK, Spring, Guava, Commons, …). Don't add a dependency for a one-liner.
- Collaborators (services, repositories, clients) go behind interfaces as test seams; one implementation is fine.
- Composition over inheritance; constructor injection; no static mutable state.
- Allow duplication until the third occurrence; a wrong abstraction costs more.

## Validation & Errors
- Validate input once, where it enters the system (endpoint, consumer, loader). Inside, trust the contract and JSpecify: no defensive checks per method.
- Never swallow exceptions; wrap with the cause attached. Don't log and rethrow. No exceptions for control flow.
- `Optional` only as a return type.

## Style
- Naming: `UpperCamelCase` types, `lowerCamelCase` members, `UPPER_SNAKE_CASE` constants, lowercase packages.
- Imports: third-party, `javax.*`, `java.*`, static; alphabetical, groups separated by a blank line; no wildcard or `import module`.
- Formatting: 4-space indent, 100-char lines, braces always, opening brace on the same line.
- Package-private by default. `final` on classes (unless designed for extension), parameters and fields.
- JSpecify: `@NullMarked` per package or class; mark nullable types `@Nullable`.

## JDK 25 Idioms (final features only, no preview)
- Records; sealed interfaces + records for closed hierarchies.
- Switch expressions with type/record patterns and `when` guards. Leave out `default` on sealed switches so the compiler checks exhaustiveness.
- `instanceof` bindings, `_` for unused variables, `var` when the type is obvious.
- `List.of`/`Map.of`, `getFirst()`/`getLast()`/`reversed()`, `Stream.toList()`, text blocks, `formatted()`.
- Statements before `super(…)` instead of static helper methods.
- Virtual threads for blocking I/O; `ScopedValue` instead of `ThreadLocal`.
