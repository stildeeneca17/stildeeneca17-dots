#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════╗
# ║            stildeeneca17-dots installer              ║
# ║        Personal dotfiles setup for macOS             ║
# ╚══════════════════════════════════════════════════════╝

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.stildeeneca_backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false

# ─── User choices (filled during questions) ───────────────
CHOICE_SHELL=""        # fish | zsh
CHOICE_MULTIPLEXER=""  # tmux | none
CHOICE_NVIM=""         # yes | no
CHOICE_FONT=""         # yes | no
CHOICE_BACKUP=""       # yes | no

# ─── Helpers ──────────────────────────────────────────────

log_step()  { echo ""; echo "  $1"; }
log_ok()    { echo "  ✅ $1"; }
log_skip()  { echo "  ⏭️  $1"; }
log_err()   { echo "  ❌ $1"; }
log_info()  { echo "  ℹ️  $1"; }

check_tool() { command -v "$1" &>/dev/null; }

ask() {
  # ask <prompt> <var_name> [default]
  local prompt="$1"
  local var_name="$2"
  local default="${3:-}"
  local answer

  if [[ -n "$default" ]]; then
    read -r -p "  $prompt [$default]: " answer
    answer="${answer:-$default}"
  else
    read -r -p "  $prompt: " answer
  fi

  printf -v "$var_name" '%s' "$answer"
}

ask_yn() {
  # ask_yn <question> <var_name> [default y|n]
  local question="$1"
  local var_name="$2"
  local default="${3:-y}"
  local answer

  while true; do
    if [[ "$default" == "y" ]]; then
      read -r -p "  $question [Y/n]: " answer
      answer="${answer:-y}"
    else
      read -r -p "  $question [y/N]: " answer
      answer="${answer:-n}"
    fi

    case "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" in
      y|yes) printf -v "$var_name" '%s' "yes"; return ;;
      n|no)  printf -v "$var_name" '%s' "no";  return ;;
      *) echo "  Please answer y or n." ;;
    esac
  done
}

ask_choice() {
  # ask_choice <title> <var_name> <opt1> <opt2> ...
  local title="$1"
  local var_name="$2"
  shift 2
  local options=("$@")

  echo ""
  echo "  $title"
  echo ""
  for i in "${!options[@]}"; do
    echo "    $((i+1))) ${options[$i]}"
  done
  echo ""

  local answer
  while true; do
    read -r -p "  Choose [1-${#options[@]}]: " answer
    if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= ${#options[@]} )); then
      printf -v "$var_name" '%s' "${options[$((answer-1))]}"
      return
    fi
    echo "  Please enter a number between 1 and ${#options[@]}."
  done
}

backup_path() {
  local src="$1"
  if [[ -e "$src" ]]; then
    local rel="${src/#$HOME\//}"
    local dest="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$dest")"
    cp -r "$src" "$dest"
    log_ok "Backed up: $src"
  fi
}

copy_config() {
  local src="$1"
  local dest="$2"
  if [[ ! -e "$src" ]]; then
    log_err "Source not found: $src"
    return 1
  fi
  if $DRY_RUN; then
    log_skip "[dry-run] Would copy $src → $dest"
    return
  fi
  if [[ "$CHOICE_BACKUP" == "yes" ]]; then
    backup_path "$dest"
  fi
  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    cp -r "$src/." "$dest/"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  fi
  log_ok "Installed: $dest"
}

# ─── Platform check ───────────────────────────────────────

check_platform() {
  if [[ "$(uname)" != "Darwin" ]]; then
    log_err "This installer only supports macOS. Detected: $(uname)"
    exit 1
  fi
  local arch
  arch="$(uname -m)"
  log_ok "macOS detected — arch: $arch"
}

# ─── Usage ────────────────────────────────────────────────

