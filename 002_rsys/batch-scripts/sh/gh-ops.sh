#!/usr/bin/env bash
set -e

BRANCH=$(git branch --show-current)
BASE=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')

git push -u origin "$BRANCH"

gh pr create \
  --base "$BASE" \
  --head "$BRANCH" \
  --title "$BRANCH" \
  --body "auto pr" \
  --repo "$(gh repo view --json nameWithOwner --jq '.nameWithOwner')"

gh pr merge \
  --squash \
  --auto \
  --delete-branch \
  "$BRANCH"