# Stildeeneca17.Dots

Personal dotfiles for macOS (Apple Silicon + Intel), structured after [Gentleman.Dots](https://github.com/Gentleman-Programming/Gentleman.Dots).

## What's inside

| Folder | Tool | Description |
|--------|------|-------------|
| `stildeeneca17-fish/` | Fish 4.x | Shell config with starship, zoxide, pyenv, deno, DevOps aliases |
| `stildeeneca17-zsh/` | Zsh + Oh My Zsh | Secondary shell with Powerlevel10k |
| `stildeeneca17-nvim/` | Neovim (LazyVim) | Full IDE setup with 35+ plugins, oil, opencode |
| `stildeeneca17-tmux/` | tmux 3.x | Multiplexer with Ctrl+a prefix, vi-mode, vim-tmux-navigator |
| `stildeeneca17-git/` | Git | Config + global gitignore |
| `stildeeneca17-opencode/` | OpenCode | AI coding assistant config + skills |
| `starship.toml` | Starship | Unified prompt with k8s, git, langs, cmd_duration |
| `Brewfile` | Homebrew | Complete dependency manifest |

## Quick install

```bash
git clone https://github.com/stildeeneca17/Stildeeneca17.Dots.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Or one-liner:
```bash
git clone https://github.com/stildeeneca17/Stildeeneca17.Dots.git ~/dotfiles && ~/dotfiles/install.sh
```

## Dry run first

```bash
./install.sh --dry-run
```

## What the installer does

1. Checks macOS platform (arm64 or x86_64)
2. Creates a timestamped backup of any existing configs at `~/.stildeeneca_backup_<timestamp>/`
3. Installs Homebrew (if missing)
4. Runs `brew bundle` to install all dependencies
5. Copies each tool's config — **only if the tool is installed**
6. Bootstraps TPM for tmux plugins

## Post-install

- **Shell**: `exec fish` to reload
- **Tmux plugins**: open tmux → `Ctrl+a` then `I` to install plugins
- **Neovim plugins**: `nvim` — LazyVim auto-installs on first open
- **Starship**: works automatically after shell reload
- **Git email**: `git config --global user.email "tu@email.com"`

## Tested on

- macOS 26 (Sequoia), Apple Silicon (M-series)

## Inspired by

[Gentleman.Dots](https://github.com/Gentleman-Programming/Gentleman.Dots) by Gentleman Programming
