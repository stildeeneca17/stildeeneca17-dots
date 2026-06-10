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

ask_yn() {
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

patch_file() {
  # patch_file <file> <search> <replacement>
  local file="$1"
  local search="$2"
  local replacement="$3"
  if [[ -f "$file" ]]; then
    local tmp
    tmp="$(mktemp)"
    sed "s|${search}|${replacement}|g" "$file" > "$tmp" && mv "$tmp" "$file"
  fi
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
#   STEP 2 — Questions
# ══════════════════════════════════════════════════════════

echo ""
echo "  ─────────────────────────────────────────────────"
echo "  Let's configure your setup"
echo "  ─────────────────────────────────────────────────"

ask_choice "Step 1/5 — Choose your shell:" CHOICE_SHELL \
  "Fish (+ carapace, zoxide, atuin, starship)" \
  "Zsh (+ Oh My Zsh, P10k, carapace, zoxide, atuin)"

ask_choice "Step 2/5 — Choose your terminal multiplexer:" CHOICE_MULTIPLEXER \
  "Tmux (+ TPM + plugins auto-install)" \
  "None — skip"

echo ""
ask_yn "Step 3/5 — Install Neovim with full config? (LazyVim + OpenCode + Claude Code)" CHOICE_NVIM "y"

echo ""
ask_yn "Step 4/5 — Install MesloLGS Nerd Font?" CHOICE_FONT "y"

echo ""
ask_yn "Step 5/5 — Backup existing configs before overwriting?" CHOICE_BACKUP "y"

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

# Create required dirs (same as Gentleman.Dots)
if ! $DRY_RUN; then
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.cache/starship"
  mkdir -p "$HOME/.cache/carapace"
  mkdir -p "$HOME/.local/share/atuin"
fi

if [[ "$CHOICE_SHELL" == Fish* ]]; then
  log_info "Installing Fish + carapace + zoxide + atuin + starship..."
  if ! $DRY_RUN; then
    brew install fish carapace zoxide atuin starship
  else
    log_skip "[dry-run] Would install: fish carapace zoxide atuin starship"
  fi
  copy_config "$REPO_DIR/stildeeneca17-fish/fish" "$HOME/.config/fish"
  copy_config "$REPO_DIR/starship.toml" "$HOME/.config/starship.toml"
  # Patch tmux default shell placeholder in config.fish (if tmux chosen)
  if [[ "$CHOICE_MULTIPLEXER" == Tmux* ]] && ! $DRY_RUN; then
    FISH_PATH="$(which fish 2>/dev/null || echo /opt/homebrew/bin/fish)"
    patch_file "$HOME/.config/fish/config.fish" "# STILDEENECA_DEFAULT_SHELL" \
      "set -gx SHELL $FISH_PATH"
  fi
  # direnv — load .env per directory
  if ! check_tool direnv; then
    log_info "Installing direnv..."
    $DRY_RUN || brew install direnv
  else
    log_skip "direnv already installed"
  fi
  log_ok "Fish configured"

elif [[ "$CHOICE_SHELL" == Zsh* ]]; then
  log_info "Installing Zsh + carapace + zoxide + atuin + p10k + plugins..."
  if ! $DRY_RUN; then
    brew install zsh carapace zoxide atuin zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete powerlevel10k
  else
    log_skip "[dry-run] Would install: zsh + plugins"
  fi
  # Oh My Zsh
  if [[ ! -d "$HOME/.oh-my-zsh" ]] && ! $DRY_RUN; then
    log_info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null || true
  fi
  copy_config "$REPO_DIR/stildeeneca17-zsh/.zshrc" "$HOME/.zshrc"
  copy_config "$REPO_DIR/stildeeneca17-zsh/.p10k.zsh" "$HOME/.p10k.zsh"
  # direnv — load .env per directory
  if ! check_tool direnv; then
    log_info "Installing direnv..."
    $DRY_RUN || brew install direnv
  else
    log_skip "direnv already installed"
  fi
  log_ok "Zsh configured"
fi

# ══════════════════════════════════════════════════════════
#   STEP 6 — Terminal multiplexer
# ══════════════════════════════════════════════════════════

log_step "🪟 Terminal multiplexer..."

if [[ "$CHOICE_MULTIPLEXER" == Tmux* ]]; then
  if ! check_tool tmux; then
    log_info "Installing Tmux..."
    $DRY_RUN || brew install tmux
  else
    log_skip "Tmux already installed ($(tmux -V))"
  fi

  # Clone TPM if not present
  TPM_DIR="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$TPM_DIR" ]]; then
    log_info "Cloning TPM (Tmux Plugin Manager)..."
    if ! $DRY_RUN; then
      git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" --depth 1
      log_ok "TPM cloned"
    else
      log_skip "[dry-run] Would clone TPM"
    fi
  else
    log_skip "TPM already present"
  fi

  copy_config "$REPO_DIR/stildeeneca17-tmux/tmux.conf" "$HOME/.tmux.conf"

  # Patch default shell in tmux.conf (same as Gentleman.Dots)
  if ! $DRY_RUN; then
    SHELL_BIN=""
    if [[ "$CHOICE_SHELL" == Fish* ]]; then
      SHELL_BIN="$(which fish 2>/dev/null || echo /opt/homebrew/bin/fish)"
    elif [[ "$CHOICE_SHELL" == Zsh* ]]; then
      SHELL_BIN="$(which zsh 2>/dev/null || echo /bin/zsh)"
    fi
    if [[ -n "$SHELL_BIN" ]]; then
      SHELL_CONFIG="set -g default-command \"$SHELL_BIN\"\nset -g default-shell \"$SHELL_BIN\""
      patch_file "$HOME/.tmux.conf" "# STILDEENECA_DEFAULT_SHELL" "$SHELL_CONFIG"
    fi
  fi

  # Auto-install plugins via TPM (same as Gentleman.Dots)
  log_info "Installing Tmux plugins via TPM..."
  if ! $DRY_RUN; then
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || \
      log_info "TPM plugin install had issues — run Ctrl+a I in tmux to retry"
    log_ok "Tmux configured + plugins installed"
  else
    log_skip "[dry-run] Would run TPM install_plugins"
  fi

