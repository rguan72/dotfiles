# Minimal Dotfiles

Bare essentials: nice-looking terminal + development tools.

## Install vs Deploy

**install.sh** - Downloads and installs software (run once per machine)
- Installs zsh, curl, git, and Node.js
- Installs oh-my-zsh and powerlevel10k theme
- Installs zsh autosuggestions, extra completions, and syntax highlighting
- Installs custom aliases into oh-my-zsh
- Installs the Vim configuration
- Installs the Ghostty config and cursor shaders on macOS
- Installs oh-my-tmux
- Installs Claude Code, uv, HuggingFace CLI, pnpm, OpenAI Codex

**deploy.sh** - Links your configs (run after install, safe to re-run anytime)
- Creates `~/.zshrc` that points to your zsh config
- Links custom aliases into oh-my-zsh
- Links the Vim configuration to `~/.vimrc`
- Creates `~/.tmux.conf` that points to your tmux config
- Links the Ghostty config and cursor shaders on macOS
- Optionally configures GitHub and HuggingFace authentication
- Sets zsh as your default shell

**When to use each:**
- First time on a new machine: `./install.sh` then `./deploy.sh`
- Updating configs on existing machine: just `./deploy.sh`
- Moving this repo to a new location: just `./deploy.sh` to update the paths

## Quick Start

```bash
./install.sh    # First time only
./deploy.sh     # Every time you move the repo or update configs
exec zsh        # Start using it
```

## What You Get

**Terminal appearance:**
- Powerlevel10k theme (makes terminal look professional)
- Git integration (shows branch, status in prompt)
- Random inspirational quote on each shell startup

**Useful features:**
- Git tab completion (type `git che<tab>` → `git checkout`)
- Command autosuggestions from history and completions
- Smart history search (type `git`, press up arrow, cycles through git commands only)
- 10,000 command history saved immediately, with up-arrow scoped to the current terminal session
- Daily auto-update check for global packages (prompts y/n)

**Tools:**
- Claude Code CLI
- OpenAI Codex (via pnpm)
- uv (fast Python package installer)
- HuggingFace CLI

**Optional:**
- GitHub authentication (won't ask for password on push/pull)
- HuggingFace authentication

## Files

```
dotfiles/
├── install.sh              # Installs software
├── deploy.sh               # Links configs to home directory
├── setup_github.sh         # GitHub authentication setup
├── config/
│   ├── zshrc.sh            # ZSH config (theme + history + git completion)
│   ├── aliases.sh          # Custom aliases
│   ├── auto_update_check.sh # Daily update checker for pnpm packages
│   ├── vimrc               # Vim configuration
│   ├── tmux.conf           # Fallback tmux config
│   ├── tmux.conf.local     # Oh my tmux overrides
│   └── p10k.zsh            # Powerlevel10k theme settings
└── start/
    ├── quotes.json         # Inspirational quotes collection
    └── display_quote.sh    # Random quote display script
```

## Customization

**Add aliases** - Edit `config/aliases.sh`

**Customize ZSH** - Edit `config/zshrc.sh`

**Add your own quotes** - Edit `start/quotes.json`:
```json
{
  "quote": "Your inspiring quote here",
  "author": "Author Name"
}
```

## Where Things Go

After running deploy.sh:
- `~/.zshrc` → sources this repo's `config/zshrc.sh`
- `~/.config/tmux/tmux.conf` → symlinks to Oh my tmux
- `~/.config/tmux/tmux.conf.local` → symlinks to this repo's `config/tmux.conf.local`
- `~/.vimrc` → symlinks to this repo's `config/vimrc`
- `~/.config/ghostty/config` → symlinks to this repo's `config/ghostty/config` on macOS
- `~/.config/ghostty/shaders` → symlinks to this repo's `config/ghostty/shaders` on macOS
- `~/.git-credentials` → your GitHub token (if configured)
- `~/.hf_config.sh` → your HuggingFace home directory (if configured)

This means you can edit files in this repo and changes take effect immediately (just restart your shell).

## Credit

Based on [jplhughes/dotfiles](https://github.com/jplhughes/dotfiles).
