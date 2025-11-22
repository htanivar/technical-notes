# Builder Pattern in Go

## Overview

The **Builder Pattern** is a creational design pattern used to construct complex objects step by step. It provides a flexible solution when an object needs to be created with many optional configurations.

In Go, the builder pattern isn't native like in some OOP languages, but it can be implemented effectively using:

* Method chaining (fluent interface)
* Functional options
* Faceted builders

---

## Why Use the Builder Pattern?

| Benefit                | Description                                                            |
| ---------------------- | ---------------------------------------------------------------------- |
| Readability            | Clear, fluent way to configure objects with multiple fields.           |
| Maintainability        | Avoids complex constructors or bloated structs.                        |
| Separation of Concerns | Different builders can focus on different parts (facets) of an object. |
| Optional Configuration | Easily skip or add optional fields without creating many constructors. |

---

## Example: Building a `Person` Object

### ✅ Fluent Builder (Method Chaining)

```go
package main
import "fmt"

type Person struct {
    Name, Position string
    Street, City   string
}

type PersonBuilder struct {
    person *Person
}

func NewPersonBuilder() *PersonBuilder {
    return &PersonBuilder{&Person{}}
}

func (b *PersonBuilder) Named(name string) *PersonBuilder {
    b.person.Name = name
    return b
}

func (b *PersonBuilder) WorksAs(position string) *PersonBuilder {
    b.person.Position = position
    return b
}

func (b *PersonBuilder) LivesOnStreet(street string) *PersonBuilder {
    b.person.Street = street
    return b
}

func (b *PersonBuilder) InCity(city string) *PersonBuilder {
    b.person.City = city
    return b
}

func (b *PersonBuilder) Build() *Person {
    return b.person
}

func main() {
    person := NewPersonBuilder().
        Named("Ravi").
        WorksAs("Engineer").
        LivesOnStreet("MG Road").
        InCity("Chennai").
        Build()

    fmt.Printf("%+v\n", person)
}
```

---

## 🔄 Faceted Builder (Divide Responsibility)

```go
type PersonFacetedBuilder struct {
    person *Person
}

func NewPersonFacetedBuilder() *PersonFacetedBuilder {
    return &PersonFacetedBuilder{&Person{}}
}

func (b *PersonFacetedBuilder) Info() *PersonJobBuilder {
    return &PersonJobBuilder{b}
}

func (b *PersonFacetedBuilder) Address() *PersonAddressBuilder {
    return &PersonAddressBuilder{b}
}

func (b *PersonFacetedBuilder) Build() *Person {
    return b.person
}

type PersonJobBuilder struct {
    *PersonFacetedBuilder
}

func (j *PersonJobBuilder) Named(name string) *PersonJobBuilder {
    j.person.Name = name
    return j
}

func (j *PersonJobBuilder) WorksAs(position string) *PersonJobBuilder {
    j.person.Position = position
    return j
}

type PersonAddressBuilder struct {
    *PersonFacetedBuilder
}

func (a *PersonAddressBuilder) LivesOnStreet(street string) *PersonAddressBuilder {
    a.person.Street = street
    return a
}

func (a *PersonAddressBuilder) InCity(city string) *PersonAddressBuilder {
    a.person.City = city
    return a
}

func main() {
    person := NewPersonFacetedBuilder().
        Info().Named("Ravi").WorksAs("Engineer").
        Address().LivesOnStreet("MG Road").InCity("Chennai").
        Build()

    fmt.Printf("%+v\n", person)
}
```

---

## Advantages Summary

| Feature              | Fluent Builder          | Faceted Builder                           |
| -------------------- | ----------------------- | ----------------------------------------- |
| Clear chaining       | ✅ Yes                   | ✅ Yes                                     |
| Code separation      | ❌ Mixed config logic    | ✅ Address/job logic in their own builders |
| Optional fields      | ✅ Easy to skip          | ✅ Easy to skip                            |
| Scalable for complex | ⚠️ Harder as size grows | ✅ Great for large, complex objects        |

---

## When to Use

* Object has many optional fields
* Multiple configurations depending on context
* Want readable object construction
* Need to abstract complex creation logic

## Go Tips

* Return `*Builder` in each method for chaining
* Embed shared builder in facets to share state
* Add `.Build()` or `.Create()` method to finalize construction

---

## References

* Effective Go: [https://golang.org/doc/effective\_go.html](https://golang.org/doc/effective_go.html)
* Go Proverbs: [https://go-proverbs.github.io/](https://go-proverbs.github.io/)
* SOLID Principles: [https://en.wikipedia.org/wiki/SOLID](https://en.wikipedia.org/wiki/SOLID)

*End of Builder Pattern documentation.*
