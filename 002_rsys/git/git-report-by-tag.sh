#!/usr/bin/env bash

TAG1="v1.0.0"
TAG2="v2.0.0"
FOLDER1="frontend"
FOLDER2="backend"
OUTPUT_FILE="tag_diff_report.md"

cat << EOF > "$OUTPUT_FILE"
# Git Tag Comparison Report: \`$TAG1\` → \`$TAG2\`

**Generated:** \$(date +%Y-%m-%d)  
**Comparison Range:** \`$TAG1\`...\`$TAG2\`

---

## 📁 Changed Files in \`$FOLDER1/\`

\`\`\`
\$(git diff --stat "$TAG1" "$TAG2" -- "$FOLDER1")
\`\`\`

### File Status List
\`\`\`
\$(git diff --name-status "$TAG1" "$TAG2" -- "$FOLDER1")
\`\`\`

---

## 📁 Changed Files in \`$FOLDER2/\`

\`\`\`
\$(git diff --stat "$TAG1" "$TAG2" -- "$FOLDER2")
\`\`\`

### File Status List
\`\`\`
\$(git diff --name-status "$TAG1" "$TAG2" -- "$FOLDER2")
\`\`\`

---

## 📜 Commits Introduced

\`\`\`
\$(git log --oneline "$TAG1..$TAG2")
\`\`\`
EOF

echo "Report generated successfully at: $OUTPUT_FILE"
