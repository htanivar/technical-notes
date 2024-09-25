#!/bin/bash

# Function to validate and install Go if not available
install_go() {
    if ! command -v go &> /dev/null; then
        echo "Go is not installed. Installing Go..."

        # Detect OS and install Go accordingly
        OS=$(uname -s)
        ARCH=$(uname -m)
        GO_VERSION="1.20.3"

        if [ "$OS" == "Linux" ]; then
            wget https://dl.google.com/go/go$GO_VERSION.linux-$ARCH.tar.gz
            sudo tar -C /usr/local -xzf go$GO_VERSION.linux-$ARCH.tar.gz
            export PATH=$PATH:/usr/local/go/bin
        elif [ "$OS" == "Darwin" ]; then
            brew install go
        else
            echo "Unsupported OS. Please install Go manually."
            exit 1
        fi

        echo "Go installed successfully."
    else
        echo "Go is already installed."
    fi
}

# Function to validate and install swag CLI
install_swag() {
    if ! command -v swag &> /dev/null; then
        echo "Swag CLI is not installed. Installing now..."
        go install github.com/swaggo/swag/cmd/swag@latest
        if [ $? -ne 0 ]; then
            echo "Failed to install Swag CLI. Please check your Go installation."
            exit 1
        fi
        export PATH=$PATH:$(go env GOPATH)/bin
        echo "Swag CLI installed successfully."
    else
        echo "Swag CLI is already installed."
    fi
}

# Function to request project name input
get_project_name() {
    while true; do
        read -p "Enter the project name (alphanumeric only): " PROJECT_NAME
        if [[ $PROJECT_NAME =~ ^[a-zA-Z0-9]+$ ]]; then
            break
        else
            echo "Invalid project name. Please use only alphanumeric characters."
        fi
    done
}

# Validate dependencies
validate_dependencies() {
    install_go
    install_swag
    echo "All dependencies are satisfied."
}

# Main script execution

# Validate dependencies
validate_dependencies

# Get project name from user input
get_project_name

# Create project directory
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Initialize Go module
go mod init $PROJECT_NAME

# Create project folder structure
mkdir -p config routes handlers services utils docs tests http-tests

# Install required Go packages
go get -u github.com/gin-gonic/gin
if [ $? -ne 0 ]; then
    echo "Failed to install Gin framework. Please check your Go environment."
    exit 1
fi

go get -u github.com/swaggo/gin-swagger
if [ $? -ne 0 ]; then
    echo "Failed to install Gin Swagger. Please check your Go environment."
    exit 1
fi

go get -u github.com/swaggo/files
if [ $? -ne 0 ]; then
    echo "Failed to install Swagger files. Please check your Go environment."
    exit 1
fi

go get -u github.com/stretchr/testify/assert
if [ $? -ne 0 ]; then
    echo "Failed to install Testify for unit tests. Please check your Go environment."
    exit 1
fi

# Create main.go
cat <<EOL > main.go
package main

import (
    "$PROJECT_NAME/config"
    "$PROJECT_NAME/routes"
    "github.com/gin-gonic/gin"
    _ "$PROJECT_NAME/docs"
    ginSwagger "github.com/swaggo/gin-swagger"
    swaggerFiles "github.com/swaggo/files"
)

// @title $PROJECT_NAME API
// @version 1.0
// @description This is a sample server for $PROJECT_NAME.

// @host localhost:8080
// @BasePath /api/v1
func main() {
    // Load configuration
    config.LoadConfig()

    // Create a new Gin router
    router := gin.Default()

    // Register Swagger
    router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

    // Register routes
    routes.RegisterRoutes(router)

    // Start the server
    router.Run(":8080")
}
EOL

# Create config/config.go
cat <<EOL > config/config.go
package config

import (
    "log"
)

func LoadConfig() {
    log.Println("Configuration loaded")
}
EOL

# Create routes/routes.go
cat <<EOL > routes/routes.go
package routes

import (
    "github.com/gin-gonic/gin"
    "$PROJECT_NAME/handlers"
)

func RegisterRoutes(r *gin.Engine) {
    api := r.Group("/api/v1")
    {
        userRoutes := api.Group("/users")
        {
            userRoutes.GET("/", handlers.GetUsers)
            userRoutes.GET("/:id", handlers.GetUserByID)
        }
    }
}
EOL

# Create handlers/user.go
cat <<EOL > handlers/user.go
package handlers

import (
    "github.com/gin-gonic/gin"
    "net/http"
    "strconv"
)

