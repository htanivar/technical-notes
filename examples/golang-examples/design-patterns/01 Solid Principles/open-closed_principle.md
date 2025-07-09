# Open-Closed Principle (OCP) in Go

## Overview

The **Open-Closed Principle (OCP)** states that **software entities** (types, modules, functions, etc.) should be:

* **Open for extension:** You can add new behavior without modifying existing code.
* **Closed for modification:** Existing, tested code remains unchanged to avoid regressions.

## Why OCP Matters

* **Extensibility:** New features can be introduced with minimal impact.
* **Stability:** Reduces risk of bugs in proven code.
* **Maintainability:** Encourages clear extension points rather than complex conditional logic.

## Core Concept

> "Extend behavior by adding new code, rather than changing existing code."

In Go, this is often achieved via:

* **Interfaces:** Depend on abstractions, not concrete types.
* **Dependency injection:** Inject implementations that satisfy interfaces.

## Example: Notification System

### Violating OCP

```go
package main

type UserNotifier struct {}

func (u *UserNotifier) Notify(userID, message, method string) {
    if method == "email" {
        sendEmail(userID, message)
    } else if method == "sms" {
        sendSMS(userID, message)
    }
    // Adding support for a new method requires modifying this function
}
```

> **Issue:** Every time a new notification channel is required (e.g., push notifications), `Notify` must be changed.

### Respecting OCP

```go
package main

// NotificationSender defines the contract for sending notifications

type NotificationSender interface {
    Send(userID, message string) error
}

// EmailSender implements NotificationSender

type EmailSender struct {}
func (e *EmailSender) Send(userID, message string) error {
    return sendEmail(userID, message)
}

// SMSSender implements NotificationSender
type SMSSender struct {}
func (s *SMSSender) Send(userID, message string) error {
    return sendSMS(userID, message)
}

// Notifier uses any NotificationSender without modification
type Notifier struct {
    Sender NotificationSender
}

func (n *Notifier) Notify(userID, message string) error {
    return n.Sender.Send(userID, message)
}

func main() {
    emailNotifier := &Notifier{Sender: &EmailSender{}}
    smsNotifier := &Notifier{Sender: &SMSSender{}}

    emailNotifier.Notify("user1", "Welcome!")
    smsNotifier.Notify("user2", "Your code has shipped.")
}
```

> **Benefit:** To add a new channel (e.g., `PushSender`), simply implement `NotificationSender` and inject—no changes to `Notifier` or existing code.

## References

* Go Proverbs: [https://go-proverbs.github.io/](https://go-proverbs.github.io/)
* SOLID Principles: [https://en.wikipedia.org/wiki/SOLID](https://en.wikipedia.org/wiki/SOLID)

*End of OCP documentation.*
