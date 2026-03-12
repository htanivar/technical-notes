#!/usr/bin/env bash
set -e

BRANCH=$(git branch --show-current)
echo "Current branch: $BRANCH"

BASE=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
echo "Base branch detected: $BASE"

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

echo "Checking PR..."
PR=$(gh pr list --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null || true)

if [ -z "$PR" ]; then
    echo "Creating PR..."
    gh pr create --base "$BASE" --head "$BRANCH" --fill
else
    echo "Existing PR: #$PR"
fi

echo "Merging PR..."
gh pr merge "$BRANCH" --squash --delete-branch --auto

echo "Done."