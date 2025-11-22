#!/bin/bash

# ====
# Git Aliases & Functions - Enhanced Collection
# ====

# ----
# Basic Git Operations
# ----

# Git Status - Show working tree status
alias gs='git status'

# Git Status Short - Compact status output
alias gss='git status -s'

# Git Add All - Stage all changes
alias gaa='git add .'

# Git Add Interactive - Interactive staging
alias gai='git add -i'

# Git Pull - Fetch and merge from remote
alias gpl='git pull'

# Git Push - Push to remote
alias gps='git push'

# Git Push Force (with lease) - Safer force push
alias gpsf='git push --force-with-lease'

# Git Fetch - Download objects and refs from remote
alias gf='git fetch'

# Git Fetch All - Fetch from all remotes
alias gfa='git fetch --all'

# ----
# Logging & History
# ----

# Git Log Oneline - Compact log view
alias gl='git log --oneline'

# Git Log Graph - Visual branch history
alias glg='git log --graph --oneline --decorate --all'

# Git Log Pretty - Detailed formatted log
alias glp='git log --pretty=format:"%h %ad %an %s" --date=short'

# Git Log Stats - Show file change statistics
alias gls='git log --stat'

# Git Log No Merges - Exclude merge commits
alias glnm='git log --no-merges --oneline'

# ----
# Branch Management
# ----

# Git Branch All - List all branches (local + remote)
alias gbla='git branch -a'

# Git Branch Local - List local branches
alias gbl='git branch'

# Git Branch Remote - List remote branches
alias gbr='git branch -r'

# Git Branch Cleanup - Delete merged branches
alias gbc='git branch --merged | grep -v "*" | grep -v "main\|master\|develop" | xargs -n 1 git branch -d'

# Git Switch - Modern branch switching
alias gsw='git switch'

# Git Switch Create - Create and switch to new branch
alias gswc='git switch -c'

# ----
# Diff & Comparison
# ----

# Git Diff - Show unstaged changes
alias gd='git diff'

# Git Diff Staged - Show staged changes
alias gds='git diff --staged'

# Git Diff Name Only - Show only changed file names
alias gdn='git diff --name-only'

# Git Diff Between Branches - Compare two branches
alias gdb='git diff --name-status'

# ----
# Stash Operations
# ----

# Git Stash List - Show all stashes
alias gsl='git stash list'

# Git Stash Pop - Apply and remove latest stash
alias gsp='git stash pop'

# Git Stash Drop - Delete a stash
alias gsd='git stash drop'

# Git Stash Clear - Delete all stashes
alias gsc='git stash clear'

# ----
# Reset & Cleanup
# ----

# Git Reset Hard - Reset to HEAD (DANGER: loses changes)
alias grh='git reset --hard'

# Git Reset Soft - Reset keeping changes staged
alias grs='git reset --soft'

# Git Clean - Remove untracked files (dry run)
alias gcl='git clean -n'

# Git Clean Force - Remove untracked files (DANGER)
alias gclf='git clean -fd'

# ----
# Remote Operations
# ----

# Git Remote - Show remotes
alias gr='git remote -v'

# Git Remote Update - Update remote refs
alias gru='git remote update'

# ----
# Advanced Functions
# ----

# Git Checkout - Switch branches or restore files
gc() {
  if [ -z "$1" ]; then
    read -p "Enter branch name: " branch_name
    git checkout "$branch_name"
  else
    git checkout "$1"
  fi
}

# Git Checkout New Branch - Create and switch to new branch
gcnb() {
  if [ -z "$1" ]; then
    read -p "Enter new branch name: " branch_name
    git checkout -b "$branch_name"
  else
    git checkout -b "$1"
  fi
}

 Git Commit - Commit with message
gcm() {
  if [ -z "$1" ]; then
    read -p "Enter commit message: " commit_message
    git commit -m "$commit_message"
  else
    git commit -m "$1"
  fi
}

# Git Commit Amend - Amend last commit
gcma() {
  if [ -z "$1" ]; then
    git commit --amend --no-edit
  else
    git commit --amend -m "$1"
  fi
}

# Git Stash Save - Save changes to stash with message
gss() {
  if [ -z "$1" ]; then
    read -p "Enter stash message: " stash_name
    git stash push -m "$stash_name"
  else
    git stash push -m "$1"
  fi
}