else
  log_skip "Multiplexer skipped"
fi

# ══════════════════════════════════════════════════════════
#   STEP 7 — Neovim + AI tools
# ══════════════════════════════════════════════════════════

log_step "📝 Neovim..."

if [[ "$CHOICE_NVIM" == "yes" ]]; then
  # Ensure Node.js (required for LSP)
  if ! check_tool node; then
    log_info "Installing Node.js..."
    $DRY_RUN || brew install node
    log_ok "Node.js installed"
  else
    log_skip "Node.js already installed ($(node --version))"
  fi

  # Install Neovim + all dependencies (same list as Gentleman.Dots)
  log_info "Installing Neovim and dependencies..."
  if ! $DRY_RUN; then
    brew install nvim git gcc fzf fd ripgrep coreutils bat curl lazygit tree-sitter
  else
    log_skip "[dry-run] Would install: nvim git gcc fzf fd ripgrep coreutils bat curl lazygit tree-sitter"
  fi

  # Create Obsidian dirs (same as Gentleman.Dots)
  if ! $DRY_RUN; then
    mkdir -p "$HOME/.config/obsidian/templates"
  fi

  copy_config "$REPO_DIR/stildeeneca17-nvim/nvim" "$HOME/.config/nvim"
  log_ok "Neovim configured — plugins install on first open"

  # ── AI CLI tools (all installed as part of nvim step, same as Gentleman.Dots) ──

  # OpenCode
  log_info "Installing OpenCode..."
  if ! $DRY_RUN; then
    if check_tool opencode; then
      log_skip "OpenCode already installed ($(opencode version 2>/dev/null | head -1 || echo 'installed'))"
    else
      curl -fsSL https://opencode.ai/install | bash || \
        log_info "OpenCode install failed — install manually: https://opencode.ai"
    fi
  else
    log_skip "[dry-run] Would install OpenCode"
  fi

  # Copy OpenCode config (now that it's installed)
  if check_tool opencode || $DRY_RUN; then
    copy_config "$REPO_DIR/stildeeneca17-opencode/opencode" "$HOME/.config/opencode"
    log_ok "OpenCode config installed"
  fi

  # Claude Code
  log_info "Installing Claude Code..."
  if ! $DRY_RUN; then
    if check_tool claude; then
      log_skip "Claude Code already installed"
    else
      curl -fsSL https://claude.ai/install.sh | bash || \
        log_info "Claude Code install failed — install manually: https://claude.ai/code"
    fi
  else
    log_skip "[dry-run] Would install Claude Code"
  fi

  # Codex CLI (OpenAI)
  log_info "Installing Codex CLI..."
  if ! $DRY_RUN; then
    if check_tool codex; then
      log_skip "Codex CLI already installed"
    else
      curl -fsSL https://chatgpt.com/codex/install.sh | sh || \
        log_info "Codex CLI install failed — install manually: https://developers.openai.com/codex/cli"
    fi
  else
    log_skip "[dry-run] Would install Codex CLI"
  fi

  # Gemini CLI
  log_info "Installing Gemini CLI..."
  if ! $DRY_RUN; then
    if check_tool gemini; then
      log_skip "Gemini CLI already installed"
    else
      brew install gemini-cli || \
        log_info "Gemini CLI install failed — install manually: https://geminicli.com/docs/get-started/installation"
    fi
  else
    log_skip "[dry-run] Would install Gemini CLI"
  fi

  # Engram (persistent memory for AI agents)
  log_info "Installing Engram..."
  if ! $DRY_RUN; then
    if check_tool engram; then
      log_skip "Engram already installed ($(engram version 2>/dev/null || echo 'installed'))"
    else
      brew install gentleman-programming/tap/engram || \
        log_info "Engram install failed — install manually: https://github.com/Gentleman-Programming/engram"
    fi
  else
    log_skip "[dry-run] Would install Engram"
  fi

  # Gentle-AI + GGA
  log_info "Installing Gentle-AI and GGA..."
  if ! $DRY_RUN; then
    brew install gentleman-programming/tap/gentle-ai 2>/dev/null || \
      log_info "gentle-ai install failed — install manually: https://github.com/Gentleman-Programming/gentle-ai"
    brew install gentleman-programming/tap/gga 2>/dev/null || \
      log_info "gga install failed — install manually: https://github.com/Gentleman-Programming/gentleman-guardian-angel"
  else
    log_skip "[dry-run] Would install gentle-ai and gga"
  fi

