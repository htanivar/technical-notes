#!/usr/bin/env bash
#
# ask-gpt.sh - Zero-Code First AI Task Planner
# Generates structured planning prompts for AI IDEs & coding agents
#

set -eo pipefail

# ANSI color codes
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if arguments provided via CLI or interactive mode
if [ $# -ge 1 ]; then
    task_desc="$1"
    context_files="${2:-}"
    constraints="${3:-}"
else
    # Clear the screen for a clean prompt
    clear

    echo -e "${BOLD}${BLUE}=================================================${NC}"
    echo -e "  ${BOLD}🧠 AI IDE Task Planner (Zero-Code First)${NC}"
    echo -e "${BOLD}${BLUE}=================================================${NC}"
    echo "Let's construct your prompt to save tokens."
    echo ""

    # 1. Gather the core task
    echo -e "${BOLD}1. What is the core objective?${NC}"
    echo "   (e.g., 'Refactor the auth middleware to support JWT' or 'Fix the hydration bug on the dashboard')"
    read -rp "> " task_desc
    while [[ -z "$task_desc" ]]; do
        echo -e "${YELLOW}⚠️ Task description cannot be empty. Please enter the objective:${NC}"
        read -rp "> " task_desc
    done
    echo ""

    # 2. Gather context files
    echo -e "${BOLD}2. Which files should the AI look at?${NC}"
    echo "   (e.g., 'src/middleware.js, components/Navbar.tsx' or press Enter to skip)"
    read -rp "> " context_files
    echo ""

    # 3. Gather constraints
    echo -e "${BOLD}3. Are there any specific constraints, libraries, or edge cases?${NC}"
    echo "   (e.g., 'Use Tailwind only', 'Don't change the database schema', or press Enter to skip)"
    read -rp "> " constraints
    echo ""
fi

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
${context_files:-"Analyze relevant repository files as needed."}

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
echo -e "${GREEN}✅ Done! Your AI prompt has been generated.${NC}"
echo -e "📄 File: ${BOLD}$filename${NC}"
echo "You can now copy the contents of this file or feed it directly into your AI IDE."
