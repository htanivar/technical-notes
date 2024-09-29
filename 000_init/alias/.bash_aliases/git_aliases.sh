# Git Status
alias gs='git status'
# Git Log Oneline
alias gl='git log --oneline'
# Git Add All
alias gaa='git add .'
# Git pull
alias gpl='git pull'
# Git push
alias gps='git push'
# Git Branch Cleanup
alias gbla='git branch -a'
# Git Branch Cleanup
alias gbc='git branch --merged | grep -v "*" | xargs -n 1 git branch -d'
# Git Checkout
gc() {
  git checkout "$1"
}

# Git Commit
gc() {
  if [ -z "$1" ]; then
    read -p "Enter commit message: " commit_message
    git commit -m "$commit_message"
  else
    git commit -m "$1"
  fi
}


# Git Stash List
gsl() {
  git stash list
}
# Git Stash Save
gss() {
  if [ -z "$1" ]; then
    read -p "Enter commit message: " commit_message
    git stash save "$commit_message"
  else
    git stash save "$1"
  fi
}
# Git Stash Apply
gsa() {
  # Check if the argument is provided
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