#!/usr/bin/env bash
set -e

# Check if glab is installed
if ! command -v glab &> /dev/null; then
    echo "Error: GitLab CLI (glab) is not installed."
    echo "Please install it first:"
    echo "  brew install glab        # macOS"
    echo "  apt install glab         # Debian/Ubuntu"
    echo "  yum install glab         # RHEL/Fedora"
    echo "Or see: https://gitlab.com/gitlab-org/cli#installation"
    exit 1
fi

# Get current branch
BRANCH=$(git branch --show-current)
echo "Current branch: $BRANCH"

# Get default branch (usually main or master)
# Try to get from git symbolic-ref first, fallback to glab
if BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'); then
    echo "Base branch detected via git: $BASE"
else
    # Use glab to get the default branch
    BASE=$(glab repo view --json defaultBranch --jq '.defaultBranch' 2>/dev/null || echo "main")
    echo "Base branch detected via glab: $BASE"
fi

# Prevent running on protected branch
if [ "$BRANCH" = "$BASE" ]; then
    echo "Error: You are on the protected branch '$BASE'."
    echo "Create a feature branch before running this script."
    exit 1
fi

# Check if working tree is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree is not clean."
    echo "Please commit or stash your changes before running this script."
    git status --short
    exit 1
fi

echo "Pushing branch..."
git push origin "$BRANCH"

echo "Checking for existing merge request..."
# Check if MR already exists for this branch
MR=$(glab mr list --source-branch="$BRANCH" --json iid --jq '.[0].iid' 2>/dev/null || true)

if [ -z "$MR" ] || [ "$MR" = "null" ]; then
    echo "Creating merge request..."
    # Get the first commit message to use as title
    TITLE=$(git log --oneline -1 --format="%s" 2>/dev/null || echo "Merge $BRANCH into $BASE")
    # Create MR non-interactively
    # Temporarily disable set -e to handle potential failure
    set +e
    glab mr create --source-branch="$BRANCH" --target-branch="$BASE" --title="$TITLE" --description="Automated merge request" --yes
    CREATE_STATUS=$?
    set -e
    
    # Check if creation was successful or failed due to existing MR
    if [ $CREATE_STATUS -eq 0 ]; then
        # Get the MR number after successful creation
        MR=$(glab mr list --source-branch="$BRANCH" --json iid --jq '.[0].iid' 2>/dev/null)
        if [ -z "$MR" ] || [ "$MR" = "null" ]; then
            echo "Error: Failed to retrieve MR number after creation."
            exit 1
        fi
    else
        echo "MR creation may have failed (possibly already exists). Trying to retrieve MR number..."
        # Try to get the MR number again
        MR=$(glab mr list --source-branch="$BRANCH" --json iid --jq '.[0].iid' 2>/dev/null)
        if [ -z "$MR" ] || [ "$MR" = "null" ]; then
            echo "Error: Failed to create or retrieve MR number."
            exit 1
        else
            echo "Found existing MR: !$MR"
        fi
    fi
else
    echo "Existing MR found: !$MR"
fi

echo "Merging MR..."
# Merge the MR with squash and delete source branch
glab mr merge "$MR" --squash --delete-source-branch

echo "Updating local repository..."
# Switch to base branch and pull latest changes
git checkout "$BASE"
git pull origin "$BASE"

echo "Done."
