#!/bin/bash

# Function to display progress and log
log_progress() {
    echo "$1"
    echo "$(date): $1" >> $LOG_FILE
}

# Ask for source (release) and target (develop) branches
read -p "Enter the release branch (e.g., release/21-00-00): " RELEASE_BRANCH
read -p "Enter the target branch (usually 'develop'): " DEVELOP_BRANCH

# Validate input for branches
if [ -z "$RELEASE_BRANCH" ] || [ -z "$DEVELOP_BRANCH" ]; then
    echo "Error: Both source and target branches must be provided."
    exit 1
fi

log_progress "Starting comparison between $RELEASE_BRANCH and $DEVELOP_BRANCH..."

# Ensure both branches exist locally
if ! git show-ref --verify --quiet refs/heads/"$RELEASE_BRANCH"; then
    echo "Error: Release branch '$RELEASE_BRANCH' does not exist."
    exit 1
fi

if ! git show-ref --verify --quiet refs/heads/"$DEVELOP_BRANCH"; then
    echo "Error: Target branch '$DEVELOP_BRANCH' does not exist."
    exit 1
fi

# Fetch the latest changes for both branches
log_progress "Fetching latest changes from the remote repository..."
git fetch origin

# Create a log file name
LOG_FILE="local/$(echo $RELEASE_BRANCH | sed 's/\//_/g')CompareWith$(echo $DEVELOP_BRANCH | sed 's/\//_/g').log"

# Checkout to the release branch and pull the latest changes
log_progress "Checking out the $RELEASE_BRANCH branch..."
git checkout "$RELEASE_BRANCH" &>> $LOG_FILE
git pull origin "$RELEASE_BRANCH" &>> $LOG_FILE

# Checkout to the develop branch and pull the latest changes
log_progress "Checking out the $DEVELOP_BRANCH branch..."
git checkout "$DEVELOP_BRANCH" &>> $LOG_FILE
git pull origin "$DEVELOP_BRANCH" &>> $LOG_FILE

# List the commits that are unique to the release branch
log_progress "Listing commits that exist in $RELEASE_BRANCH but not in $DEVELOP_BRANCH..."
git log "$DEVELOP_BRANCH..$RELEASE_BRANCH" --oneline &>> $LOG_FILE
log_progress "Commits listed successfully."

# List all the unique files changed in the release branch
log_progress "Listing affected files in $RELEASE_BRANCH that are not in $DEVELOP_BRANCH..."

git diff --name-only "$DEVELOP_BRANCH..$RELEASE_BRANCH" &>> $LOG_FILE
log_progress "Files listed successfully."

# Success message
log_progress "Comparison between $RELEASE_BRANCH and $DEVELOP_BRANCH completed."
echo "The log has been saved to $LOG_FILE"
