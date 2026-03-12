#!/usr/bin/env bash
set -e

BRANCH=$(git branch --show-current)

git push -u origin "$BRANCH"

gh pr create --fill --head "$BRANCH"

gh pr merge --auto --squash --delete-branch