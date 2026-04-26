# Hermes Communication Template

Use this file to convey context to Hermes efficiently. Keep it concise; Hermes will load it via the `plan` skill or `read_file` as needed.

## Goal
[One‑sentence description of what you want to achieve.]

## Constraints
- Language / framework versions (e.g., Go 1.22, Node 20, React 18)
- Libraries you *must* or *must not* use
- Testing requirements
- Any other hard limits

## Steps
1. [First action – include file path if relevant]
2. [Second action]
3. [Third action]
   - Sub‑step if needed
4. [...]

## References (optional)
- Link to design docs, API specs, or UI mockups (if needed, add as separate files and reference them here)

## How to use with Hermes
- Load this file as a plan:  
  `plan load ./HERMES_INSTRUCTIONS_TEMPLATE.md`
- For each step that needs coding, delegate to a subagent:  
  `delegate_task goal="<step description>" context="See step X in the plan; file path: <path>" toolsets=["terminal","file"]`
- After completing a useful pattern, save it as a skill for reuse:  
  `skill manage create <skill-name> --content "$(cat ./HERMES_INSTRUCTIONS_TEMPLATE.md)"`
