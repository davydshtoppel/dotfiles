---
mode: 'agent'
description: 'Create or refactor Java unit tests following JUnit 5, AssertJ, and Mockito conventions. Provide an optional class name or file path; generates tests with @Nested organization, parameterized tests, soft assertions, and AAA structure.'
tools: ['codebase', 'terminal']
---

# Create JUnit Test

Generate or refactor Java unit tests using JUnit 5, AssertJ, Mockito: nested organization, parameterized tests, soft assertions, AAA (Arrange / Act / Assert).

## Arguments

- First (optional): class name (e.g. `Calculator`) or file path

If absent, infer from context or ask.

## Workflow

### 1. Locate Class and Existing Test

Find `src/main/java/**/<ClassName>.java` and read it. Extract public methods, dependencies, branches. Check for existing `src/test/java/**/<ClassName>Test.java`.

### 2. Detect Libraries

```bash
grep -rE "junit.jupiter|junit.api|junit.engine|assertj|mockito" pom.xml build.gradle* 2>/dev/null | sort -u | head -10
```

Assume JUnit 5 + AssertJ + Mockito; fallback to JUnit 4 asserts if needed.

### 3. Analyze Structure

- Public method signatures and returns
- Dependencies: mock if external service/I/O/database/network; real if data class / DTO / value object
- All paths: happy path, edges (empty, null, boundary, zero), errors, all branches (`if`, `switch`), exception throws
- Assertion targets: return value? state change? exception? void side effects?

### 4. Generate Test Class

Canonical example:

```java
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
        when(paymentGateway.charge(100.0)).thenReturn(false);

        // Act & Assert
        assertThatThrownBy(() -> subject.createOrder(100.0))
            .isInstanceOf(PaymentFailedException.class)
            .hasMessage("Payment declined");
    }

    @Test
    void whenChargeThrowsException_thenPropagateException() {
        // Arrange
        when(paymentGateway.charge(100.0))
            .thenThrow(new NetworkException("Connection timeout"));

        // Act & Assert
        assertThatThrownBy(() -> subject.createOrder(100.0))
            .isInstanceOf(NetworkException.class);
    }
}
```

### 5. Key Conventions

- Test class: `<ClassName>Test` (add `@ExtendWith(MockitoExtension.class)` only if using mocks)
- Field `subject` (no modifier, no `final`) → initialized in `@BeforeEach`
- Test methods: `when<Condition>_then<Expectation>` (one test = one assertion focus); @DisplayName optional if method name is clear
- Use `@Nested` only when 5+ public methods or multiple test groups per method — one `@Nested` class per public method, `@DisplayName("methodName()")` on each. Example: `@Nested @DisplayName("divide()") class Divide { @Test void whenDivisorIsZero_thenThrows() {...} }`
- **Mocking:** mock external services/I/O/database; never mock data classes/DTOs. Declare with `@Mock` (no modifier, no `final`); `@ExtendWith(MockitoExtension.class)` at class; stub with `when(mock.method()).thenReturn(value)` or `.thenThrow(…)`; do NOT `verify()` on stubs (strict stubs fail if unused); do NOT use `@InjectMocks` — construct `subject` manually in `@BeforeEach` so constructor changes are caught at compile time
- **Assertions:** `assertThat(result).isEqualTo(x)`, `assertThat(subject).returns(x, Subject::getField)`, `assertThatThrownBy(…).isInstanceOf(…).hasMessage(…)`, chain conditions, `SoftAssertions.assertSoftly()` for multiple properties of the same object so all failures are reported at once
- **Parameterized:** `@ParameterizedTest` + `@CsvSource` / `@MethodSource` / `@ValueSource`; no `final` on params; replaces loops/conditionals
- **AAA:** Arrange / Act / Assert with blank-line separators
- **Coverage:** test behaviour not implementation; all paths (happy, edges, errors, all branches); no `if`/loops in test code
- **Test data:** inline for primitives/strings; object mother (`TestFixtures.anOrder().build()`) for complex objects; create builder if missing
- **Field declaration:** no access modifier, no `final` (exception to java style)

### 6. Write to File

Edit existing or write to `src/test/java/<package>/<ClassName>Test.java`. Verify syntax, coverage.

## Edge Cases

- No public methods: suggest integration tests
- Static methods: test via static import
- Inner classes: test via public constructor
- Missing libraries: suggest adding JUnit 5, AssertJ, Mockito
- Kotlin: adapt syntax, same conventions
- Non-conforming existing tests: refactor incrementally
