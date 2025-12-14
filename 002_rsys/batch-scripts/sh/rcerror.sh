#!/bin/bash

# Array of files to audit (using absolute paths for safety)
RC_FILES=(
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.commonrc"
)

# --- Offending Patterns Explained ---
# Original patterns (for simple redirection/spacing errors) are kept for completeness.
PATTERN_1='[>][>]*[[:space:]]*2[[:space:]]*$'
PATTERN_2='[[:space:]]2[[:space:]]*[>][>]*[[:space:]]*[^[:space:]]'
PATTERN_3='[[:space:]]2[[:space:]]*&'
PATTERN_4='[[:space:]]2$'

# Pattern 5: NEW PATTERN to catch the nested single-quote error in aliases.
# Looks for an unescaped single quote (') inside the main alias definition ('...').
# Specifically targets lines starting with 'alias' that contain an odd number of quotes inside.
PATTERN_5='^alias[^=]*='

# Combine all patterns into a single regex (requires extended regex `-E`)
ALL_PATTERNS="$PATTERN_1|$PATTERN_2|$PATTERN_3|$PATTERN_4"


echo "--- Starting Configuration File Audit ---"
echo "Searching for patterns that may cause a file named '2' to be created."
echo "----------------------------------------"

FOUND_ERROR=0

for RC_FILE in "${RC_FILES[@]}"; do
    if [ -f "$RC_FILE" ]; then
        echo "## Checking: $RC_FILE"

        # 1. Check for standard redirection errors (the original patterns)
        MATCHES=$(grep -E -n -i "$ALL_PATTERNS" "$RC_FILE" | grep -v '^[[:space:]]*#')

        # 2. Check for the specific nested quoting error (the dcrm type issue)
        # This requires counting quotes, which grep cannot do perfectly, so we use awk for analysis.
        QUOTING_ERRORS=$(awk -F "'" '/^alias/ && NF>2 && (NF%2==0) {print NR ":" $0}' "$RC_FILE")

        # Note: The awk logic above is a heuristic. A more robust check for your specific issue
        # is a targeted grep for the known bad structure:
        QUOTING_ERRORS_DC=$(grep -n -E -i "^alias[^=]*='[^']*'\w*'" "$RC_FILE" | grep -v '^[[:space:]]*#')

        ALL_ERRORS=""
        if [ -n "$MATCHES" ]; then
            ALL_ERRORS="${ALL_ERRORS}Standard Redirection Issues:\n${MATCHES}\n"
        fi
        if [ -n "$QUOTING_ERRORS_DC" ]; then
             ALL_ERRORS="${ALL_ERRORS}Quoting/Nested Command Issues (e.g., awk):\n${QUOTING_ERRORS_DC}\n"
        fi

        if [ -n "$ALL_ERRORS" ]; then
            echo "🚨 POTENTIAL OFFENDING ROWS FOUND:"
            echo -e "$ALL_ERRORS"
            FOUND_ERROR=1
        else
            echo "✅ No common offending patterns found."
        fi
        echo "---"
    else
        echo "File not found: $RC_FILE (Skipping)"
    fi
done

if [ $FOUND_ERROR -eq 1 ]; then
    echo "ACTION REQUIRED: Examine the lines above. The most likely issues are:"
    echo "1. **Trailing Space:** A space before the final background '&' (fix: remove the space)."
    echo "2. **Nested Quotes:** Using single quotes inside a command that is wrapped in single quotes (fix: change inner quotes to double quotes and escape \$). For example:"
    echo "   Correct: alias dcrm='dcl | awk \"NR > 2 {print \\$NF}\" | xargs ...'"
else
    echo "Audit Complete. No common pattern errors detected in the specified files."
fi