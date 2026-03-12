#!/usr/bin/env bash
set -e

BRANCH=$(git branch --show-current)
echo "Current branch: $BRANCH"

BASE=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
echo "Base branch detected: $BASE"

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