usage() {
  echo ""
  echo "  stildeeneca17-dots installer"
  echo ""
  echo "  Usage: ./install.sh [options]"
  echo ""
  echo "  Options:"
  echo "    --dry-run    Preview what would happen without making changes"
  echo "    --help       Show this help"
  echo ""
}

# ─── Parse args ───────────────────────────────────────────

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $arg"; usage; exit 1 ;;
  esac
done

# ══════════════════════════════════════════════════════════
#   STEP 1 — Welcome
# ══════════════════════════════════════════════════════════

clear
echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║          stildeeneca17-dots installer            ║"
echo "  ║        Personal dotfiles setup for macOS         ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""
echo "  This will install and configure your personal"
echo "  development environment on this machine."
echo ""

if $DRY_RUN; then
  echo "  ⚠️  DRY RUN MODE — no changes will be made"
  echo ""
fi

check_platform

# ══════════════════════════════════════════════════════════
#   STEP 2 — Ask questions (like Gentleman.Dots)
# ══════════════════════════════════════════════════════════

echo ""
echo "  ─────────────────────────────────────────────────"
echo "  Let's configure your setup"
echo "  ─────────────────────────────────────────────────"

# Shell
ask_choice "Step 1/5 — Choose your shell:" CHOICE_SHELL \
  "Fish (recommended — default shell)" \
  "Zsh (+ Oh My Zsh + Powerlevel10k)"

# Multiplexer
ask_choice "Step 2/5 — Choose your terminal multiplexer:" CHOICE_MULTIPLEXER \
  "Tmux (+ TPM plugins)" \
  "None — skip"

# Neovim
echo ""
ask_yn "Step 3/5 — Install Neovim with full config (LazyVim + plugins)?" CHOICE_NVIM "y"

# Font
echo ""
ask_yn "Step 4/5 — Install MesloLGS Nerd Font?" CHOICE_FONT "y"

# Backup
echo ""
ask_yn "Step 5/5 — Backup existing configs before overwriting?" CHOICE_BACKUP "y"

# Summary
echo ""
echo "  ─────────────────────────────────────────────────"
echo "  Your choices:"
echo ""
echo "    Shell:        $CHOICE_SHELL"
echo "    Multiplexer:  $CHOICE_MULTIPLEXER"
echo "    Neovim:       $CHOICE_NVIM"
echo "    Font:         $CHOICE_FONT"
echo "    Backup:       $CHOICE_BACKUP"
echo "  ─────────────────────────────────────────────────"
echo ""

ask_yn "Proceed with installation?" CONFIRM "y"
if [[ "$CONFIRM" != "yes" ]]; then
  echo ""
  echo "  Installation cancelled."
  exit 0
fi

# ══════════════════════════════════════════════════════════
#   STEP 3 — Backup
# ══════════════════════════════════════════════════════════

if [[ "$CHOICE_BACKUP" == "yes" ]] && ! $DRY_RUN; then
  log_step "📁 Creating backup at $BACKUP_DIR..."
  mkdir -p "$BACKUP_DIR"
  log_ok "Backup directory ready"
fi

# ══════════════════════════════════════════════════════════
#   STEP 4 — Homebrew
# ══════════════════════════════════════════════════════════

log_step "🍺 Homebrew..."
if check_tool brew; then
  log_skip "Already installed ($(brew --version | head -1))"
