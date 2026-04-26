# Multi-Project Hermes Communication Template

Use this template when you need to work on two or more separate code bases (e.g., API & UI) in the same Hermes session. Keep each project's section concise; load the relevant section as a plan before working in that project.

---

## Project 1: <API / Backend>
**Path:** `/path/to/project1`

### Goal
[One‑sentence description of what you want to achieve in this project.]

### Constraints
- Language / framework versions (e.g., Go 1.22, Node 20, Python 3.11)
- Libraries you *must* or *must not* use
- Testing requirements
- Any other hard limits

### Steps
1. [First action – include file path if relevant]
2. [Second action]
3. [Third action]
   - Sub‑step if needed
4. [...]

### References (optional)
- Link to design docs, API specs, or UI mockups (if needed, add as separate files and reference them here)

---

## Project 2: <UI / Frontend>
**Path:** `/path/to/project2`

### Goal
[One‑sentence description of what you want to achieve in this project.]

### Constraints
- Language / framework versions (e.g., React 18, TypeScript 5, Vue 3)
- Libraries you *must* or *must not* use
- Testing requirements
- Any other hard limits

### Steps
1. [First action – include file path if relevant]
2. [Second action]
3. [Third action]
   - Sub‑step if needed
4. [...]

### References (optional)
- Link to design docs, API specs, or UI mockups (if needed, add as separate files and reference them here)

---

## How to use with Hermes

1. **Load the relevant project section as a plan**  
   You can either:
   - Copy the section for the project you want to work on into a temporary file and load it, or
   - Use `read_file` with `offset`/`limit` to extract just that section and pipe it into a file, then load it.

   Example (bash):
   ```bash
   # Extract Project 1 section (lines 8-30) and load as plan
   sed -n '8,30p' ./HERMES_MULTI_PROJECT_TEMPLATE.md > /tmp/project1_plan.md
   plan load /tmp/project1_plan.md
   ```

   Or manually create `project1_instructions.md` with the content from the section.

2. **Set the working directory for tool calls**  
   When you run terminal, file, or delegate_task commands, specify the project's root via `workdir` (or include it in the context passed to a subagent).

   Example:
   ```bash
   # API work
   terminal command="go test ./..." workdir="/path/to/project1"
   delegate_task goal="Add POST /orders handler" context="See Project 1 step 2; file: handlers/order.go" toolsets=["terminal","file"] workdir="/path/to/project1"

   # UI work
   terminal command="npm run test" workdir="/path/to/project2"
   delegate_task goal="Create OrderForm component" context="See Project 2 step 1; file: src/components/OrderForm.tsx" toolsets=["terminal","file"] workdir="/path/to/project2"
   ```

3. **Switching projects**  
   When you need to move to the other project:
   - Load the other project's plan (repeat step 1).
   - Update the `workdir` in your commands to the other project's path.

4. **Saving repeatable patterns as skills**  
   If you frequently perform the same across‑project workflow (e.g., "add API endpoint + matching UI component"), turn it into a skill:
   ```
   skill manage create api-ui-feature --content "$(cat ./MULTI_PROJECT_TEMPLATE.md)"
   ```
   Then invoke the skill and just point it at the appropriate `workdir` for each project.

5. **Keeping token usage low**  
   - Only send new instructions, error messages, or small code snippets in chat.
   - Let Hermes pull the bulk of the context from the loaded plan or from files via `read_file`/`search_files`.
   - Use `session_search` to recall past work on a specific project without re‑explaining everything.

--- 

*Tip:* Keep this template under version control (e.g., in a `docs/` folder) so you can evolve it as your workflow changes.