type User struct {
    ID   int    \`json:"id"\`
    Name string \`json:"name"\`
}

var users = []User{
    {ID: 1, Name: "John Doe"},
    {ID: 2, Name: "Jane Doe"},
}

// GetUsers godoc
// @Summary Get a list of users
// @Success 200 {array} User
// @Router /api/v1/users [get]
func GetUsers(c *gin.Context) {
    c.JSON(http.StatusOK, users)
}

// GetUserByID godoc
// @Summary Get a user by ID
// @Param id path int true "User ID"
// @Success 200 {object} User
// @Failure 404 {string} string "User not found"
// @Router /api/v1/users/{id} [get]
func GetUserByID(c *gin.Context) {
    id, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, "Invalid user ID")
        return
    }

    for _, user := range users {
        if user.ID == id {
            c.JSON(http.StatusOK, user)
            return
        }
    }

    c.JSON(http.StatusNotFound, "User not found")
}
EOL

# Create services/user.go
cat <<EOL > services/user.go
package services

// ExampleService contains business logic for users
func ExampleService() string {
    return "This is a service logic example."
}
EOL

# Create utils/utils.go
cat <<EOL > utils/utils.go
package utils

// ExampleUtility is a utility function
func ExampleUtility() string {
    return "This is a utility function"
}
EOL

# Create advanced unit tests
cat <<EOL > tests/handlers_test.go
package tests

import (
    "$PROJECT_NAME/handlers"
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
)

func TestGetUsers(t *testing.T) {
    router := gin.Default()
    router.GET("/api/v1/users", handlers.GetUsers)

    req, _ := http.NewRequest("GET", "/api/v1/users", nil)
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    assert.Equal(t, http.StatusOK, w.Code)
    assert.Contains(t, w.Body.String(), "John Doe")
}

func TestGetUserByID(t *testing.T) {
    router := gin.Default()
    router.GET("/api/v1/users/:id", handlers.GetUserByID)

    req, _ := http.NewRequest("GET", "/api/v1/users/1", nil)
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    assert.Equal(t, http.StatusOK, w.Code)
    assert.Contains(t, w.Body.String(), "John Doe")
}

func TestGetUserByIDNotFound(t *testing.T) {
    router := gin.Default()
    router.GET("/api/v1/users/:id", handlers.GetUserByID)

    req, _ := http.NewRequest("GET", "/api/v1/users/999", nil)
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    assert.Equal(t, http.StatusNotFound, w.Code)
    assert.Contains(t, w.Body.String(), "User not found")
}
EOL

# Create HTTP tests
cat <<EOL > http-tests/users.http
### Get all users
GET http://localhost:8080/api/v1/users
Accept: application/json

###

### Get a user by ID
GET http://localhost:8080/api/v1/users/1
Accept: application/json

###

### Get a non-existing user
GET http://localhost:8080/api/v1/users/999
Accept: application/json
EOL

# Create README.md
cat <<EOL > README.md
# $PROJECT_NAME

## Overview

$PROJECT_NAME is a Golang-based web service using the Gin framework. It provides RESTful APIs with integrated Swagger documentation.

## Features

- Gin framework for high-performance HTTP requests.
- Swagger integration for API documentation.
- Modular folder structure: config, routes, handlers, services, utils.
- Unit tests using Testify.
- HTTP tests using .http files.

## Project Structure

\`\`\`
$PROJECT_NAME/
├── config/           # Configuration files
├── routes/           # Route definitions
├── handlers/         # HTTP request handlers
├── services/         # Business logic
├── utils/            # Utility functions
├── tests/            # Unit tests
├── http-tests/       # HTTP tests for controllers
├── docs/             # Swagger documentation
└── README.md         # Project overview and instructions
\`\`\`

## Setup

### Prerequisites

- [Golang](https://golang.org/doc/install) (version 1.16+ recommended)
- [Swag CLI](https://github.com/swaggo/swag) for generating Swagger docs

### Installation

1. **Clone the repository**:

   \`\`\`bash
   git clone <repository-url>
   cd $PROJECT_NAME
   \`\`\`

2. **Install dependencies**:

   \`\`\`bash
   go mod tidy
   \`\`\`

3. **Generate Swagger docs**:

   \`\`\`bash
   swag init
   \`\`\`

4. **Run the server**:

   \`\`\`bash
   go run main.go
   \`\`\`

## Usage

- Access the API documentation at [http://localhost:8080/swagger/index.html](http://localhost:8080/swagger/index.html).
- Use the provided `.http` files in `http-tests/` for testing endpoints via IntelliJ or other HTTP clients.

## Testing

Run unit tests with:

\`\`\`bash
go test ./tests/...
\`\`\`

EOL

# Generate Swagger docs (run swag init)
swag init
if [ $? -ne 0 ]; then
    echo "Failed to generate Swagger documentation. Please check your Swag installation."
    exit 1
fi

# Build and run the project
go run main.go
if [ $? -ne 0 ]; then
    echo "Failed to run the project. Please check your Go environment and dependencies."
    exit 1
fi

