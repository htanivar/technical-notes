#!/bin/bash

# Clear the screen for a clean prompt
clear

echo "================================================="
echo "  🧠 AI IDE Task Planner (Token-Optimized)"
echo "================================================="
echo "Let's construct your prompt with protection guardrails."
echo ""

# Helper function to read multiline input until a special delimiter character/word
read_multiline() {
    local prompt_heading="$1"
    local var_name="$2"
    local end_char="${3:-END}"

    echo "$prompt_heading"
    echo "   (Enter text below. Type '$end_char' on a line by itself to finish)"
    
    local content=""
    local line
    while IFS= read -r line; do
        if [[ "$line" == "$end_char" ]]; then
            break
        fi
        if [[ -z "$content" ]]; then
            content="$line"
        else
            content="${content}"$'\n'"${line}"
        fi
    done
    
    printf -v "$var_name" "%s" "$content"
}

# 1. Delimiter / Special Character selection
echo "1. Set closing special character / word for multiline text?"
echo "   (Press Enter for default 'END')"
read -p "> " delimiter
delimiter=${delimiter:-"END"}
echo ""

# 2. Core Objective
echo "2. What is the core objective?"
echo "   (e.g., 'Refactor the auth middleware to support JWT')"
read -p "> " task_desc
echo ""

# 3. Detailed Explanation (Multiline)
read_multiline "3. Detailed Explanation (supports line breaks)?" "detailed_explanation" "$delimiter"
echo ""

# 4. Use Case
read_multiline "4. What is the use case (e.g., personal workflow, agent integration scenario)?" "use_case" "$delimiter"
echo ""

# 5. Agent's Personal Context / Persona
read_multiline "5. Agent's personal notes, persona, or guidelines?" "agent_personal" "$delimiter"
echo ""

# 6. Gather context files
echo "6. Which files should the AI look at?"
echo "   (e.g., 'src/middleware.js, components/Navbar.tsx')"
read -p "> " context_files
echo ""

# 7. Gather constraints
echo "7. Any specific constraints, libraries, or edge cases?"
echo "   (e.g., 'Use Tailwind only', 'Don't change DB schema')"
read -p "> " constraints
echo ""

# 8. Expected delivery time (default: 1 hour)
echo "8. Expected delivery timeline?"
echo "   (e.g., '30 min', '2 hours', or press Enter for '1 hour')"
read -p "> " delivery_time
delivery_time=${delivery_time:-"1 hour"}
echo ""

# 9. Max iterations (default: 3)
echo "9. Maximum iterations for this task?"
echo "   (Enter number, or press Enter for '3')"
read -p "> " max_iterations
max_iterations=${max_iterations:-"3"}
echo ""

# 10. Token budget warning threshold (default: 80%)
echo "10. Token budget warning threshold? (%)"
echo "    (Press Enter for '80')"
read -p "> " token_threshold
token_threshold=${token_threshold:-"80"}
echo ""

# Generate timestamp and directory path
timestamp=$(date +"%Y%m%d_%H%M%S")
date_dir=$(date +"%Y-%m-%d")
target_dir="local/ask-gpt/${date_dir}"
filename="${target_dir}/ask-gpt-${timestamp}.txt"

# Ensure the target directory exists
mkdir -p "$target_dir"

# Create the file with the optimized template
cat > "$filename" <<EOF
# ⚡ TASK OBJECTIVE
${task_desc:-"N/A"}

# 📝 DETAILED EXPLANATION
${detailed_explanation:-"N/A"}

# 🎯 USE CASE
${use_case:-"N/A"}

# 🤖 AGENT'S PERSONAL / CONTEXT
${agent_personal:-"N/A"}

# 📁 CONTEXT FILES
${context_files:-"N/A"}

# 🔒 CONSTRAINTS
${constraints:-"Follow standard best practices."}

# ⏱️ DELIVERY EXPECTATIONS
- **Timeline:** $delivery_time
- **Max Iterations:** $max_iterations
- **Token Warning Threshold:** ${token_threshold}%

---

# 🛡️ RULES OF ENGAGEMENT

You are a **Senior Staff Engineer** focused on efficient token usage.

## PHASE 0: GRAPHIFY CHECK (MANDATORY)
**BEFORE YOU PROCEED:**
1. Use Graphify to map dependencies and relationships
2. Run \`graphify --analyze\` on the context files
3. Generate a dependency graph to identify:
   - Core vs. peripheral components
   - Potential ripple effects
   - Reusable patterns
4. If Graphify reveals complexity > 70%, request permission to scope down

**Graphify Check Response Format:**
\`\`\`
📊 GRAPHIFY ANALYSIS:
- Total Nodes: [number]
- Critical Path: [components]
- Complexity Score: [0-100]
- Recommendation: [Proceed/Scope Down/Request Clarification]
\`\`\`

## PHASE 1: PLANNING (Zero-Code)
1. **Context Check:** Analyze task against provided files
2. **Clarification Limit:** Maximum 3 clarifying questions if ambiguous
3. **Plan Structure:** Outline step-by-step architectural plan as Markdown checklist
4. **Token Guard:** Keep total response under 1000 tokens

## PHASE 2: CODE EXECUTION (Post-Approval)
1. **Iteration Limit:** Maximum $max_iterations cycles
2. **Progress Check:** After each iteration, provide:
   - Files modified
   - Lines changed
   - Remaining token budget (${token_threshold}% warning)
3. **Delivery Scope:** Must fit within $delivery_time timeframe

## ⚠️ TOKEN PROTECTION PROTOCOL
- If response exceeds 1000 tokens, summarize and ask for direction
- Stop if token budget drops below ${token_threshold}%
- Request checkpoint save after each major step

---

# 📋 REQUIRED RESPONSE FORMAT

## Step 1: Graphify Check
[Run graphify and show analysis]

## Step 2: Plan
[If enough context, provide checklist with estimated times per step]

## Step 3: Token Status
- Tokens used: [number]
- Tokens remaining: [number]
- Budget status: [OK / WARNING / CRITICAL]

---

**End your response exactly with:**
**"Plan ready. Type 'APPROVE' to authorize coding, 'GRAPHIFY' to re-run analysis, or request changes."**
EOF

# Confirmation
echo ""
echo "✅ Token-optimized prompt generated!"
echo "📄 File: $filename"
echo ""
echo "🔒 Protection Summary:"
echo "   - ⚡ Objective: $task_desc"
echo "   - 🛑 Multiline Delimiter: $delimiter"
echo "   - ⏱️ Expected delivery: $delivery_time"
echo "   - 🔄 Max iterations: $max_iterations"
echo "   - 🚨 Token warning: ${token_threshold}%"
echo "   - 📊 Graphify analysis: MANDATORY"
echo ""
echo "💡 Tip: The AI will run Graphify first to minimize token waste."