else
  log_info "Installing Homebrew..."
  if ! $DRY_RUN; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    if [[ "$(uname -m)" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    log_ok "Homebrew installed"
  else
    log_skip "[dry-run] Would install Homebrew"
  fi
fi

# ══════════════════════════════════════════════════════════
#   STEP 5 — Shell
# ══════════════════════════════════════════════════════════

log_step "🐚 Shell..."

if [[ "$CHOICE_SHELL" == Fish* ]]; then
  if ! check_tool fish; then
    log_info "Installing Fish..."
    $DRY_RUN || brew install fish
    log_ok "Fish installed"
  else
    log_skip "Fish already installed ($(fish --version 2>&1))"
  fi
  # Install Starship (used by Fish config)
  if ! check_tool starship; then
    log_info "Installing Starship prompt..."
    $DRY_RUN || brew install starship
    log_ok "Starship installed"
  else
    log_skip "Starship already installed"
  fi
  # Install Oh My Fish
  if [[ ! -d "$HOME/.local/share/omf" ]] && ! $DRY_RUN; then
    log_info "Installing Oh My Fish..."
    curl -L https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish -c "source /dev/stdin --noninteractive" 2>/dev/null || true
  fi
  # Copy Fish config
  copy_config "$REPO_DIR/stildeeneca17-fish/fish" "$HOME/.config/fish"
  # Copy Starship config
  copy_config "$REPO_DIR/starship.toml" "$HOME/.config/starship.toml"
  log_ok "Fish + Starship configured"

elif [[ "$CHOICE_SHELL" == Zsh* ]]; then
  if ! check_tool zsh; then
    log_info "Installing Zsh..."
    $DRY_RUN || brew install zsh zsh-syntax-highlighting zsh-autosuggestions
    log_ok "Zsh installed"
  else
    log_skip "Zsh already installed"
  fi
  # Install Oh My Zsh if not present
  if [[ ! -d "$HOME/.oh-my-zsh" ]] && ! $DRY_RUN; then
    log_info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null || true
    log_ok "Oh My Zsh installed"
  fi
  # Install Powerlevel10k
  if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]] && ! $DRY_RUN; then
    log_info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" 2>/dev/null || true
    log_ok "Powerlevel10k installed"
  fi
  copy_config "$REPO_DIR/stildeeneca17-zsh/.zshrc" "$HOME/.zshrc"
  copy_config "$REPO_DIR/stildeeneca17-zsh/.p10k.zsh" "$HOME/.p10k.zsh"
  log_ok "Zsh + P10k configured"
fi

# ══════════════════════════════════════════════════════════
#   STEP 6 — Terminal multiplexer
# ══════════════════════════════════════════════════════════

log_step "🪟 Terminal multiplexer..."

if [[ "$CHOICE_MULTIPLEXER" == Tmux* ]]; then
  if ! check_tool tmux; then
    log_info "Installing Tmux..."
    $DRY_RUN || brew install tmux
    log_ok "Tmux installed"
  else
    log_skip "Tmux already installed ($(tmux -V))"
  fi
  copy_config "$REPO_DIR/stildeeneca17-tmux/tmux.conf" "$HOME/.tmux.conf"
  # Bootstrap TPM
  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log_info "Installing TPM (Tmux Plugin Manager)..."
    if ! $DRY_RUN; then
      git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" --depth 1
      log_ok "TPM installed"
    else
      log_skip "[dry-run] Would clone TPM"
    fi
  else
    log_skip "TPM already installed"
  fi
  log_ok "Tmux configured"
else
  log_skip "Multiplexer skipped"
fi

# ══════════════════════════════════════════════════════════
#   STEP 7 — Neovim
# ══════════════════════════════════════════════════════════

log_step "📝 Neovim..."

if [[ "$CHOICE_NVIM" == "yes" ]]; then
  if ! check_tool nvim; then
    log_info "Installing Neovim and dependencies..."
    $DRY_RUN || brew install neovim git gcc fzf fd ripgrep coreutils bat curl lazygit node
    log_ok "Neovim installed"
  else
    log_skip "Neovim already installed ($(nvim --version | head -1))"
    # Install missing deps anyway
    $DRY_RUN || brew install fzf fd ripgrep bat lazygit node 2>/dev/null || true
  fi
  copy_config "$REPO_DIR/stildeeneca17-nvim/nvim" "$HOME/.config/nvim"
  log_ok "Neovim configured — plugins will install on first open"
else
  log_skip "Neovim skipped"
fi

# ══════════════════════════════════════════════════════════
#   STEP 8 — Font
# ══════════════════════════════════════════════════════════

