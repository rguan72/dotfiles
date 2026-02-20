#!/bin/zsh
# Custom aliases and helper functions

# Force check for updates (ignores daily check timer)
alias update-check='rm -f ~/.cache/dotfiles_update_check && source ~/.zshrc'

# --- Git aliases ---
alias gb="git branch"
alias gau="git add -u"
alias gaa="git add ."
alias gco="git checkout"
alias gcom="git checkout main"
alias gd="git diff"
alias gdc="git diff --cached"
alias gg="git grep"
alias gpre="git pull --rebase"
alias gs="git status"
alias gp="git push"
alias gpr="gh pr create --template pull_request_template.md"
alias gsa="git add . && git commit -m '.' && git push -u"

# --- Helper functions ---

# Create a git branch prefixed with your name
gbc_function() {
    branch_name="richard/$1"
    git checkout -b "$branch_name"
}
alias gbc="gbc_function"

# Delete local branches whose PRs have been merged or closed
delete_merged_branches() {
    for branch in $(git branch | sed 's/\*//'); do
        pr=$(gh pr list --head "$branch" -s closed --json state,number -q '.[] | select(.state=="MERGED" or .state=="CLOSED") | .number')
        if [ ! -z "$pr" ]; then
            echo "Deleting branch $branch as its PR #$pr is merged or closed."
            git branch -d "$branch"
        else
            echo "Branch $branch does not have a merged or closed PR."
        fi
    done
}

# Checkout main, pull latest, and clean up merged branches
alias grs="git checkout main; git pull; delete_merged_branches"

# Kill a process listening on a given port
kill_process_on_port() {
    if [ -z "$1" ]; then
        echo "Usage: kill_process_on_port <port>"
        return 1
    fi
    local port=$1
    echo "Killing process on port $port..."
    lsof -i tcp:${port} | awk 'NR!=1 {print $2}' | xargs -r kill
    echo "Process on port $port killed (if it was running)."
}
alias kp="kill_process_on_port"

# --- Utilities ---
alias ll="ls -al"
alias uuid="python -c 'import sys,uuid; sys.stdout.write(str(uuid.uuid4()))' | pbcopy && pbpaste && echo"
