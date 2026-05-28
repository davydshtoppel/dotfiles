---
name: create-junit-test
description: Create or refactor Java unit tests following JUnit 5, AssertJ, and Mockito conventions. Use when the user asks to "write tests for X", "create junit tests", "refactor tests in Y", or "test this class". Also use for test maintenance when the code under test has evolved — e.g. "constructor signature changed", "update tests after refactoring", "tests broke after I changed the class", "fix tests to match new API". Takes an optional class name or file path.
argument-hint: [ClassName or path]
allowed-tools: [Read, Bash, Glob, Grep, Edit, Write]
---

# Create JUnit Test

Generate or refactor Java unit tests following JUnit 5, AssertJ, Mockito, and best practices: nested organization, parameterized tests, soft assertions, and AAA (Arrange / Act / Assert) structure.

## Arguments

Parse: first token (optional) → class name (e.g. `Calculator`) or file path (e.g. `src/main/java/com/example/Calculator.java`). If absent, infer from context or ask.

## Steps

### 1. Locate the Class and Existing Test

- Find `src/main/java/**/<ClassName>.java` using `find` or `glob`
- Read the source file; extract public methods, dependencies, branch structure
- Check for existing `src/test/java/**/<ClassName>Test.java`; read if found

### 2. Detect Available Libraries

Detect build tool (`pom.xml` → Maven, `build.gradle*` → Gradle) and query dependencies:

```bash
# Maven
mvn dependency:list -q 2>/dev/null | grep -iE "junit|assertj|mockito"
# Gradle
./gradlew dependencies --configuration testRuntimeClasspath -q 2>/dev/null | grep -iE "junit|assertj|mockito"
```

Assume JUnit 5 + AssertJ + Mockito. If detection suggests JUnit 4, offer fallback (plain asserts).

### 3. Analyze Class Structure

Extract:
- **Public method signatures** — what each method takes and returns
- **Dependencies** — constructor params / fields. Mock if: external service, I/O, network, database. Real if: data class, value object, immutable DTO.
- **Distinct code paths** — each unique branch (`if`/`switch`), exception throw, null check, and happy path. Count branches, not input variants.
- **Assertion targets** — what should the test verify? Return value? Object state? Exception type & message? Side effects (void methods)?

Then map paths to test groups before writing any code: inputs that exercise the **same branch** belong in one `@ParameterizedTest`; inputs that exercise **different branches** get separate test methods. A method with one guard clause produces exactly two test groups.

### 4. Generate Test Class

Canonical example (shows all patterns naturally):

```java
package com.example;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    PaymentGateway paymentGateway;

    OrderService subject;

    @BeforeEach
    void setUp() {
        subject = new OrderService(paymentGateway);
    }

    @ParameterizedTest
    @CsvSource({ "10.0, ACCEPTED", "0.0, REJECTED" })
    void whenPaymentResult_thenOrderReflectsStatus(double amount, String status) {
        // Arrange
        when(paymentGateway.charge(amount)).thenReturn(amount > 0);

        // Act
        var order = subject.createOrder(amount);

        // Assert
        assertThat(order).returns(status, Order::status);
    }

    @Test
    void whenPaymentFails_thenThrowPaymentException() {
        // Arrange
        var amount = 100.0;
        when(paymentGateway.charge(amount)).thenReturn(false);

        // Act & Assert
        assertThatThrownBy(() -> subject.createOrder(amount))
            .isInstanceOf(PaymentFailedException.class)
            .hasMessage("Payment declined");
    }

    @Test
    void whenChargeThrowsException_thenPropagateException() {
        // Arrange
        var amount = 100.0;
        when(paymentGateway.charge(amount))
            .thenThrow(new NetworkException("Connection timeout"));

        // Act & Assert
        assertThatThrownBy(() -> subject.createOrder(amount))
            .isInstanceOf(NetworkException.class);
    }
}
```

### 5. Conventions (all embedded above)

**Test class structure:**
- One `<ClassName>Test` per class under test
- Field `subject` (no access modifier, no `final`) initialized in `@BeforeEach setUp()`
- Test methods: `when<Condition>_then<Expectation>` naming with `@DisplayName` on every test method. One test = one assertion focus = one expected outcome.
- Use `@Nested` classes only when a class has 5+ public methods or multiple test groups per method. Do not create a `@Nested` class with only one test method. `@DisplayName` is optional on `@Nested` classes with self-documenting names.

