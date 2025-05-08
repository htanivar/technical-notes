#!/bin/bash

# Ensure that both branches are up-to-date
git fetch origin

# Define the branch names
DEVELOP_BRANCH="develop"
RELEASE_BRANCH="release/21-00-00"  # Replace with your release branch version

# Checkout the develop branch and pull latest changes
git checkout $DEVELOP_BRANCH
git pull origin $DEVELOP_BRANCH

# Checkout the release branch and pull latest changes
git checkout $RELEASE_BRANCH
git pull origin $RELEASE_BRANCH

# Compare the release branch to the develop branch and list the commits unique to the release branch
echo "Listing commits that exist in $RELEASE_BRANCH but not in $DEVELOP_BRANCH:"
git log $DEVELOP_BRANCH..$RELEASE_BRANCH --oneline

# Alternative: If you want a more detailed view of the commits
# git log $DEVELOP_BRANCH..$RELEASE_BRANCH --stat --oneline
