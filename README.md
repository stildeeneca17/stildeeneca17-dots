# stildeeneca17-dots

Personal dotfiles for macOS (Apple Silicon + Intel).

## What's inside

| Folder | Tool | Description |
|--------|------|-------------|
| `stildeeneca17-fish/` | Fish 4.x | Shell config with starship, zoxide, pyenv, deno, DevOps aliases |
| `stildeeneca17-zsh/` | Zsh + Oh My Zsh | Secondary shell with Powerlevel10k |
| `stildeeneca17-nvim/` | Neovim (LazyVim) | Full IDE setup — oil, opencode, LSP, treesitter |
| `stildeeneca17-tmux/` | tmux 3.x | Ctrl+a prefix, vi-mode, vim-tmux-navigator, TPM |
| `stildeeneca17-git/` | Git | Config with delta diffs + global gitignore |
| `stildeeneca17-opencode/` | OpenCode | AI coding assistant config + skills + agents |
| `starship.toml` | Starship | Unified prompt: git, k8s, python, node, deno, cmd_duration |
| `Brewfile` | Homebrew | Complete dependency manifest |

## Install

```bash
git clone https://github.com/stildeeneca17/stildeeneca17-dots.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

One-liner:
```bash
git clone https://github.com/stildeeneca17/stildeeneca17-dots.git ~/dotfiles && ~/dotfiles/install.sh
```

Dry run first:
```bash
./install.sh --dry-run
```

## What the installer does

The installer asks 5 questions, then runs automatically:

```
Step 1/5 — Shell:        Fish (+ carapace, zoxide, atuin, starship)
                         Zsh  (+ Oh My Zsh, P10k, carapace, zoxide, atuin)
Step 2/5 — Multiplexer:  Tmux (+ TPM, plugins auto-install)  |  None
Step 3/5 — Neovim:       Yes (LazyVim + all AI CLIs)  |  No
Step 4/5 — Font:         MesloLGS Nerd Font
Step 5/5 — Backup:       Timestamped backup to ~/.stildeeneca_backup_<timestamp>/
```

Then installs in order:

1. **Homebrew** — installs if missing
2. **Shell** — fish/zsh + plugins + starship + direnv
3. **Tmux** — TPM + plugins auto-installed via `tpm/bin/install_plugins`
4. **Neovim** — nvim + deps (fzf, fd, ripgrep, bat, lazygit, tree-sitter...)
5. **AI tools** — OpenCode, Claude Code, Codex CLI, Gemini CLI, Engram, Gentle-AI, GGA
6. **CLI utilities** — eza, bat, fzf, fd, zoxide, atuin, btop, lazydocker, stern, xh, tldr...
7. **Font** — MesloLGS Nerd Font via brew cask
8. **Git** — delta diffs + gitconfig + gitignore_global
9. **Default shell** — chsh to chosen shell

---

## Post-install checklist

Steps that require manual action after running `./install.sh`.

### 🐚 Shell

- [ ] **Reload shell**: `exec fish` (or `exec zsh`)
- [ ] **Set Git identity** (sanitized in the repo):
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "you@example.com"
  ```

### 🪟 Tmux

- [ ] **Verify plugins loaded**: open tmux — plugins should already be installed.
  If not: `Ctrl+a` then `I` (capital i) to reinstall via TPM.

### 📝 Neovim

- [ ] **First open**: run `nvim` — LazyVim auto-installs all plugins (~2 min, needs internet).
- [ ] **Check health**: inside nvim run `:checkhealth` to verify LSP, treesitter, etc.
- [ ] **Mason LSP servers**: run `:Mason` to install language servers for your stack
  (suggested: `pyright`, `ts_ls`, `lua_ls`, `bashls`, `dockerls`, `yamlls`, `terraformls`).

### 🤖 AI tools

- [ ] **OpenCode**: run `opencode` and sign in / configure your API keys.
- [ ] **Claude Code**: run `claude` and authenticate with your Anthropic account.
- [ ] **Codex CLI**: run `codex` and sign in with your OpenAI / ChatGPT account.
- [ ] **Gemini CLI**: run `gemini` and authenticate with your Google account.
- [ ] **Engram** (AI memory): set up for each agent:
  ```bash
  engram setup opencode    # OpenCode integration
  engram setup claude-code # Claude Code integration
  engram setup codex       # Codex integration
  engram setup gemini-cli  # Gemini CLI integration
  ```
- [ ] **Gentle-AI**: run `gentle-ai` or `gga` to configure.

### 🔧 Git

- [ ] **Set your name and email** (sanitized in the repo):
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "you@example.com"
  ```
- [ ] **Verify delta**: run `git diff` in any repo — should show side-by-side diff with colors.
  If not: check that `delta` is in PATH with `which delta`.

### ☁️ DevOps / Cloud

- [ ] **kubectl context**: `kubectl config get-contexts` — set your cluster context.
- [ ] **Azure CLI login**: `az login`
- [ ] **ArgoCD login**: `argocd login <your-argocd-server>`
- [ ] **Flux**: configure your Git repository source if needed.
- [ ] **k9s**: launch with `k9s` — no config needed, works with current kubectl context.
- [ ] **lazydocker**: launch with `lazydocker` — connects to running Docker daemon automatically.
- [ ] **stern**: tail pods with `stern <pod-name-pattern> -n <namespace>`.

### 🐍 Python

- [ ] **pyenv**: verify with `pyenv versions` and `python --version`.
- [ ] **virtualenvs**: pyenv-virtualenv is installed — create envs with:
  ```bash
  pyenv virtualenv 3.13.11 my-project-env
  pyenv local my-project-env
  ```
- [ ] **direnv**: add `.envrc` files to your project dirs to auto-load env vars.
  First use in a dir: `direnv allow`.

### 📦 Node

- [ ] **pnpm**: verify with `pnpm --version`.
- [ ] **Angular CLI** (if needed): `npm install -g @angular/cli`.

### 🔤 Font

- [ ] **Set color preset in iTerm2**: `Cmd+,` → Profiles → Colors → Color Preset → **`Solarized Dark`**.
- [ ] **Set font in iTerm2**: `Cmd+,` → Profiles → Text → Font → search `MesloL` → select **`MesloLGS Nerd Font Mono`**.
- [ ] **Verify icons**: run `fastfetch` or `eza --icons` — icons should render correctly.
  If you see `?` boxes or squares, the font isn't set in your terminal.

> **Why `MesloLGS Nerd Font Mono` and not `MesloLGS NF`?**
> The cask `font-meslo-lg-nerd-font` installs the full Meslo family under the name
> **MesloLGS Nerd Font Mono**. That's the one Powerlevel10k recommends. If you search
> for `MesloL` in iTerm2's font picker, pick the first result: `MesloLGS Nerd Font Mono`.

### 🖥️ macOS misc

- [ ] **ngrok**: `ngrok config add-authtoken <your-token>` (get token at https://ngrok.com).
- [ ] **mkcert**: first-time setup: `mkcert -install` (installs local CA).
- [ ] **Starship**: verify it loads in your shell after `exec fish` — the prompt should change.
  If still showing old prompt, check that `starship init fish | source` is in `config.fish`.

---

## Tested on

macOS 26 (Sequoia), Apple Silicon (M-series)
