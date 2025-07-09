# Single Responsibility Principle (SRP) in Go

## Overview

The **Single Responsibility Principle (SRP)** states that a type or module should have one, and only one, reason to change. In Go, this means splitting functionality into small, focused types or functions such that each has a clear, singular responsibility.

---

## Why SRP Matters

- **Maintainability:** Changes for one concern don’t ripple across unrelated code.
- **Testability:** Smaller units of behavior are easier to test in isolation.
- **Readability:** Code with a single focus is simpler to understand.
- **Reusability:** Each component can be reused without pulling in unrelated functionality.

---

## Core Concept

> **A type (function, struct, package, etc.) should have only one reason to change.**

In Go:

- **Structs** should model a single concept.
- **Functions/Methods** should perform one clear action.
- **Packages** should group cohesive functionality.

---

## Example: User Registration

### 1. Violating SRP

```go
package main

import (
	"database/sql"
	"fmt"
	"log"
)

type UserManager struct {
	db *sql.DB
}

// RegisterUser handles validation, hashing, persistence, email, and logging.
func (u *UserManager) RegisterUser(username, password string) error {
	// 1. Validate input
	if len(username) < 3 {
		return fmt.Errorf("username too short")
	}
	
	// 2. Hash password
	hashed := hashPassword(password)
	
	// 3. Insert into database
	_, err := u.db.Exec("INSERT INTO users (name, pwd) VALUES (?, ?)", username, hashed)
	if err != nil {
		return err
	}
	
	// 4. Send confirmation email
	sendEmail(username, "Welcome!")
	
	// 5. Write log file
	log.Println("User registered:", username)

	return nil
}
```

*Issues:*

- Multiple reasons to change: validation rules, hash algorithm, DB schema, email template, logging logic.
- Hard to test or extend.

---

### 2. Applying SRP

We split each responsibility into its own type:

```go
package main

import (
	"database/sql"
	"fmt"
	"log"
)

// 1. Validation
type UserValidator struct{}
func (uv *UserValidator) Validate(username, password string) error {
	if len(username) < 3 {
		return fmt.Errorf("username too short")
	}
	return nil
}

// 2. Hashing
type PasswordHasher struct{}
func (ph *PasswordHasher) Hash(password string) (string, error) {
	// imagine bcrypt or similar
	return hashAlg(password), nil
}

// 3. Persistence
type UserRepository struct {
	db *sql.DB
}
func (ur *UserRepository) Save(username, hashed string) error {
	_, err := ur.db.Exec("INSERT INTO users (name, pwd) VALUES (?, ?)", username, hashed)
	return err
}

// 4. Emailing
type EmailSender struct{}
func (es *EmailSender) SendConfirmation(username string) error {
	// send email logic
	return nil
}
```

#### Main Function with SRP

```go
func main() {
	// Setup dependencies
	db, _ := sql.Open("sqlite3", "file:test.db")
	validator := &UserValidator{}
	hasher := &PasswordHasher{}
	repo := &UserRepository{db: db}
	emailer := &EmailSender{}
	logger := log.Default()

	username, password := "alice", "password123"

	// 1. Validate
	if err := validator.Validate(username, password); err != nil {
		logger.Fatal(err)
	}

	// 2. Hash
	hashed, err := hasher.Hash(password)
	if err != nil {
		logger.Fatal(err)
	}

	// 3. Save
	if err := repo.Save(username, hashed); err != nil {
		logger.Fatal(err)
	}

	// 4. Send Email
	if err := emailer.SendConfirmation(username); err != nil {
		logger.Println("warning: email failed:", err)
	}

	// 5. Log
	logger.Println("User registered successfully")
}
```

**Benefits:**

- Each type/function focuses on one task.
- Easy to swap implementations (e.g., mock `EmailSender` for tests).
- Changes to validation or hashing won’t touch database or email code.

---

## References

- Go Proverbs: [https://go-proverbs.github.io/](https://go-proverbs.github.io/)
- SOLID Principles: [https://en.wikipedia.org/wiki/SOLID](https://en.wikipedia.org/wiki/SOLID)

---

*End of SRP documentation.*

