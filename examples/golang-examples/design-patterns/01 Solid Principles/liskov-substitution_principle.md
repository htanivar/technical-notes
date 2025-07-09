# Liskov Substitution Principle (LSP) in Go

## Overview

The **Liskov Substitution Principle (LSP)** states that **objects of a superclass (or type) should be replaceable with objects of its subclasses (or implementations) without altering the correctness of the program**.

> *"If S is a subtype of T, then objects of type T in a program may be replaced with objects of type S without altering any of the desirable properties of that program."*
> — Barbara Liskov (1987)

## Why LSP Matters

* **Reliability:** Ensures that components remain interchangeable and behave consistently.
* **Maintainability:** Avoids surprises when substituting implementations.
* **Extensibility:** New implementations integrate seamlessly when they conform to expected contracts.

## Core Concept

* **Behavioral Subtyping:** A subtype must honor the expectations set by its base type’s interface or contract.
* **No Unexpected Side Effects:** Subtypes shouldn’t strengthen preconditions or weaken postconditions.

In Go, interfaces define contracts: any implementation must honor the documented behavior.

## Violating LSP

```go
package main

type Reader interface {
    Read(p []byte) (int, error)
}

// FileReader reads from a file

type FileReader struct {}
func (fr *FileReader) Read(p []byte) (int, error) {
    // actual file read
    return 0, nil
}

// FakeReader implements Reader but violates expectations

type FakeReader struct {}
func (fr *FakeReader) Read(p []byte) (int, error) {
    // Ignores p entirely and returns dummy data
    return len(p)*2, nil  // Returns more bytes than buffer size
}

func Process(r Reader) {
    buf := make([]byte, 10)
    n, err := r.Read(buf)
    if err != nil {
        panic(err)
    }
    // We expect n <= len(buf), but FakeReader breaks that
    fmt.Printf("Read %d bytes: %v\n", n, buf[:n])
}
```

*Issue:* `FakeReader` returns `n` larger than the buffer, causing out-of-bounds slices and panics—violating caller’s expectations.

## Respecting LSP

```go
package main

// Correct FakeReader honors contract

type SafeFakeReader struct {}
func (fr *SafeFakeReader) Read(p []byte) (int, error) {
    copy(p, []byte("hello"))
    return 5, nil // never exceeds buffer length
}

func Process(r Reader) {
    buf := make([]byte, 10)
    n, err := r.Read(buf)
    if err != nil {
        panic(err)
    }
    fmt.Printf("Read %d bytes: %s\n", n, string(buf[:n]))
}

func main() {
    readers := []Reader{
        &FileReader{},
        &SafeFakeReader{},
    }
    for _, r := range readers {
        Process(r)
    }
}
```

*Benefit:* Substituting `SafeFakeReader` for `FileReader` never breaks `Process`—behavioral contract holds.

## Guidelines for LSP in Go

* **Document Interface Behavior:** Clearly state preconditions and postconditions in GoDoc.
* **Avoid Strengthening Preconditions:** Subtypes must accept all valid inputs of the base type.
* **Avoid Weakening Postconditions:** Subtypes must fulfill at least the same guarantees as base.
* **Respect Error Contracts:** Errors returned should match documented error semantics.

## References

* Barbara Liskov’s Original Paper (1987)
* SOLID Principles: [https://en.wikipedia.org/wiki/SOLID](https://en.wikipedia.org/wiki/SOLID)
* Go Proverbs: [https://go-proverbs.github.io/](https://go-proverbs.github.io/)

*End of LSP documentation.*
