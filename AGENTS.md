# AGENTS.md

Guidance for coding agents working in this dotfiles repo.

## Purpose

This repo configures my local laptop terminal environment. Keep changes practical and close to the existing setup. The common request is: understand the local configuration and update dotfiles without disturbing unrelated machine-specific state.

## Repo Layout

- `install.sh`: one-time software/bootstrap install.
- `deploy.sh`: safe re-run deployment that links config files into `$HOME`.
- `config/zshrc.sh`: main zsh setup, completion, history, theme loading, auto-venv, startup quote.
- `config/aliases.sh`: shell aliases and helper functions.
- `config/vimrc`: Vim configuration linked to `~/.vimrc`.
- `config/ghostty/config`: Ghostty terminal config.
- `config/ghostty/shaders/`: Ghostty cursor shaders.
- `config/tmux.conf`: fallback/standalone tmux config.
- `config/tmux.conf.local`: Oh my tmux local overrides. Prefer editing this for tmux behavior.
- `config/p10k.zsh`: Powerlevel10k prompt config.
- `start/`: startup quote data and display script.

## Important Preferences

### Ghostty

Ghostty is the primary terminal on macOS. `deploy.sh` symlinks:

- `config/ghostty/config` to `~/.config/ghostty/config`
- `config/ghostty/shaders` to `~/.config/ghostty/shaders`

Preserve shader support when editing Ghostty. The active shader is configured with `custom-shader = shaders/...` in `config/ghostty/config`; shader files live under `config/ghostty/shaders/`.

### Zsh Completion and History

Keep these zsh behaviors working:

- Autocomplete/tab completion through oh-my-zsh plus explicit cached `compinit`.
- Git completion via `plugins=(git)`.
- Prefix history search: typing a prefix and pressing up/down should cycle through history entries matching that prefix.

The prefix-history behavior is implemented in `config/zshrc.sh` with:

```zsh
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
```

Do not replace these with plain history navigation unless explicitly requested.

### Aliases

Put aliases and small shell helper functions in `config/aliases.sh`. Keep repo-specific or personal workflow aliases there instead of spreading them through `config/zshrc.sh`.

### Oh my tmux

The intended tmux setup is Oh my tmux from `gpakosz/.tmux`, installed into `~/.config/tmux` by `install.sh`.

When Oh my tmux is present, `deploy.sh` symlinks `config/tmux.conf.local` to `~/.config/tmux/tmux.conf.local`. Prefer editing `config/tmux.conf.local` for tmux customization. `config/tmux.conf` is mainly a fallback for systems without Oh my tmux.

## Editing Rules

- Preserve the install/deploy split: install missing tools in `install.sh`; link or write config in `deploy.sh`.
- Avoid committing secrets, tokens, local absolute paths, or machine-only generated files.
- Keep shell scripts portable between macOS and Linux unless a section is explicitly macOS-only.
- Use zsh syntax in `config/zshrc.sh` and `config/aliases.sh`; use bash syntax in `install.sh` and `deploy.sh`.
- Prefer small, focused edits over broad rewrites.

## Validation

Useful checks after changes:

```bash
bash -n install.sh
bash -n deploy.sh
zsh -n config/zshrc.sh
zsh -n config/aliases.sh
tmux -L dotfiles-check -f config/tmux.conf start-server \; source-file config/tmux.conf \; kill-server
```

For Ghostty changes, inspect `config/ghostty/config` and shader paths carefully. The deployed shader path should be relative to `~/.config/ghostty/`.
