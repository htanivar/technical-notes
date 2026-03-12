#!/usr/bin/env bash

set -e

BRANCH=$(git branch --show-current)

git push -u origin "$BRANCH"

PR_URL=$(gh pr create --fill --head "$BRANCH")

PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]\+$')

gh pr merge "$PR_NUMBER" --squash --delete-branch --auto