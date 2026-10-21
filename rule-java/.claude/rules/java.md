---
description: Java rules: pragmatic design, reuse, boundary validation, style, JSpecify, JDK 25 idioms
paths:
  - "**/*.java"
---

# Java Rules

Project conventions override these rules. Do not reformat code that you do not change.

## Design
- Build only what the task needs. Add no abstraction for a future requirement.
- Use language idioms first: records, enums, sealed types, lambdas, framework features.
- Use a GoF pattern only when ≥2 variants exist now. Name the type after the domain, not the pattern.
- Before you write a helper, search the project and its dependencies (JDK, Spring, Guava, Commons).
- Add no dependency for a one-line helper.
- Put collaborators (services, repositories, clients) behind an interface. One implementation is correct: the interface is a test seam, not a pattern.
- Use composition, not inheritance.
- Use constructor injection.
- Keep no static mutable state.
- Extract shared code at the third copy, not before.

## Validation and errors
- Validate input once, at the entry point (endpoint, consumer, file loader).
- Inside the system, do not repeat null or argument checks. JSpecify annotations are the contract.
- Do not catch an exception without handling it. Wrap it with the cause.
- Log an exception once, where you handle it. Do not log and rethrow.
- Do not use exceptions for control flow.
- Use `Optional` only as a return type.
- Log with SLF4J placeholders, not string concatenation.

## Style
- Import order: third-party, `javax.*`, `java.*`, static. Sort each group alphabetically. Put a blank line between groups.
- Do not use wildcard imports or `import module`.
- Indent 4 spaces. Max line length 100. Always use braces. Put the opening brace on the same line.
- Use package-private visibility by default.
- Make fields and parameters `final`. Make classes `final` unless they are designed for extension.
- Put `@NullMarked` on the package (`package-info.java`) or class. Mark each nullable type `@Nullable`.

## JDK 25 idioms
Use final features only. Do not use preview features.

| Use | Instead of |
|---|---|
| record | class with fields, getters, `equals`/`hashCode` |
| sealed interface + records | open hierarchy for a closed set of types |
| switch expression with type/record patterns and `when` | `if`/`instanceof` chains |
| no `default` in a switch over a sealed type | `default` that hides a missing case |
| `instanceof` binding | cast after `instanceof` |
| `_` | name for an unused variable |
| `var` when the right side shows the type | repeated type name |
| `List.of`, `Map.of`, `Stream.toList()` | `Arrays.asList`, `Collections.unmodifiable*`, `collect(Collectors.toList())` |
| `getFirst()`, `getLast()`, `reversed()` | `get(0)`, `get(size() - 1)`, manual reverse |
| text block, `formatted()` | string concatenation, `String.format` |
| statements before `super(…)` | static helper for constructor arguments |
| virtual threads for blocking I/O | platform thread pools |
| `ScopedValue` | `ThreadLocal` |
