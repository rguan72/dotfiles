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
    [ -z "$1" ] && { echo "Usage: ski <name> [--no-teardown|--no-autostop] [sky flags]"; return 1; }
    local repo_dir="$HOME/projects/petri"
    local repo_label="Petri"
    case "$PWD/" in
        "$HOME/projects/Petri_2"/*)
            repo_dir="$HOME/projects/Petri_2"
            repo_label="Petri_2"
            ;;
    esac
    local petri_env="$repo_dir/.env"
    [ -r "$petri_env" ] || { echo "Missing local $repo_label .env: $petri_env"; return 1; }
    local petri_1_env="$HOME/projects/petri/.env"
    local petri_2_env="$HOME/projects/Petri_2/.env"
    local petri_2_url
    petri_2_url="$(git -C "$HOME/projects/Petri_2" remote get-url origin)" || { echo "Missing Petri_2 origin remote"; return 1; }
    local petri_2_branch
    petri_2_branch="$(git -C "$HOME/projects/Petri_2" branch --show-current)" || return 1
    [ -n "$petri_2_branch" ] || { echo "Petri_2 is in detached HEAD; cannot choose a branch to clone"; return 1; }
    [ -r "$petri_1_env" ] || { echo "Missing local Petri .env: $petri_1_env"; return 1; }
    [ -r "$petri_2_env" ] || { echo "Missing local Petri_2 .env: $petri_2_env"; return 1; }
    local name="$1"; shift
    local ssh_cmd=(ssh -A)
    local petri_url="git@github.com:rguan72/petri.git"
    local remote_git_ssh="ssh -o IdentitiesOnly=no -o StrictHostKeyChecking=accept-new"
    local github_key="$HOME/.ssh/id_ed25519"
    local autostop_args=(-i 720)
    local sky_args=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --no-teardown|--no-autostop)
                autostop_args=()
                ;;
            *)
                sky_args+=("$1")
                ;;
        esac
        shift
    done
    [ -r "$github_key" ] || { echo "ERROR: Missing local GitHub SSH key: $github_key"; return 1; }
    ssh-add -q "$github_key" >/dev/null 2>&1 || { echo "ERROR: Could not load local GitHub SSH key into ssh-agent: $github_key"; return 1; }
    sky launch -y "${autostop_args[@]}" -c "$name" "${sky_args[@]}" || return $?
    "${ssh_cmd[@]}" "$name" 'test -d ~/.tmux || (git clone --quiet https://github.com/gpakosz/.tmux.git ~/.tmux && ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf)' || return $?
    scp -q ~/projects/dotfiles/config/tmux.conf.local "$name":~/.tmux.conf.local || return $?
    "${ssh_cmd[@]}" "$name" 'command -v gh >/dev/null 2>&1 || { curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && sudo apt-get update -qq && sudo apt-get install -y gh; }' || return $?
    "${ssh_cmd[@]}" "$name" 'command -v aws >/dev/null 2>&1 || { tmpdir=$(mktemp -d) && cd "$tmpdir" && sudo apt-get update -qq && sudo apt-get install -y -qq unzip curl && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o awscliv2.zip && unzip -q awscliv2.zip && sudo ./aws/install && cd / && rm -rf "$tmpdir"; }' || return $?
    "${ssh_cmd[@]}" "$name" 'set -e; command -v node >/dev/null 2>&1 || { curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - >/dev/null && sudo apt-get install -y -qq nodejs; }; command -v claude >/dev/null 2>&1 || sudo npm install -g @anthropic-ai/claude-code@latest; command -v codex >/dev/null 2>&1 || sudo npm install -g @openai/codex@latest; command -v claude; claude --version; command -v codex; codex --version; command -v bwrap >/dev/null 2>&1 || sudo apt-get install -y -qq bubblewrap' || return $?
    "${ssh_cmd[@]}" "$name" "set -e; export GIT_SSH_COMMAND='$remote_git_ssh'; if [ -z \"\${SSH_AUTH_SOCK:-}\" ]; then echo 'ERROR: SSH agent forwarding is not active on the remote host.' >&2; echo 'Run ssh-add -l locally, make sure your key is loaded, and reconnect with ssh -A.' >&2; exit 1; fi; if ! ssh-add -l >/dev/null 2>&1; then echo 'ERROR: SSH agent forwarding is active, but the forwarded agent has no usable keys.' >&2; echo 'Run ssh-add -l locally and add your GitHub key with ssh-add if needed.' >&2; exit 1; fi; for repo in '$petri_url' '$petri_2_url'; do if ! git ls-remote --exit-code \"\$repo\" HEAD >/dev/null 2>&1; then echo \"ERROR: Cannot access \$repo from remote host via forwarded SSH agent.\" >&2; echo 'Agent forwarding or GitHub repo permissions are broken; refusing to clone/pull.' >&2; exit 1; fi; done" || return $?
    "${ssh_cmd[@]}" "$name" "export GIT_SSH_COMMAND='$remote_git_ssh'; test -d ~/petri/.git || { echo 'Cloning ~/petri via forwarded SSH agent...'; git clone '$petri_url' ~/petri || { echo 'ERROR: Failed to clone ~/petri via forwarded SSH agent.' >&2; exit 1; }; }" || return $?
    "${ssh_cmd[@]}" "$name" "set -e; export GIT_SSH_COMMAND='$remote_git_ssh'; if [ -d ~/Petri_2/.git ]; then echo 'Updating ~/Petri_2 via forwarded SSH agent...'; git -C ~/Petri_2 fetch origin '$petri_2_branch' && git -C ~/Petri_2 checkout '$petri_2_branch' && git -C ~/Petri_2 pull --ff-only origin '$petri_2_branch' || { echo 'ERROR: Failed to update ~/Petri_2 via forwarded SSH agent.' >&2; exit 1; }; else if [ -e ~/Petri_2 ]; then mv ~/Petri_2 ~/Petri_2.rsync-backup.\$(date +%Y%m%d%H%M%S); fi; echo 'Cloning ~/Petri_2 via forwarded SSH agent...'; git clone --branch '$petri_2_branch' '$petri_2_url' ~/Petri_2 || { echo 'ERROR: Failed to clone ~/Petri_2 via forwarded SSH agent.' >&2; exit 1; }; fi" || return $?
    scp -q "$petri_1_env" "$name":~/petri/.env || return $?
    scp -q "$petri_2_env" "$name":~/Petri_2/.env || return $?
    "${ssh_cmd[@]}" "$name" "chmod 600 ~/petri/.env ~/Petri_2/.env" || return $?
    "${ssh_cmd[@]}" "$name"
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
alias cdx='codex --dangerously-bypass-approvals-and-sandbox'
alias ins='inspect eval'

# Inspect eval --model shortcuts (e.g., `ins task.py --model $sonnet`)
export flash='openrouter/google/gemini-3.1-flash-lite-preview'
export sonnet='anthropic/claude-sonnet-4-6'
export haiku='anthropic/claude-haiku-4-5'
export opus='anthropic/claude-opus-4-6'

agentnet-tunnel() {
  local NS=$1 SVC=$2 RPORT=$3 LPORT=$4
  local POD_IP=$(kubectl get endpoints "$SVC" -n "$NS" \
    -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
  local NODE=$(kubectl get pod -l "app.kubernetes.io/name=$SVC" -n "$NS" \
    -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
  local INSTANCE_ID=$(kubectl get node "$NODE" \
    -o jsonpath='{.spec.providerID}' | grep -oE 'i-[0-9a-f]+')
  echo "Tunneling localhost:$LPORT -> $POD_IP:$RPORT via $INSTANCE_ID"
  aws ssm start-session --target "$INSTANCE_ID" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "portNumber=$RPORT,localPortNumber=$LPORT,host=$POD_IP" \
    --profile agentnet-customer
}

# --- Transcript viewers ---
alias bloomv="npx @isha-gpt/bloom-viewer --port 8080 --dir ./bloom-results"
alias petriv="npx @kaifronsdal/transcript-viewer@latest --dir ./outputs"

# --- Docker cleanup ---
alias nuke-insp='docker ps -a --filter "name=inspect-" --format "{{.ID}}" | xargs -r docker rm -f && docker network prune -f'

# --- Utilities ---
alias ll="ls -al"
alias uuid="python -c 'import sys,uuid; sys.stdout.write(str(uuid.uuid4()))' | pbcopy && pbpaste && echo"
