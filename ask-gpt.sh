#!/bin/bash

# Clear the screen for a clean prompt
clear

echo "================================================="
echo "  🧠 AI IDE Task Planner (Zero-Code First)"
echo "================================================="
echo "Let's construct your prompt to save tokens."
echo ""

# 1. Gather the core task
echo "1. What is the core objective?"
echo "   (e.g., 'Refactor the auth middleware to support JWT' or 'Fix the hydration bug on the dashboard')"
read -p "> " task_desc
echo ""

# 2. Gather context files
echo "2. Which files should the AI look at?"
echo "   (e.g., 'src/middleware.js, components/Navbar.tsx')"
read -p "> " context_files
echo ""

# 3. Gather constraints
echo "3. Are there any specific constraints, libraries, or edge cases?"
echo "   (e.g., 'Use Tailwind only', 'Don't change the database schema', or press Enter to skip)"
read -p "> " constraints
echo ""

# Generate timestamp and directory path
timestamp=$(date +"%Y%m%d_%H%M%S")
date_dir=$(date +"%Y-%m-%d")
target_dir="local/ask-gpt/${date_dir}"
filename="${target_dir}/ask-gpt-${timestamp}.txt"

# Ensure the target directory exists
mkdir -p "$target_dir"

# Create the file with the template
cat > "$filename" <<EOF
# TASK: 
$task_desc

# CONTEXT FILES:
$context_files

# CONSTRAINTS / NOTES:
${constraints:-"No specific constraints provided. Rely on standard best practices."}

---

# RULES OF ENGAGEMENT

You are acting as a Senior Staff Engineer. We are currently in **PHASE 1: PLANNING**. 

1. **Zero-Code Policy:** Do not write any implementation code, functions, or CSS in this response. 
2. **Context Check:** Briefly analyze the requested task against the provided context files. If the requirements are ambiguous, ask a maximum of 3 clarifying questions.
3. **Draft the Plan:** If you have enough context, outline a step-by-step architectural plan. 
4. **Format:** Output the plan as a Markdown checklist (\`- [ ]\`). Keep descriptions concise.

# REQUIRED ENDING
End your response exactly with this phrase: 
**"Plan ready. Type 'APPROVE' to authorize coding, or request changes."**
EOF

# Confirmation
echo "✅ Done! Your AI prompt has been generated."
echo "📄 File: $filename"
echo "You can now copy the contents of this file or feed it directly into your AI IDE."