**Mocking:**
- Mock external dependencies only: database, HTTP client, message queue, file system, clock, random, external service interfaces. Do NOT mock data classes, DTOs, value objects.
- Declare with `@Mock` annotation (no modifier, no `final`)
- Add `@ExtendWith(MockitoExtension.class)` at class level
- Stub return values: `when(mock.method(arg)).thenReturn(value)` or throw exceptions: `.thenThrow(new Exception())`
- **Do NOT call `verify()` on stubbed return-value methods** — strict stubs fail automatically if unused. Use `verify()` only for void methods where invocation is the sole assertion.
- **Do NOT use `@InjectMocks`** — prefer explicit constructor injection in `@BeforeEach setUp()`. `@InjectMocks` silently bypasses constructor signature changes and hides missing dependencies.

**Assertions (AssertJ — import explicitly, no wildcards per java.md):**
- `assertThat(result).isEqualTo(expected)` — single value
- `assertThat(subject).returns(expectedValue, Subject::getField).returns(anotherValue, Subject::getOtherField)` — multiple properties of the same object; chain `.returns()` / `.extracting()` / other purpose-built methods; use `.satisfies()` only as last resort
- `assertThatThrownBy(() -> call()).isInstanceOf(X.class).hasMessage("…")` — exception type and message
- Chain multiple conditions: `assertThat(result).isNotNull().isGreaterThan(0).hasSize(3)`
- `SoftAssertions.assertSoftly(s -> { s.assertThat(a).isEqualTo(x); s.assertThat(b).isEqualTo(y); })` — multiple independent assertions on different objects, all collected before failure

**Parameterized tests:**
- Replace repeated logic with `@ParameterizedTest`
- Sources: `@CsvSource({…})`, `@MethodSource("methodName")`, `@ValueSource(strings={…})`, `@EnumSource`
- No `final` on parameters

**AAA structure (blank lines between sections):**
```
// Arrange: set up test data, stubs, initial state
// Act: call the method under test
// Assert: verify result and side effects
```
- **Input variables:** In non-parameterized tests, assign each input value to a named `var` in the Arrange section (e.g. `var amount = 100.0;`). Reference that variable in both stub setup and the act call — never repeat the same literal twice in one test. Name the variable after its semantic role, not its type. (Parameterized tests already have named parameters, so this rule doesn't apply there.)

**Branch coverage:**
- One assertion focus per test method (one test verifies one expected outcome)
- Test behaviour, not implementation — test what the method does (happy path, edge cases, errors), not how it does it
- Cover each distinct code path **exactly once**. A method with one guard clause needs exactly two test groups (pass / fail), not one test per failing input value. Edge cases (null, zero, negative, empty) that all trigger the same branch belong in `@CsvSource` rows of a single `@ParameterizedTest`, not in separate test methods.
- **Do not multiply tests across input values.** The signal for consolidation: two method names that differ only by the input description (e.g. `whenNull_thenThrows` vs. `whenEmpty_thenThrows`) — that's one `@ParameterizedTest`, not two methods.
- Never use `if` or loops in test code — use `@ParameterizedTest` instead to test multiple inputs

**Test data:**
- Simple values (primitives, strings): construct inline (`new Order("123", 100.0)`)
- Complex objects: create a `<ClassName>TestFixtures` or `<ClassName>Mother` class (package-private in same test directory) with static builder methods. Example: `OrderTestFixtures.anOrder().withStatus(SHIPPED).withCustomer("Alice").build()`
- If builder doesn't exist: generate it with fluent builder pattern (private constructor, withX() methods, build() returns instance)
- Always create fresh instances per test — never share mutable state between tests

**Fields:**
- Test fields (instance and static): no access modifier, no `final` (exception to java.md)
- Parameterized parameters: no `final`

### 6. Write to File

- Edit existing `<ClassName>Test.java` or Write to `src/test/java/<package>/<ClassName>Test.java`
- Verify imports, syntax, method coverage

## Edge Cases

- **No public methods:** Suggest integration tests or testing via internal usage
- **Constructor exceptions:** Separate test method for exception path
- **Static methods only:** Test via static import or class reference (no subject)
- **Inner classes:** Test via public inner class constructor or enclosing class reference
- **Missing libraries:** Suggest adding JUnit 5, AssertJ, Mockito to build config
- **Kotlin:** Adapt syntax (data classes, extension functions) but follow same conventions
- **Existing non-conforming tests:** Refactor incrementally; explain each change