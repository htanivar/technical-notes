# Hermes Agent Quick Reference & Best‑Practice Guide

This document summarizes the most useful Hermes capabilities, slash commands, and workflow patterns to help you interact efficiently while minimizing token usage.

---
[HERMES_INSTRUCTIONS_TEMPLATE.md](HERMES_INSTRUCTIONS_TEMPLATE.md)  
[HERMES_MULTI_PROJECT_TEMPLATE.md](HERMES_MULTI_PROJECT_TEMPLATE.md)

## 1. Core Interaction Patterns

| Pattern | When to Use | How |
|---------|-------------|-----|
| **Load a plan / instructions** | You have a multi‑step task or a template you want to reuse. | `plan load ./PATH/TO/FILE.md`  (or `skill view plan` then follow its instructions). |
| **Delegate coding work** | A step needs non‑trivial implementation (5+ tool calls, branching, loops). | `delegate_task goal="<clear goal>" context="<relevant info, file paths>" toolsets=["terminal","file"] workdir="/path/to/project"` |
| **Search past sessions** | You need to recall what was done before. | `session_search "<keywords>"`  (omit args to browse recent sessions). |
| **Save durable facts** | You learn a preference, environment quirk, or stable convention. | `memory add --target memory --content "<fact>"`  (or `--target user` for personal prefs). |
| **Create a reusable skill** | You discover a repeatable procedure (e.g., “add API endpoint + UI”). | `skill manage create <skill-name> --content "$(cat ./FILE.md)"` |
| **Run a background job** | Long‑running task you don’t need to watch. | `terminal command="<long cmd>" background=true notify_on_complete=true` |
| **Run a scheduled task** | You need something to happen periodically. | `cronjob create --prompt "<self‑contained prompt>" --schedule "every 1h" --skills ["plan","delegate_task"]` |

---

## 2. Essential Slash Commands (available in CLI & most gateways)

| Command | Alias | Category | Description |
|---------|-------|----------|-------------|
| `/help` | – | Info | Show help & list of commands. |
| `/plan` | – | Session | Load a plan file (see `plan load`). |
| `/delegate` | – | Session | Shortcut for `delegate_task`. |
| `/skill` | – | Tools & Skills | Manage skills (`skill view`, `skill manage create`, etc.). |
| `/memory` | – | Tools & Skills | View/add/remove memory entries. |
| `/session` | – | Session | List/resume past sessions. |
| `/todo` | – | Session | View/edit session todo list. |
| `/terminal` | – | Session | Run a terminal command (foreground). |
| `/bg` | – | Session | Start a background terminal process. |
| `/cron` | – | Session | Manage cron jobs. |
| `/file` | – | Session | File operations (`read_file`, `write_file`, `patch`, `search_files`). |
| `/browser` | – | Session | Web‑interaction commands (`browser_navigate`, `browser_click`, …). |
| `/vision` | – | Session | Analyze images (`vision_analyze`). |
| `/image` | – | Session | Generate images (`image_generate`). |
| `/tts` | – | Session | Text‑to‑speech (`text_to_speech`). |
| `/clear` | – | Session | Clear the chat screen. |
| `/quit` / `/exit` | – | Exit | End the session. |

*To see the full list with arguments, run `/help` or `/help <command>`.*

---

## 3. Keeping Token Usage Low

1. **Never paste whole files** – use `read_file` with `offset`/`limit` or `search_files` to pull only the needed snippets.
2. **Load context once** – put instructions, API specs, or DB schemas in a file and load it via `plan load` (or `skill view`) at the start of a session.
3. **Use subagents** – `delegate_task` runs the work in an isolated context and returns only the final summary, keeping your main session light.
4. **Leverage memory & skills** – store repeated facts or procedures so you don’t re‑explain them each time.
5. **Search instead of recall** – `session_search` gives you a summary of past work; you can then request only the missing details.

---

## 4. Typical Multi‑Project Workflow (API + UI)

1. **Create a template per project** (see `MULTI_PROJECT_TEMPLATE.md` or your own `HERMES_INSTRUCTIONS_TEMPLATE.md`).
2. **When starting work on a project:**  
   ```bash
   plan load /path/to/projectX/PLAN.md   # loads only that project's context
   ```
3. **Execute steps:**  
   ```bash
   # API example
   delegate_task goal="Add POST /orders handler" \
     context="See PLAN step 2; file: handlers/order.go" \
     toolsets=["terminal","file"] \
     workdir="/path/to/api"

   # UI example
   delegate_task goal="Create OrderForm component" \
     context="See PLAN step 1; file: src/components/OrderForm.tsx" \
     toolsets=["terminal","file"] \
     workdir="/path/to/ui"
   ```
4. **Switch projects** – just load the other project’s plan and adjust `workdir`.
5. **Save the pattern** – after a successful end‑to‑end feature, turn it into a skill:
   ```bash
   skill manage create api-ui-feature --content "$(cat ./HERMES_MULTI_PROJECT_TEMPLATE.md)"
   ```

---

## 5. File Locations (default)

- Current working directory: where you launched Hermes (or the `workdir` you set).
- Hermes config & data: `~/.hermes/` (profiles, logs, skills, memory).
- Templates you just created:  
  - `/home/ubuntu/.hermes/hermes-agent/HERMES_INSTRUCTIONS_TEMPLATE.md`  
  - `/home/ubuntu/.hermes/hermes-agent/MULTI_PROJECT_TEMPLATE.md`  
  - `/home/ubuntu/.hermes/hermes-agent/HERMES_GUIDE.md` (this file)

You can copy or symlink these templates into any project folder for convenience.

---

## 6. Quick Checklist Before Sending a Message

- [ ] Did I load the relevant plan/instructions for this project? (`plan load …`)
- [ ] Is my `workdir` set correctly for any terminal/file/delegate calls?
- [ ] Am I sending only new info (error, snippet, decision) and not repeating the whole context?
- [ ] If I’m about to repeat a procedure, do I have a skill for it? (`skill view <name>`)
- [ ] Do I need to recall something from the past? (`session_search …`)
- [ ] Should I save what I just learned? (`memory add …` or `skill manage create …`)

---

### That’s it!

Keep this guide handy (you can `read_file ./HERMES_GUIDE.md` whenever you need a refresher).  
Feel free to ask Hermes to update it as you discover new patterns—just treat it like any other file and use `patch` or `write_file`.

Happy coding!