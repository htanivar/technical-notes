#!/usr/bin/env bash
set -e

# 1. Environment & Branch Setup
if ! command -v glab &> /dev/null; then
    echo "Error: GitLab CLI (glab) is not installed."
    exit 1
fi

# Store the branch we are currently working on
FEATURE_BRANCH=$(git branch --show-current)

# Determine the default/base branch
if BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'); then
    echo "Detected base branch: $BASE"
else
    BASE=$(glab repo view --json defaultBranch --jq '.defaultBranch' 2>/dev/null || echo "main")
fi

# Guardrail: Don't run this on the base branch itself
if [ "$FEATURE_BRANCH" = "$BASE" ]; then
    echo "Error: You are already on the base branch ($BASE). Please switch to a feature branch."
    exit 1
fi

# 2. Logic to Find and Increment RBOT ID
echo "🔍 Searching for the highest RBOT ticket number..."
HIGHEST_NUM=$(git log --all --format="%s" | grep -oP 'RBOT-\K[0-9]+' | sort -rn | head -n 1 || echo "")

if [ -z "$HIGHEST_NUM" ] || [ "$HIGHEST_NUM" -lt 1030 ]; then
    NEXT_NUM=1030
    echo "⚠️ Starting sequence at $NEXT_NUM (Historical highest: $HIGHEST_NUM)"
else
    NEXT_NUM=$((HIGHEST_NUM + 1))
    echo "✅ Highest found was RBOT-$HIGHEST_NUM. Incrementing to RBOT-$NEXT_NUM"
fi

NEW_TICKET="RBOT-$NEXT_NUM"

# 3. Handle Local Changes (Automatic Commit/Amend)
if [ -n "$(git status --porcelain)" ]; then
    echo "📦 Committing changes with $NEW_TICKET..."
    git add .
    git commit -m "$NEW_TICKET: Automated update"
else
    CURRENT_MSG=$(git log -1 --format="%s")
    if [[ ! $CURRENT_MSG =~ RBOT-[0-9]+ ]]; then
        echo "📝 Amending last commit to include $NEW_TICKET..."
        git commit --amend -m "$NEW_TICKET: $CURRENT_MSG" --no-edit
    fi
fi

# 4. Push and Create MR
echo "Pushing $FEATURE_BRANCH to origin (forced)..."
git push origin "$FEATURE_BRANCH" -f

echo "Handling Merge Request..."
TITLE=$(git log --oneline -1 --format="%s")

CREATE_OUTPUT=$(glab mr create \
    --source-branch="$FEATURE_BRANCH" \
    --target-branch="$BASE" \
    --title="$TITLE" \
    --description="Automated sync for $NEW_TICKET" \
    --yes 2>&1) || true

MR=$(echo "$CREATE_OUTPUT" | grep -oP '!\K[0-9]+' | head -n 1)

if [ -z "$MR" ] || [ "$MR" = "null" ]; then
    echo "Wait... Syncing with GitLab API..."
    sleep 2
    MR=$(glab mr list --source-branch="$FEATURE_BRANCH" --json iid --jq '.[0].iid' 2>/dev/null || echo "")
fi

if [ -z "$MR" ] || [ "$MR" = "null" ]; then
    echo "❌ Error: Could not identify MR ID."
    exit 1
fi

# 5. Automated Merge
echo "Merging MR !$MR..."
glab mr merge "$MR" \
    --yes \
    --squash \
    --message "$TITLE" \
    --remove-source-branch \
    --when-pipeline-succeeds

# 6. Final Local Cleanup & Reset
echo "🔄 Returning to default branch: $BASE"
git checkout "$BASE"

echo "📥 Pulling latest changes..."
git pull origin "$BASE"

echo "🧹 Deleting local feature branch: $FEATURE_BRANCH"
# Using -D to force delete since it was merged via squash (Git might not recognize it as merged)
git branch -D "$FEATURE_BRANCH"

echo "✨ Done! Processed $NEW_TICKET. You are now on $BASE."