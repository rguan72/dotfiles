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

# Launch a SkyPilot cluster and ssh into it
ski() {
    [ -z "$1" ] && { echo "Usage: ski <name> [--no-autostop|--teardown] [sky flags]"; return 1; }
    local name="$1"; shift
    local autostop_args=(-i 720)
    local sky_args=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --no-autostop)
                autostop_args=()
                ;;
            --teardown)
                autostop_args=(--down -i 720)
                ;;
            *)
                sky_args+=("$1")
                ;;
        esac
        shift
    done
    sky launch -y "${autostop_args[@]}" -c "$name" "${sky_args[@]}" || return $?
    ssh "$name" 'test -d ~/.tmux || (git clone --quiet https://github.com/gpakosz/.tmux.git ~/.tmux && ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf)'
    scp -q ~/projects/dotfiles/config/tmux.conf.local "$name":~/.tmux.conf.local
    ssh "$name" 'command -v gh >/dev/null 2>&1 || { curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && sudo apt-get update -qq && sudo apt-get install -y gh; }'
    ssh "$name"
}

# Restart a stopped SkyPilot cluster (same disk/data) and ssh into it
skup() {
    [ -z "$1" ] && { echo "Usage: skup <name>"; return 1; }
    sky start -y -i 720 "$1" || return $?
    ssh "$1"
}

# `cd` then `ls` automatically
cd() {
    builtin cd "$@" && ls
}

# --- AWS S3 ---
alias s3ls='aws s3 ls'
alias s3cp='aws s3 cp'
alias s3rm='aws s3 rm'

# --- Python / venv ---
alias va='source .venv/bin/activate'

# --- AI / eval tooling ---
alias cc='claude'
alias cdx='codex --sandbox danger-full-access'
alias ins='inspect eval'

# Inspect eval --model shortcuts (e.g., `ins task.py --model $sonnet`)
export flash='openrouter/google/gemini-3.1-flash-lite-preview'
export sonnet='anthropic/claude-sonnet-4-6'
export haiku='anthropic/claude-haiku-4-5'
export opus='anthropic/claude-opus-4-6'

# --- Transcript viewers ---
alias bloomv="npx @isha-gpt/bloom-viewer --port 8080 --dir ./bloom-results"
alias petriv="npx @kaifronsdal/transcript-viewer@latest --dir ./outputs"

# --- Docker cleanup ---
alias nuke-insp='docker ps -a --filter "name=inspect-" --format "{{.ID}}" | xargs -r docker rm -f && docker network prune -f'

# --- Utilities ---
alias ll="ls -al"
alias uuid="python -c 'import sys,uuid; sys.stdout.write(str(uuid.uuid4()))' | pbcopy && pbpaste && echo"
