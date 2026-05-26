---
description: 'Best practices for applying Object-Oriented Programming (OOP) design patterns, including Gang of Four (GoF) patterns and SOLID principles, to ensure clean, maintainable, and scalable code.'
applyTo: '**/*.py, **/*.java, **/*.ts, **/*.js, **/*.cs'
---

# Design Patterns for Object-Oriented Programming for Clean Code

These instructions configure GitHub Copilot to prioritize Gang of Four (GoF) Design Patterns, SOLID principles, and clean Object-Oriented Programming (OOP) practices when generating or refactoring code.

## Core Principles

- **Program to Interfaces, not Implementations:** Use abstract classes/interfaces; favor dependency injection.
- **Composition over Inheritance:** Avoid deep inheritance hierarchies; use delegation for behavior reuse.
- **Encapsulate What Varies:** Isolate aspects that change using Strategy, State, or Bridge patterns.
- **Loose Coupling:** Use Mediator, Observer, or abstract factories to decouple components.

## Creational Patterns

- **Abstract Factory:** Multiple product families with common interfaces.
- **Factory Method:** Defer object instantiation to subclasses.
- **Builder:** Complex multi-step object construction.
- **Singleton:** Only for guaranteed single instances (prefer dependency injection).
- **Prototype:** Clone existing objects instead of expensive creation.

## Structural Patterns

- **Adapter:** Make incompatible interfaces work (prefer composition).
- **Bridge:** Separate abstraction from implementation for independent variation.
- **Composite:** Represent part-whole hierarchies with uniform interfaces.
- **Decorator:** Dynamically add responsibilities without subclassing.
- **Facade:** Unified interface for complex subsystems.
- **Flyweight:** Minimize memory by sharing similar objects.
- **Proxy:** Control access via surrogates (lazy loading, access control).

## Behavioral Patterns

- **Strategy:** Encapsulate interchangeable algorithms; eliminate complex conditionals.
- **Observer:** One-to-many loose coupling with automatic notifications.
- **Command:** Encapsulate requests as objects (undo/redo, queues).
- **State:** Runtime behavior changes based on internal state.
- **Template Method:** Define algorithm skeleton in base class; defer steps to subclasses.
- **Chain of Responsibility:** Pass requests along a handler chain.
- **Mediator:** Centralize complex communication between objects.
- **Iterator:** Standard sequential access without exposing structure.
- **Visitor:** New operations on stable structures without modifying elements.
- **Memento:** Capture/restore state without violating encapsulation.

## Code Generation Rules

- **Interface First:** Generate abstract classes/interfaces before concrete implementations.
- **Encapsulation:** Make fields `private`; provide getters/setters only when needed.
- **Naming:** Use pattern names when clarifying (e.g., `TaxCalculationStrategy`); keep domain-natural otherwise.
- **Single Responsibility:** Each class has one reason to change.
- **SOLID Principles:**
  - Open/Closed: Open for extension, closed for modification.
  - Liskov Substitution: Subclasses substitute base classes without breaking correctness.
  - Interface Segregation: Specific interfaces over general-purpose ones.
  - Dependency Inversion: Depend on abstractions, not concretions.
- **Avoid God Classes:** Break complex classes into smaller, focused ones.
- **Pattern Documentation:** Explain why and how patterns are applied.
- **Testability:** Use patterns that enable unit testing (e.g., dependency injection for mocking).
- **Iterative Refactoring:** Make small, incremental changes; verify behavior with tests.
- **Performance:** Balance abstraction layers with performance; profile when necessary.
- **Consistency:** Apply patterns uniformly across the codebase.
- **Balance:** Favor simplicity and functions over over-engineered patterns.

## Logging & Error Handling

- Fail safe, loud, clear, and early; avoid silent failures.
- Use custom exceptions for meaningful error messages and granular handling.
- Avoid exception blocks for normal control flow.
- Use logging frameworks with appropriate levels (info, debug, warning, error, critical).
- Implement centralized error handling for consistency.

## Documentation

- Use English docstrings explaining purpose, parameters, and returns.
- Include comments clarifying complex logic and design decisions.
- Maintain a high-level architectural overview in README or dedicated docs.
- Use diagrams (UML) for class relationships and patterns.
- Divide docs into user documentation (usage) and developer documentation (maintenance).
- Keep docs concise, focused, and DRY—extend existing files rather than creating duplicates.