# Git Stash Apply - Apply specific stash
gsa() {
  if [ -z "$1" ]; then
    # No argument, apply the most recent stash
    git stash apply stash@{0}
  elif [[ "$1" =~ ^[0-9]+$ ]]; then
    # If argument is a valid number, try to apply the specified stash
    if git stash list | grep -q "stash@{$1}"; then
      git stash apply "stash@{$1}"
    else
      echo "Error: Stash index stash@{$1} does not exist."
    fi
  else
    # Invalid argument
    echo "Error: Invalid input. Please provide a valid stash index (e.g., 0, 1, 2)."
  fi
}

# Git Nuclear Reset - Reset branch to match remote exactly (DANGER)
gnuke() {
  local branch=${1:-$(git branch --show-current)}
  echo "WARNING: This will destroy ALL local changes on branch '$branch'"
  read -p "Are you sure? (y/N): " confirm
  if [[ $confirm =~ ^[Yy]$ ]]; then
    git fetch origin
    git reset --hard "origin/$branch"
    git clean -fd
    echo "Branch '$branch' reset to match remote."
  else
    echo "Operation cancelled."
  fi
}

# Git Compare Branches - Show commits in branch1 but not in branch2
gcompare() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: gcompare <branch1> <branch2>"
    echo "Shows commits in branch1 but not in branch2"
    return 1
  fi
  echo "Commits in $1 but not in $2:"
  git log --no-merges --oneline "$2..$1"
}

# Git Files Changed - Show files changed between branches
gfiles() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: gfiles <branch1> <branch2>"
    echo "Shows files that differ between branches"
    return 1
  fi
  git diff --name-status "$1...$2"
}

# Git Backup Branch - Create backup of current branch
gbackup() {
  local current_branch=$(git branch --show-current)
  local backup_name="backup/${current_branch}-$(date +%F-%H%M%S)"
  git branch "$backup_name"
  echo "Created backup branch: $backup_name"
}

# Git Find Commit - Search for commits by message
gfind() {
  if [ -z "$1" ]; then
    read -p "Enter search term: " search_term
  else
    search_term="$1"
  fi
  git log --grep="$search_term" --oneline
}

# Git Undo Last Commit - Undo last commit but keep changes
gundo() {
  git reset --soft HEAD~1
  echo "Last commit undone. Changes are still staged."
}

# Git Quick Commit - Add all and commit in one go
gqc() {
  if [ -z "$1" ]; then
    read -p "Enter commit message: " commit_message
  else
    commit_message="$1"
  fi
  git add . && git commit -m "$commit_message"
}

# Git Sync - Fetch, pull, and push current branch
gsync() {
  local current_branch=$(git branch --show-current)
  echo "Syncing branch: $current_branch"
  git fetch origin
  git pull origin "$current_branch"
  git push origin "$current_branch"
}

# ----
# Utility Functions
# ----

# Git Current Branch - Show current branch name
gcurrent() {
  git branch --show-current
}

# Git Root - Go to git repository root
groot() {
  cd "$(git rev-parse --show-toplevel)"
}

# Git Size - Show repository size
gsize() {
  git count-objects -vH
}

# ----
# Usage Instructions
# ----

# Show all available git aliases
ghelp() {
  echo "=== Git Aliases & Functions ==="
  echo ""
  echo "Basic Operations:"
  echo "  gs     - git status"
  echo "  gss    - git status -s"
  echo "  gaa    - git add ."
  echo "  gpl    - git pull"
  echo "  gps    - git push"
  echo "  gf     - git fetch"
  echo ""
  echo "Logging:"
  echo "  gl     - git log --oneline"
  echo "  glg    - git log --graph"
  echo "  glp    - git log pretty format"
  echo ""
  echo "Branches:"
  echo "  gbl    - list local branches"
  echo "  gbla   - list all branches"
  echo "  gbc    - cleanup merged branches"
  echo "  gsw    - git switch"
  echo ""
  echo "Functions:"
  echo "  gcm    - commit with message"
  echo "  gcnb   - create new branch"
  echo "  gnuke  - reset branch to remote (DANGER)"
  echo "  gcompare - compare branches"
  echo "  gbackup - backup current branch"
  echo ""
  echo "Type 'ghelp' to see this help again"
}

echo "Git aliases loaded! Type 'ghelp' for available commands."