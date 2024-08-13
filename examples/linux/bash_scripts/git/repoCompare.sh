#!/bin/bash

# Variables for SSH URLs of the repositories
REPO1_SSH_URL="git@github.com:user/repo1.git"
REPO2_SSH_URL="git@github.com:user/repo2.git"

# Directories where the repositories will be cloned
REPO1_DIR="repo1"
REPO2_DIR="repo2"

# Reports
UNCHANGED_FILES_REPORT="unchanged_files_report.txt"
CHANGED_FILES_REPORT="changed_files_report.txt"

# Clone the first repository
git clone "$REPO1_SSH_URL" "$REPO1_DIR"

# Clone the second repository
git clone "$REPO2_SSH_URL" "$REPO2_DIR"

# Compare the directories
echo "Comparing repositories..."
diff -rq "$REPO1_DIR" "$REPO2_DIR" > diff_output.txt

# Generate reports
echo "Generating reports..."

# Files without changes
grep "Files .* are identical" diff_output.txt | awk '{print $2}' > "$UNCHANGED_FILES_REPORT"

# Summarize the changes in different files
grep "Files .* differ" diff_output.txt | awk '{print $2 " and " $4}' > "$CHANGED_FILES_REPORT"

# Clean up the diff output
rm diff_output.txt

echo "Reports generated:"
echo "1. Files without changes: $UNCHANGED_FILES_REPORT"
echo "2. Summary of changes: $CHANGED_FILES_REPORT"
