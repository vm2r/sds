#!/usr/bin/env bash

# Define the target primary branch
BRANCH_NAME="main"

# Create orphan branch to disconnect from history
git checkout --orphan temp_branch

# Stage all current files
git add -A

# Create the new root commit
git commit -m "Initial commit"

# Delete the local reference to the old primary branch
git branch -D $BRANCH_NAME

# Rename the orphan branch to the primary branch name
git branch -m $BRANCH_NAME

# Force push the new state to the remote
git push -f origin $BRANCH_NAME

# Delete all other remote branches except the new primary branch
# This assumes 'origin' is your remote name
git push origin --delete $(git branch -r | grep 'origin/' | grep -v "origin/$BRANCH_NAME" | sed 's/origin\///')

# Prune local tracking branches
git remote prune origin