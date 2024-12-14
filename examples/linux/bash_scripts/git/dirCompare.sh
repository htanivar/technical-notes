#!/bin/bash

# Directories to compare
DIR1="$1"
DIR2="$2"

# Reports
CHANGED_FILES_REPORT="changed_files_report.txt"
UNCHANGED_FILES_REPORT="unchanged_files_report.txt"
SUMMARY_REPORT="summary_report.txt"

# Ensure both directories are provided
if [ -z "$DIR1" ] || [ -z "$DIR2" ]; then
  echo "Usage: $0 <directory1> <directory2>"
  exit 1
fi

# Check if directories exist
if [ ! -d "$DIR1" ]; then
  echo "Directory $DIR1 does not exist."
  exit 1
fi

if [ ! -d "$DIR2" ]; then
  echo "Directory $DIR2 does not exist."
  exit 1
fi

# Compare the directories
echo "Comparing directories..."
diff -qr "$DIR1" "$DIR2" > diff_output.txt

# Generate reports
echo "Generating reports..."

# Files that are different
grep "differ" diff_output.txt | awk '{print $2}' > "$CHANGED_FILES_REPORT"

# Files that are identical
grep "are identical" diff_output.txt | awk '{print $2}' > "$UNCHANGED_FILES_REPORT"

# Summary of differences
rm -f "$SUMMARY_REPORT"
while IFS= read -r line; do
    file1=$(echo "$line" | awk '{print $2}')
    file2=$(echo "$line" | awk '{print $4}')
    echo "Changes in $file1 and $file2:" >> "$SUMMARY_REPORT"
    diff "$file1" "$file2" >> "$SUMMARY_REPORT"
    echo -e "\n" >> "$SUMMARY_REPORT"
done < <(grep "differ" diff_output.txt)

# Clean up the diff output
rm diff_output.txt

echo "Reports generated:"
echo "1. List of changed files: $CHANGED_FILES_REPORT"
echo "2. List of unchanged files: $UNCHANGED_FILES_REPORT"
echo "3. Summary of changes: $SUMMARY_REPORT"
