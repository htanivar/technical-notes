#!/bin/bash

SOURCE=$1
TARGET=$2

if [ -z "$SOURCE" ] || [ -z "$TARGET" ]; then
    echo "Usage: $0 <source_branch> <target_branch>"
    exit 1
fi

# Ensure we are in a git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: You must run this script inside a Git repository."
    exit 1
fi

REPORT_FILE="comparison_report_${SOURCE//\//-}_to_${TARGET//\//-}.md"

# 1. Capture Commit Logs
COMMIT_LOGS=$(git log "$TARGET..$SOURCE" --oneline --graph --decorate)
[ -z "$COMMIT_LOGS" ] && COMMIT_LOGS="No unique commits found. Branches are synchronized."

# 2. Capture Content Differences
FILES_CHANGED=$(git diff --name-status "$TARGET" "$SOURCE")
if [ -z "$FILES_CHANGED" ]; then
    FILES_STATUS="SUCCESS: Code content is identical."
    FILES_LIST="None"
else
    FILES_STATUS="WARNING: Code content differs!"
    FILES_LIST="$FILES_CHANGED"
fi

# 3. Verify Merge History
if git merge-base --is-ancestor "$SOURCE" "$TARGET"; then
    HISTORY_STATUS="SUCCESS: All history from $SOURCE is fully merged into $TARGET."
    ANCESTOR_INFO="N/A (Fully Merged)"
else
    HISTORY_STATUS="FAILURE: $SOURCE is NOT fully merged into $TARGET (History Gap)."
    BASE=$(git merge-base "$SOURCE" "$TARGET")
    ANCESTOR_INFO="Common Ancestor: $BASE"
fi

# Generate the .md file
cat << EOF > "$REPORT_FILE"
# Branch Comparison Report
**Source:** \`$SOURCE\`
**Target:** \`$TARGET\`
**Generated on:** $(date)

---

## 1. Commit History Logs
The following commits exist in **$SOURCE** but are missing from **$TARGET**:

\`\`\`text
$COMMIT_LOGS
\`\`\`

---

## 2. File Content Differences
**Status:** $FILES_STATUS

The following files have inconsistent content between the two branches:

\`\`\`text
$FILES_LIST
\`\`\`

---

## 3. Merge Verification Status
**Status:** $HISTORY_STATUS

**Details:**
* $ANCESTOR_INFO
* Note: If status is FAILURE, a merge or rebase is required to sync history.

EOF

echo "-------------------------------------------------------"
echo "Report generated: $REPORT_FILE"
echo "-------------------------------------------------------"