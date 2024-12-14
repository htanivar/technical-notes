# Custom Aliases
alias ll='ls -ltr'

alias reload='source ~/.bashrc'


# Source Paths aliases
if [ -f ~/.bash_aliases/paths.sh ]; then
  source ~/.bash_aliases/paths.sh
fi


# Source Git-related aliases
if [ -f ~/.bash_aliases/git_aliases.sh ]; then
  source ~/.bash_aliases/git_aliases.sh
fi

# Call go.sh to manage Go symlink
source ~/.bash_aliases/go.sh