log_step "🔤 Nerd Font..."

if [[ "$CHOICE_FONT" == "yes" ]]; then
  log_info "Installing MesloLGS Nerd Font..."
  if ! $DRY_RUN; then
    brew tap homebrew/cask-fonts 2>/dev/null || true
    brew install --cask font-meslo-lg-nerd-font 2>/dev/null || \
      log_info "Font may already be installed or unavailable via brew — check manually"
    log_ok "Font installed"
  else
    log_skip "[dry-run] Would install font"
  fi
else
  log_skip "Font skipped"
fi

# ══════════════════════════════════════════════════════════
#   STEP 9 — Git config
# ══════════════════════════════════════════════════════════

log_step "🔧 Git config..."
copy_config "$REPO_DIR/stildeeneca17-git/.gitconfig" "$HOME/.gitconfig"
copy_config "$REPO_DIR/stildeeneca17-git/.gitignore_global" "$HOME/.gitignore_global"
if ! $DRY_RUN; then
  git config --global core.excludesfile "$HOME/.gitignore_global" 2>/dev/null || true
fi
log_ok "Git configured"

# ══════════════════════════════════════════════════════════
#   STEP 10 — OpenCode
# ══════════════════════════════════════════════════════════

log_step "🤖 OpenCode config..."
if check_tool opencode; then
  copy_config "$REPO_DIR/stildeeneca17-opencode/opencode" "$HOME/.config/opencode"
  log_ok "OpenCode configured"
else
  log_skip "opencode not installed — skipping"
fi

# ══════════════════════════════════════════════════════════
#   STEP 11 — Set default shell
# ══════════════════════════════════════════════════════════

log_step "🐚 Setting default shell..."

if [[ "$CHOICE_SHELL" == Fish* ]]; then
  FISH_PATH="$(which fish 2>/dev/null || echo /opt/homebrew/bin/fish)"
  if [[ "$SHELL" != "$FISH_PATH" ]]; then
    if ! $DRY_RUN; then
      if ! grep -q "$FISH_PATH" /etc/shells 2>/dev/null; then
        echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
      fi
      chsh -s "$FISH_PATH"
      log_ok "Default shell set to Fish ($FISH_PATH)"
    else
      log_skip "[dry-run] Would set shell to $FISH_PATH"
    fi
  else
    log_skip "Fish is already the default shell"
  fi
elif [[ "$CHOICE_SHELL" == Zsh* ]]; then
  ZSH_PATH="$(which zsh 2>/dev/null || echo /bin/zsh)"
  if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    if ! $DRY_RUN; then
      chsh -s "$ZSH_PATH"
      log_ok "Default shell set to Zsh ($ZSH_PATH)"
    else
      log_skip "[dry-run] Would set shell to $ZSH_PATH"
    fi
  else
    log_skip "Zsh is already the default shell"
  fi
fi

# ══════════════════════════════════════════════════════════
#   Done
# ══════════════════════════════════════════════════════════

echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║           ✅  Installation complete!             ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""

if [[ "$CHOICE_BACKUP" == "yes" ]] && ! $DRY_RUN; then
  echo "  📁 Backup saved to: $BACKUP_DIR"
  echo ""
fi

echo "  Post-install steps:"
echo ""

if [[ "$CHOICE_SHELL" == Fish* ]]; then
  echo "    1. Reload shell:    exec fish"
fi
if [[ "$CHOICE_SHELL" == Zsh* ]]; then
  echo "    1. Reload shell:    exec zsh"
fi
if [[ "$CHOICE_MULTIPLEXER" == Tmux* ]]; then
  echo "    2. Tmux plugins:    open tmux → Ctrl+a then I"
fi
if [[ "$CHOICE_NVIM" == "yes" ]]; then
  echo "    3. Neovim plugins:  nvim  (auto-installs on first open)"
fi
echo "    4. Git email:       git config --global user.email \"you@example.com\""
echo ""
