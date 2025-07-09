# Interface Segregation Principle (ISP) in Go

## Overview

The **Interface Segregation Principle (ISP)** is the "I" in SOLID and states:

> **Clients should not be forced to depend on interfaces they do not use.**

In other words:

* Prefer **many small, focused interfaces** over one large, bloated one.
* Each interface should represent a **coherent set of behaviors**.

---

## Why ISP Matters

| Benefit     | Description                                                            |
| ----------- | ---------------------------------------------------------------------- |
| Simplicity  | Clients only need to implement what they use.                          |
| Decoupling  | Changes in one interface method don’t break unrelated implementations. |
| Testability | Easier to mock small interfaces.                                       |
| Readability | Small interfaces are easier to understand and document.                |

---

## Violating ISP

```go
// One large interface forces implementations to deal with unused methods

type MultiFunctionDevice interface {
    Print(doc string)
    Scan() string
    Fax(number string)
}

type SimplePrinter struct{}
func (p *SimplePrinter) Print(doc string) {
    fmt.Println("Printing:", doc)
}
func (p *SimplePrinter) Scan() string {
    return "not supported"
}
func (p *SimplePrinter) Fax(number string) {
    // not supported
}
```

**Problem:** `SimplePrinter` is forced to implement `Scan` and `Fax` which it doesn’t support. This creates confusion and violates ISP.

---

## Respecting ISP

```go
// Define small, segregated interfaces

type Printer interface {
    Print(doc string)
}

type Scanner interface {
    Scan() string
}

type Faxer interface {
    Fax(number string)
}

// SimplePrinter only implements what it needs

type SimplePrinter struct{}
func (p *SimplePrinter) Print(doc string) {
    fmt.Println("Printing:", doc)
}

// MultiFunctionPrinter composes multiple interfaces

type MultiFunctionPrinter struct{}
func (m *MultiFunctionPrinter) Print(doc string) {
    fmt.Println("Printing:", doc)
}
func (m *MultiFunctionPrinter) Scan() string {
    return "Scanned content"
}
func (m *MultiFunctionPrinter) Fax(number string) {
    fmt.Println("Faxing to:", number)
}
```

**Result:**

* Clients only implement what they need.
* Code is cleaner, easier to test, and more reusable.

---

## In Go: A Common Idiom

Go embraces small interfaces:

```go
// io.Writer is a perfect example

type Writer interface {
    Write(p []byte) (n int, err error)
}
```

* Easy to implement.
* Composable with other interfaces (e.g., `ReadWriter`, `ReadCloser`).

---

## Summary

| Principle                               | Go Practice                             |
| --------------------------------------- | --------------------------------------- |
| Don’t force unused methods              | Use multiple small interfaces           |
| Define role-specific behavior           | Keep interface responsibilities focused |
| Favor composition over large interfaces | Embed small interfaces as needed        |

---

## References

* SOLID Principles: [https://en.wikipedia.org/wiki/SOLID](https://en.wikipedia.org/wiki/SOLID)
* Go Proverbs: [https://go-proverbs.github.io/](https://go-proverbs.github.io/)

*End of ISP documentation.*
