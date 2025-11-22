# Dependency Inversion Principle (DIP) in Go

## Overview

The **Dependency Inversion Principle (DIP)** is the "D" in SOLID and states:

> **High-level modules should not depend on low-level modules.**
> **Both should depend on abstractions.**
>
> **Abstractions should not depend on details.**
> **Details should depend on abstractions.**

In simpler terms:

* Don't hardcode concrete dependencies.
* Code should depend on **interfaces**, not **implementations**.

---

## Why DIP Matters

| Benefit         | Description                                                                |
| --------------- | -------------------------------------------------------------------------- |
| Decoupling      | High-level business logic stays independent from low-level system details. |
| Testability     | Easier to swap real services with mocks/fakes during testing.              |
| Maintainability | Changes in one module don’t ripple through the system.                     |
| Flexibility     | Switch implementations (e.g., database, logging) without rewriting logic.  |

---

## DIP in Go (the Go way)

Go doesn’t have classes, but **interfaces + composition** make DIP natural:

* Define an **interface** for the behavior.
* Have **low-level structs** implement the interface.
* Inject the interface into **high-level consumers**.

---

## Example: Logging System

### ❌ Violates DIP

```go
// High-level module tightly depends on low-level implementation

package main

type Logger struct {}

func (l *Logger) Log(msg string) {
    fmt.Println("LOG:", msg)
}

func ProcessOrder() {
    logger := &Logger{}
    logger.Log("Processing order")
    // business logic...
}
```

**Problem:** `ProcessOrder()` depends directly on `Logger`. You can't test it with a mock, or switch logging system easily.

---

### ✅ Follows DIP

```go
// Define an abstraction

type Logger interface {
    Log(msg string)
}

// Implement the interface

type ConsoleLogger struct{}
func (c *ConsoleLogger) Log(msg string) {
    fmt.Println("LOG:", msg)
}

// High-level function depends on abstraction

func ProcessOrder(logger Logger) {
    logger.Log("Processing order")
    // business logic...
}

func main() {
    logger := &ConsoleLogger{}
    ProcessOrder(logger)
}
```

**Result:**

* Easily swap `ConsoleLogger` with `FileLogger`, `NoopLogger`, or a mock.
* `ProcessOrder` doesn’t know or care what kind of logger it uses.

---

## Testing Benefit Example

```go
type FakeLogger struct {
    logs []string
}

func (f *FakeLogger) Log(msg string) {
    f.logs = append(f.logs, msg)
}

func TestProcessOrder(t *testing.T) {
    fake := &FakeLogger{}
    ProcessOrder(fake)

    if len(fake.logs) == 0 || fake.logs[0] != "Processing order" {
        t.Errorf("expected log not found")
    }
}
```

---

## Summary

| Principle                         | Go Practice                                     |
| --------------------------------- | ----------------------------------------------- |
| High-level depends on abstraction | Define interfaces, not concrete structs         |
| Low-level implements abstraction  | Concrete types implement those interfaces       |
| Inject dependency                 | Use constructor functions or function arguments |

---

## References

* SOLID Principles: [https://en.wikipedia.org/wiki/SOLID](https://en.wikipedia.org/wiki/SOLID)
* Go Proverbs: [https://go-proverbs.github.io/](https://go-proverbs.github.io/)

*End of DIP documentation.*
