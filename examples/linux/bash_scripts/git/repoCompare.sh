#!/bin/bash

# Variables for SSH URLs of the repositories and branches
SOURCE_REPO_SSH_URL="git@github.com:user/source-repo.git"
TARGET_REPO_SSH_URL="git@github.com:user/target-repo.git"

SOURCE_BRANCH="main"
TARGET_BRANCH="main"

# Directories where the repositories will be cloned
SOURCE_DIR="source-repo"
TARGET_DIR="target-repo"

# Reports
CHANGED_FILES_REPORT="changed_files_report.txt"
SUMMARY_REPORT="summary_report.txt"

# Function to clone the repository and checkout the desired branch
clone_and_checkout() {
    local repo_url=$1
    local clone_dir=$2
    local branch=$3

    git clone "$repo_url" "$clone_dir"
    cd "$clone_dir" || exit
    git checkout "$branch"

    # Check if the branch has an upstream tracking branch
    if ! git rev-parse --abbrev-ref --symbolic-full-name "@{u}" &>/dev/null; then
        echo "Warning: No upstream tracking branch for $branch in $clone_dir. Ignoring updates."
        cd ..
        return 1
    fi

    # Pull the latest changes
    git pull
    cd ..
    return 0
}

# Clone and update the source repository
clone_and_checkout "$SOURCE_REPO_SSH_URL" "$SOURCE_DIR" "$SOURCE_BRANCH"

# Clone and update the target repository
clone_and_checkout "$TARGET_REPO_SSH_URL" "$TARGET_DIR" "$TARGET_BRANCH"

# Compare the repositories and generate reports
echo "Comparing repositories..."
diff -qr "$SOURCE_DIR" "$TARGET_DIR" | grep "differ" > diff_output.txt

# Generate the changed files report
awk '{print $2}' diff_output.txt > "$CHANGED_FILES_REPORT"

# Generate the summary report
echo "Summarizing changes..."
rm -f "$SUMMARY_REPORT"
while IFS= read -r line; do
    file1=$(echo "$line" | awk '{print $2}')
    file2=$(echo "$line" | awk '{print $4}')
    echo "Changes in $file1 and $file2:" >> "$SUMMARY_REPORT"
    diff "$file1" "$file2" >> "$SUMMARY_REPORT"
    echo -e "\n" >> "$SUMMARY_REPORT"
done < diff_output.txt

# Clean up the diff output
rm diff_output.txt

echo "Reports generated:"
echo "1. List of changed files: $CHANGED_FILES_REPORT"
echo "2. Summary of changes: $SUMMARY_REPORT"
