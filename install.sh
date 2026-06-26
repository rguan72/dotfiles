#!/bin/bash
# Main installation script - sets up terminal and tools
# Usage: ./install.sh

# Exit on any error, undefined variables, or pipe failures
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "========================================="
echo "  Minimal Dotfiles Setup"
echo "========================================="
echo ""

# Detect operating system (Linux or Mac)
operating_system="$(uname -s)"
case "${operating_system}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    *)          echo "Error: Unsupported OS" && exit 1
esac

echo "OS: $machine"
echo ""

# Check if basic tools are installed, install if missing
echo "Checking for zsh, curl, git..."
missing_tools=()
command -v zsh &> /dev/null || missing_tools+=("zsh")
command -v curl &> /dev/null || missing_tools+=("curl")
command -v git &> /dev/null || missing_tools+=("git")

if [ ${#missing_tools[@]} -eq 0 ]; then
    echo "All required tools are already installed!"
else
    echo "Missing tools: ${missing_tools[*]}"
    echo "Attempting to install..."

    if [ "$machine" == "Linux" ]; then
        # Try with sudo, but warn if it fails
        if sudo -n true 2>/dev/null; then
            sudo apt-get update -y
            sudo apt-get install -y "${missing_tools[@]}"
        else
            echo "Warning: sudo access required to install missing tools."
            echo "Please ask your system administrator to install: ${missing_tools[*]}"
            echo "Or install them manually in your user directory."
            exit 1
        fi
    elif [ "$machine" == "Mac" ]; then
        # Install via homebrew (Mac package manager)
        brew install "${missing_tools[@]}"
    fi
fi

# Install oh-my-zsh (zsh framework) and powerlevel10k theme (makes terminal look nice)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo ""
    echo "Installing oh-my-zsh and powerlevel10k theme..."

    # Install oh-my-zsh without prompting for user input
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Install powerlevel10k theme (the visual theme for your terminal)
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_zsh_plugin() {
    local name="$1"
    local repo="$2"
    local dest="$ZSH_CUSTOM_DIR/plugins/$name"
    if [ ! -d "$dest" ]; then
        echo "Installing zsh plugin: $name"
        git clone --depth=1 "$repo" "$dest"
    fi
}

install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
install_zsh_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions.git"
install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"

# Install Claude Code CLI if not already installed
if ! command -v claude &> /dev/null; then
    echo ""
    echo "Installing Claude Code..."
    curl -LsSf https://claude.ai/install.sh | bash
fi

# Install uv (fast Python package installer) if not already installed
if ! command -v uv &> /dev/null; then
    echo ""
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Install HuggingFace CLI using uv
# Check if uv is available (either in PATH or just installed)
if command -v uv &> /dev/null; then
    UV_CMD="uv"
elif [ -f "$HOME/.local/bin/uv" ]; then
    UV_CMD="$HOME/.local/bin/uv"
else
    echo ""
    echo "Warning: uv not found, skipping HuggingFace CLI installation"
    echo "After restarting your shell, run: uv tool install 'huggingface_hub[cli]'"
    UV_CMD=""
fi

if [ -n "$UV_CMD" ]; then
    echo ""
    echo "Installing HuggingFace CLI..."
    "$UV_CMD" tool install "huggingface_hub[cli]"
fi

# Install oh-my-tmux if not already installed
OH_MY_TMUX_DIR="$HOME/.local/share/tmux/oh-my-tmux"
if [ ! -d "$OH_MY_TMUX_DIR" ] || [ ! -f "$OH_MY_TMUX_DIR/.tmux.conf" ]; then
    echo ""
    echo "Installing oh-my-tmux..."
    mkdir -p "$HOME/.config/tmux"
    mkdir -p "$(dirname "$OH_MY_TMUX_DIR")"
    git clone https://github.com/gpakosz/.tmux.git "$OH_MY_TMUX_DIR"
fi
mkdir -p "$HOME/.config/tmux"
ln -sfn "$OH_MY_TMUX_DIR/.tmux.conf" "$HOME/.config/tmux/tmux.conf"

# Install pnpm (Node package manager) if not already installed
if ! command -v pnpm &> /dev/null; then
    echo ""
    echo "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -

    # Make pnpm available immediately in this script
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
fi

# Install OpenAI Codex using pnpm
echo ""
echo "Installing OpenAI Codex..."
pnpm install -g @openai/codex

echo ""
echo "Done! Run ./deploy.sh next"
