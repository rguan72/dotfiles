#!/bin/zsh
# ZSH configuration - makes terminal look nice and adds useful features

# Prefer user-local bin if present (Linux, sometimes macOS)
if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi

# pnpm global packages
if [ -d "$HOME/.local/share/pnpm" ]; then
  export PNPM_HOME="$HOME/.local/share/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi

# Homebrew on Apple Silicon
if [ -d "/opt/homebrew/bin" ]; then
  case ":$PATH:" in
    *":/opt/homebrew/bin:"*) ;;
    *) export PATH="/opt/homebrew/bin:$PATH" ;;
  esac
fi

# Get the directory where this config file lives
CONFIG_DIR=$(dirname "$(realpath "${(%):-%x}")")

# Setup oh-my-zsh framework with powerlevel10k theme
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"  # The theme that makes terminal look nice
ZSH_DISABLE_COMPFIX=true  # Don't warn about insecure completion directories

# Enable git plugin - adds tab completion for git commands/branches
plugins=(git)

# Load oh-my-zsh framework
source "$ZSH/oh-my-zsh.sh"

# Load powerlevel10k theme config (has all the visual settings)
source "$CONFIG_DIR/p10k.zsh"

# History settings - remember commands across sessions
HISTSIZE=10000              # Remember 10,000 commands in memory
SAVEHIST=10000              # Save 10,000 commands to disk
setopt SHARE_HISTORY        # Share history across all terminal windows
setopt HIST_IGNORE_DUPS     # Don't save duplicate commands
setopt HIST_IGNORE_SPACE    # Don't save commands that start with a space

# Smart history search with arrow keys
# Type part of a command, then press up/down to cycle through matching commands
bindkey '^[[A' history-beginning-search-backward  # Up arrow
bindkey '^[[B' history-beginning-search-forward   # Down arrow

# Load custom aliases
if [[ -f "$CONFIG_DIR/aliases.sh" ]]; then
    source "$CONFIG_DIR/aliases.sh"
fi

# Load HuggingFace config if it exists (machine-specific)
if [[ -f "$HOME/.hf_config.sh" ]]; then
    source "$HOME/.hf_config.sh"
fi

# Check for tool updates (once per day, with interactive prompt)
if [[ -f "$CONFIG_DIR/auto_update_check.sh" ]]; then
    source "$CONFIG_DIR/auto_update_check.sh"
fi

# Auto-activate virtualenv when entering a directory
autoload -U add-zsh-hook

_auto_venv() {
  # Deactivate if we've left the venv's project
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv_parent="${VIRTUAL_ENV%/*}"
    if [[ "$PWD" != "$venv_parent"* ]]; then
      deactivate
    fi
  fi

  # Activate if .venv or venv exists
  if [[ -z "$VIRTUAL_ENV" ]]; then
    if [[ -f ".venv/bin/activate" ]]; then
      source .venv/bin/activate
    elif [[ -f "venv/bin/activate" ]]; then
      source venv/bin/activate
    fi
  fi
}

add-zsh-hook chpwd _auto_venv
# Also run on shell startup for the initial directory
_auto_venv

# Display a random inspirational quote on shell startup
REPO_DIR=$(dirname "$CONFIG_DIR")
if [[ -f "$REPO_DIR/start/display_quote.sh" ]]; then
    bash "$REPO_DIR/start/display_quote.sh"
fi
