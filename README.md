# stildeeneca17-dots

Personal dotfiles for macOS (Apple Silicon + Intel), structured after [Gentleman.Dots](https://github.com/Gentleman-Programming/Gentleman.Dots).

## What's inside

| Folder | Tool | Description |
|--------|------|-------------|
| `StildeenecaFish/` | Fish 4.x | Shell config with starship, zoxide, pyenv, deno, DevOps aliases |
| `StildeenecaZsh/` | Zsh + Oh My Zsh | Secondary shell with Powerlevel10k |
| `StildeenecaNvim/` | Neovim (LazyVim) | Full IDE setup with 35+ plugins, oil, opencode |
| `StildeenecaTmux/` | tmux 3.x | Multiplexer with Ctrl+a prefix, vi-mode, vim-tmux-navigator |
| `StildeenecaGit/` | Git | Config + global gitignore |
| `StildeenecaOpencode/` | OpenCode | AI coding assistant config + skills |
| `starship.toml` | Starship | Unified prompt with k8s, git, langs, cmd_duration |
| `Brewfile` | Homebrew | Complete dependency manifest |

## Quick install

```bash
git clone https://github.com/stildeeneca17/stildeeneca17-dots.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Or one-liner:
```bash
git clone https://github.com/stildeeneca17/stildeeneca17-dots.git ~/dotfiles && ~/dotfiles/install.sh
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
- **Tmux plugins**: open tmux → `prefix + I` to install
- **Neovim plugins**: `nvim` — LazyVim auto-installs on first open
- **Starship**: works automatically after shell reload

## Tested on

- macOS 26 (Sequoia), Apple Silicon (M-series)

## Inspired by

[Gentleman.Dots](https://github.com/Gentleman-Programming/Gentleman.Dots) by Gentleman Programming
