#!/bin/zsh
# Custom aliases and helper functions

# oh-my-zsh loads this file from its custom directory, while config/zshrc.sh
# also sources it directly as a fallback. Avoid defining everything twice.
if [[ -n "${DOTFILES_ALIASES_LOADED:-}" ]]; then
    return 0
fi
typeset -g DOTFILES_ALIASES_LOADED=1

# --- Git aliases ---
alias gb="git branch"
alias gau="git add -u"
alias gaa="git add ."
alias gco="git checkout"
alias gcom="git checkout main"
alias gcm="git commit -m"
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

# `cd` then `ls` automatically
cd() {
    builtin cd "$@" && ls
}

# --- AI tooling ---
alias cc='claude'
alias cdx='codex --dangerously-bypass-approvals-and-sandbox'
