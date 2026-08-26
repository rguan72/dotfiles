#!/bin/bash
# Deployment script - links your configurations to the right places
# Usage: ./deploy.sh
# Safe to run multiple times - just updates the links

# Exit on any error, undefined variables, or pipe failures
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "========================================="
echo "  Deploying Dotfiles"
echo "========================================="
echo ""

# Setup GitHub authentication (optional)
echo "--- GitHub Setup (Optional) ---"
read -p "Configure GitHub credentials? (y/n): " configure_github
if [[ "$configure_github" =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/setup_github.sh"
fi

# Setup HuggingFace configuration (optional)
# Check for HF CLI (might not be in PATH yet after fresh install)
HF_CLI=""
if command -v hf &> /dev/null; then
    HF_CLI="hf"
elif [ -f "$HOME/.local/bin/hf" ]; then
    HF_CLI="$HOME/.local/bin/hf"
fi

if [ -n "$HF_CLI" ]; then
    echo ""
    echo "--- HuggingFace Home Directory (Optional) ---"
    echo "By default, HuggingFace uses ~/.cache/huggingface"
    read -p "Do you want to set a custom HF_HOME directory? (y/n): " set_hf_home
    if [[ "$set_hf_home" =~ ^[Yy]$ ]]; then
        echo "Example: /disk/u/andy/.cache/huggingface"
        read -p "Enter custom HF_HOME path: " hf_home_path
        if [ -n "$hf_home_path" ]; then
            # Create the directory if it doesn't exist
            mkdir -p "$hf_home_path" 2>/dev/null || true

            # Write HF_HOME export to machine-specific config file
            echo "export HF_HOME=\"$hf_home_path\"" > "$HOME/.hf_config.sh"
            echo "HF_HOME configured: $hf_home_path"
            echo "(Stored in ~/.hf_config.sh)"
        fi
    else
        # Remove HF config file if user doesn't want custom path
        rm -f "$HOME/.hf_config.sh" 2>/dev/null || true
    fi

    echo ""
    echo "--- HuggingFace Authentication (Optional) ---"
    read -p "Configure HuggingFace credentials? (y/n): " configure_hf
    if [[ "$configure_hf" =~ ^[Yy]$ ]]; then
        echo ""
        echo "You'll need a token from https://huggingface.co/settings/tokens"
        "$HF_CLI" auth login
    fi
else
    echo ""
    echo "Note: HuggingFace CLI (hf) not found - skipping HuggingFace setup"
    echo "If you just ran install.sh, try restarting your shell and running deploy.sh again"
fi

echo ""
echo "========================================="
echo "  Deploying Configuration Files..."
echo "========================================="

# Deploy zsh config
# This creates ~/.zshrc which tells zsh to load our custom config
echo ""
echo "--- Configuring ZSH ---"
echo "source $SCRIPT_DIR/config/zshrc.sh" > $HOME/.zshrc
echo "ZSH config deployed to ~/.zshrc"

# Also install aliases in oh-my-zsh's custom directory. This makes them
# available to an existing oh-my-zsh config even before the shell is restarted
# with the repo's full zsh configuration.
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM_DIR"
ln -sfn "$SCRIPT_DIR/config/aliases.sh" "$ZSH_CUSTOM_DIR/aliases.zsh"
echo "ZSH aliases deployed to $ZSH_CUSTOM_DIR/aliases.zsh"

# Deploy Vim config
echo ""
echo "--- Configuring Vim ---"
ln -sfn "$SCRIPT_DIR/config/vimrc" "$HOME/.vimrc"
echo "Vim config deployed to ~/.vimrc"

# Deploy tmux config
# oh-my-tmux uses ~/.config/tmux/tmux.conf and loads tmux.conf.local
# We symlink our customization file (tmux.conf.local) into the config dir
echo ""
echo "--- Configuring Tmux ---"
OH_MY_TMUX_DIR="$HOME/.local/share/tmux/oh-my-tmux"
if [ -f "$OH_MY_TMUX_DIR/.tmux.conf" ]; then
    mkdir -p "$HOME/.config/tmux"
    ln -sfn "$OH_MY_TMUX_DIR/.tmux.conf" "$HOME/.config/tmux/tmux.conf"
    ln -sfn "$SCRIPT_DIR/config/tmux.conf.local" "$HOME/.config/tmux/tmux.conf.local"
    echo "Tmux config deployed (oh-my-tmux + local overrides)"
else
    # Fallback for systems without oh-my-tmux
    echo "source-file $SCRIPT_DIR/config/tmux.conf" > $HOME/.tmux.conf
    echo "Tmux config deployed to ~/.tmux.conf (standalone)"
fi

# Deploy Ghostty config (macOS only)
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo ""
    echo "--- Configuring Ghostty ---"
    mkdir -p "$HOME/.config/ghostty"
    ln -sfn "$SCRIPT_DIR/config/ghostty/config" "$HOME/.config/ghostty/config"
    ln -sfn "$SCRIPT_DIR/config/ghostty/shaders" "$HOME/.config/ghostty/shaders"
    echo "Ghostty config deployed to ~/.config/ghostty/"
fi

# Change default shell to zsh
# This makes zsh start automatically when you open a new terminal
echo ""
echo "--- Setting ZSH as default shell ---"
if [ "$SHELL" != "$(which zsh)" ]; then
    # Try to change shell with timeout to avoid hanging
    # Some systems require password or restrict this entirely
    if timeout 5 chsh -s $(which zsh) 2>/dev/null; then
        echo "Default shell changed to zsh"
    else
        echo "Note: Could not change default shell automatically"
        echo "You can change it manually by running: chsh -s \$(which zsh)"
        echo "Or just run 'exec zsh' when you want to use zsh"
    fi
else
    echo "ZSH is already your default shell"
fi

echo ""
echo "========================================="
echo "  Deployment Complete!"
echo "========================================="
echo ""
echo "Restart your terminal or run: exec zsh"
echo ""
