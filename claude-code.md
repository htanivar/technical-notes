# CLAUDE CODE TERMINAL CHEATSHEET
**Version: 1.0 | Updated: 2026**

---

## 🚀 GETTING STARTED

| Command | Description |
|---------|-------------|
| `claude` | Start interactive session |
| `claude "fix this bug"` | Run one-time task and exit |
| `claude --help` | Show help information |
| `claude --version` | Show version |
| `claude --verbose` | Enable verbose logging |
| `claude --config <path>` | Use custom config file |

---

## 💬 INTERACTIVE COMMANDS (Inside Claude session)

| Command | Description |
|---------|-------------|
| `/help` | Show all available commands |
| `/clear` | Clear conversation history |
| `/exit` or `Ctrl+D` | Exit Claude Code |
| `Ctrl+C` | Cancel current generation |
| `Ctrl+L` | Clear screen |
| `Tab` | Auto-complete suggestions |
| `↑` / `↓` | Navigate command history |

---

## 📁 FILE & PROJECT MANAGEMENT

| Command | Description |
|---------|-------------|
| `/init` | Create CLAUDE.md for project memory |
| `/add <file(s)>` | Add files to context |
| `/remove <file(s)>` | Remove files from context |
| `/list` | Show files in current context |
| `/reset` | Reset all context and conversation |
| `/load <session_id>` | Load a previous session |
| `/save [name]` | Save current session |
| `/sessions` | List all saved sessions |

---

## 🔍 CODE ANALYSIS & UNDERSTANDING

| Command | Description |
|---------|-------------|
| `"explain this code"` | Explain what code does |
| `"what does [function] do?"` | Explain specific function |
| `"find all references to [var]"` | Find variable/function usage |
| `"show me the call stack"` | Display function call hierarchy |
| `"analyze complexity of [file]"` | Show time/space complexity |
| `"what are the dependencies?"` | List project dependencies |
| `"find security issues"` | Scan for vulnerabilities |
| `"trace the execution of [flow]"` | Follow data flow through code |

---

## ✏️ CODE MODIFICATION & GENERATION

| Command | Description |
|---------|-------------|
| `"refactor [function] to..."` | Refactor code with specific pattern |
| `"add error handling to..."` | Add try-catch blocks |
| `"optimize [function]"` | Improve performance |
| `"rename [variable] to [name]"` | Smart rename across files |
| `"extract [logic] to new function"` | Create new function from existing code |
| `"inline [function]"` | Replace function calls with body |
| `"generate unit tests for [file]"` | Create test suite |
| `"add logging to [function]"` | Insert debug/info logging |
| `"convert [code] to use async"` | Convert callbacks to async/await |
| `"migrate [syntax] to [new]"` | Update deprecated syntax |

---

## 🐛 DEBUGGING & PROBLEM SOLVING

| Command | Description |
|---------|-------------|
| `"debug [error message]"` | Explain and fix error |
| `"why is [function] failing?"` | Analyze failure reason |
| `"what's wrong with [line]"` | Check specific line for issues |
| `"find bug in [logic]"` | Locate logical errors |
| `"trace the bug from [input]"` | Step through execution to find bug |
| `"add debug breakpoints"` | Insert debugging statements |
| `"fix the memory leak in..."` | Identify and fix memory issues |
| `"what's causing the race condition"` | Find concurrency problems |

---

## 🔧 TASK-SPECIFIC WORKFLOWS

| Command | Description |
|---------|-------------|
| `"review this PR"` | Code review pull request |
| `"document this API"` | Generate API documentation |
| `"create a README"` | Generate project README |
| `"update CHANGELOG"` | Add changes to changelog |
| `"bump version to [x.x.x]"` | Update version across project |
| `"run linter and fix issues"` | Auto-fix linting problems |
| `"format this code"` | Apply code formatter |
| `"find dead code"` | Identify unused functions/variables |
| `"check for TODO comments"` | List all pending TODOs |

---

## 🧪 TESTING & QUALITY

| Command | Description |
|---------|-------------|
| `"run tests"` | Execute test suite |
| `"fix failing tests"` | Debug and fix test failures |
| `"increase coverage for [file]"` | Add tests to improve coverage |
| `"what tests are missing?"` | Identify untested scenarios |
| `"mock [external service]"` | Create test mocks |
| `"generate integration tests"` | Create end-to-end tests |
| `"performance benchmark [func]"` | Measure execution time |
| `"check edge cases for [func]"` | Identify boundary conditions |

---

## 📊 PROJECT MEMORY (CLAUDE.md)

### CLAUDE.md syntax examples:

```markdown
## Project Overview
Brief description of the project

## Architecture
- Key components and their relationships
- Data flow patterns

## Coding Standards
- Naming conventions
- File structure rules
- Testing requirements

## Common Commands
- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint`

## Known Issues
- Gotchas and workarounds
- Platform-specific problems

## External Dependencies
- Critical services and their APIs
- Environment variables needed