else
  log_skip "Neovim skipped"
fi

# ══════════════════════════════════════════════════════════
#   STEP 8 — CLI utilities
# ══════════════════════════════════════════════════════════

log_step "🛠️  CLI utilities..."

# These tools have no config to copy — just install them
UTILS=(
  "eza:eza"
  "bat:bat"
  "fzf:fzf"
  "fd:fd"
  "zoxide:zoxide"
  "atuin:atuin"
  "btop:btop"
  "tldr:tldr"
  "xh:xh"
  "fastfetch:fastfetch"
  "mkcert:mkcert"
  "wget:wget"
  "htop:htop"
  "lazydocker:lazydocker"
  "stern:stern"
  "jq:jq"
  "yq:yq"
  "tree:tree"
  "shellcheck:shellcheck"
)

for entry in "${UTILS[@]}"; do
  cmd="${entry%%:*}"
  pkg="${entry##*:}"
  if check_tool "$cmd"; then
    log_skip "$cmd already installed"
  else
    log_info "Installing $pkg..."
    $DRY_RUN || brew install "$pkg" || log_info "$pkg install failed — run: brew install $pkg"
  fi
done

log_ok "CLI utilities done"

# ══════════════════════════════════════════════════════════
#   STEP 9 — Font
# ══════════════════════════════════════════════════════════

log_step "🔤 Nerd Font..."

if [[ "$CHOICE_FONT" == "yes" ]]; then
  log_info "Installing MesloLGS Nerd Font..."
  if ! $DRY_RUN; then
    brew tap homebrew/cask-fonts 2>/dev/null || true
    brew install --cask font-meslo-lg-nerd-font || \
      log_info "Font may already be installed — check Font Book"
    log_ok "Font installed"
  else
    log_skip "[dry-run] Would install MesloLGS Nerd Font"
  fi
else
  log_skip "Font skipped"
fi

# ══════════════════════════════════════════════════════════
#   STEP 10 — Git config
# ══════════════════════════════════════════════════════════

log_step "🔧 Git config..."

# Install git-delta (better diffs) — it patches .gitconfig automatically
if ! check_tool delta; then
  log_info "Installing git-delta..."
  $DRY_RUN || brew install git-delta
else
  log_skip "git-delta already installed ($(delta --version 2>/dev/null))"
fi

copy_config "$REPO_DIR/stildeeneca17-git/.gitconfig" "$HOME/.gitconfig"
copy_config "$REPO_DIR/stildeeneca17-git/.gitignore_global" "$HOME/.gitignore_global"
if ! $DRY_RUN; then
  git config --global core.excludesfile "$HOME/.gitignore_global" 2>/dev/null || true
fi
log_ok "Git configured"

# ══════════════════════════════════════════════════════════
#   STEP 11 — Set default shell
# ══════════════════════════════════════════════════════════

log_step "🐚 Setting default shell..."

if [[ "$CHOICE_SHELL" == Fish* ]]; then
  SHELL_PATH="$(which fish 2>/dev/null || echo /opt/homebrew/bin/fish)"
elif [[ "$CHOICE_SHELL" == Zsh* ]]; then
  SHELL_PATH="$(which zsh 2>/dev/null || echo /bin/zsh)"
else
  SHELL_PATH=""
fi

if [[ -n "$SHELL_PATH" ]]; then
  if [[ "$SHELL" == "$SHELL_PATH" ]]; then
    log_skip "$SHELL_PATH is already the default shell"
  else
    if ! $DRY_RUN; then
      if ! grep -qF "$SHELL_PATH" /etc/shells 2>/dev/null; then
        echo "$SHELL_PATH" | sudo tee -a /etc/shells > /dev/null
      fi
      chsh -s "$SHELL_PATH"
      log_ok "Default shell set to $SHELL_PATH"
    else
      log_skip "[dry-run] Would set default shell to $SHELL_PATH"
    fi
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
  echo "    1. Reload shell:  exec fish"
elif [[ "$CHOICE_SHELL" == Zsh* ]]; then
  echo "    1. Reload shell:  exec zsh"
fi
if [[ "$CHOICE_MULTIPLEXER" == Tmux* ]]; then
  echo "    2. Tmux plugins:  already installed — or press Ctrl+a I to reinstall"
fi
if [[ "$CHOICE_NVIM" == "yes" ]]; then
  echo "    3. Neovim:        nvim  (plugins auto-install on first open)"
fi
echo "    4. Git email:     git config --global user.email \"you@example.com\""
echo ""
