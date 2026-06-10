#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════╗
# ║         stildeeneca17-dots installer         ║
# ║   Personal dotfiles for macOS (arm64/x86)    ║
# ╚══════════════════════════════════════════════╝

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.stildeeneca_backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false

# ── Helpers ──────────────────────────────────────

log_step() {
  echo ""
  echo "  $1"
}

log_ok() { echo "  ✅ $1"; }
log_skip() { echo "  ⏭️  $1"; }
log_err() { echo "  ❌ $1"; }

check_tool() {
  command -v "$1" &>/dev/null
}

backup_path() {
  local src="$1"
  if [[ -e "$src" ]]; then
    local rel="${src/#$HOME\//}"
    local dest="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$dest")"
    if $DRY_RUN; then
      log_skip "[dry-run] Would backup $src → $dest"
    else
      cp -r "$src" "$dest"
      log_ok "Backed up $src"
    fi
  fi
}

copy_config() {
  local src="$1"
  local dest="$2"
  if [[ ! -e "$src" ]]; then
    log_err "Source not found: $src"
    return 1
  fi
  backup_path "$dest"
  if $DRY_RUN; then
    log_skip "[dry-run] Would copy $src → $dest"
  else
    if [[ -d "$src" ]]; then
      mkdir -p "$dest"
      cp -r "$src/." "$dest/"
    else
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
    fi
    log_ok "Copied $src → $dest"
  fi
}

install_homebrew() {
  if check_tool brew; then
    log_skip "Homebrew already installed ($(brew --version | head -1))"
    return
  fi
  log_step "📦 Installing Homebrew..."
  if $DRY_RUN; then
    log_skip "[dry-run] Would install Homebrew"
    return
  fi
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  log_ok "Homebrew installed"
}

run_brewfile() {
  if [[ ! -f "$REPO_DIR/Brewfile" ]]; then
    log_err "Brewfile not found in $REPO_DIR"
    return 1
  fi
  if $DRY_RUN; then
    log_skip "[dry-run] Would run: brew bundle --file=$REPO_DIR/Brewfile"
    return
  fi
  log_step "🍺 Installing Brewfile packages..."
  brew bundle --file="$REPO_DIR/Brewfile" --no-lock || true
  log_ok "Brewfile done"
}

# ── Platform check ────────────────────────────────

check_platform() {
  if [[ "$(uname)" != "Darwin" ]]; then
    log_err "This installer only supports macOS. Detected: $(uname)"
    exit 1
  fi
  local arch
  arch=$(uname -m)
  log_ok "macOS detected — arch: $arch"
}

# ── Usage ─────────────────────────────────────────

usage() {
  echo ""
  echo "  stildeeneca17-dots installer"
  echo ""
  echo "  Usage: ./install.sh [options]"
  echo ""
  echo "  Options:"
  echo "    --dry-run    Show what would happen without making changes"
  echo "    --help       Show this help"
  echo ""
}

# ── Parse args ────────────────────────────────────

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $arg"; usage; exit 1 ;;
  esac
done

# ── Main ──────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║       stildeeneca17-dots installer           ║"
echo "╚══════════════════════════════════════════════╝"

if $DRY_RUN; then
  echo "  [DRY RUN MODE — no changes will be made]"
fi

log_step "🔍 Checking platform..."
check_platform

log_step "📁 Creating backup dir: $BACKUP_DIR"
if ! $DRY_RUN; then
  mkdir -p "$BACKUP_DIR"
  log_ok "Backup dir created"
else
  log_skip "[dry-run] Would create $BACKUP_DIR"
fi

log_step "🍺 Homebrew..."
install_homebrew

log_step "📦 Installing dependencies from Brewfile..."
run_brewfile

log_step "🐟 Fish shell config..."
if check_tool fish; then
  copy_config "$REPO_DIR/StildeenecaFish/fish" "$HOME/.config/fish"
  log_ok "Fish config installed"
else
  log_skip "fish not installed — skipping"
fi

log_step "💤 Zsh config..."
if check_tool zsh; then
  copy_config "$REPO_DIR/StildeenecaZsh/.zshrc" "$HOME/.zshrc"
  if [[ -f "$REPO_DIR/StildeenecaZsh/.p10k.zsh" ]]; then
    copy_config "$REPO_DIR/StildeenecaZsh/.p10k.zsh" "$HOME/.p10k.zsh"
  fi
  log_ok "Zsh config installed"
else
  log_skip "zsh not installed — skipping"
fi

log_step "📝 Neovim config..."
if check_tool nvim; then
  copy_config "$REPO_DIR/StildeenecaNvim/nvim" "$HOME/.config/nvim"
  log_ok "Neovim config installed"
else
  log_skip "nvim not installed — skipping"
fi

log_step "🪟 Tmux config..."
if check_tool tmux; then
  copy_config "$REPO_DIR/StildeenecaTmux/tmux.conf" "$HOME/.tmux.conf"
  # Bootstrap TPM if not present
  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    if ! $DRY_RUN; then
      git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" --depth 1
      log_ok "TPM installed"
    else
      log_skip "[dry-run] Would clone TPM"
    fi
  else
    log_skip "TPM already installed"
  fi
  log_ok "Tmux config installed"
else
  log_skip "tmux not installed — skipping"
fi

log_step "⭐ Starship config..."
if check_tool starship; then
  copy_config "$REPO_DIR/starship.toml" "$HOME/.config/starship.toml"
  log_ok "Starship config installed"
else
  log_skip "starship not installed — skipping"
fi

log_step "🔧 Git config..."
copy_config "$REPO_DIR/StildeenecaGit/.gitconfig" "$HOME/.gitconfig"
copy_config "$REPO_DIR/StildeenecaGit/.gitignore_global" "$HOME/.gitignore_global"
git config --global core.excludesfile "$HOME/.gitignore_global" 2>/dev/null || true
log_ok "Git config installed"

log_step "🤖 OpenCode config..."
if check_tool opencode; then
  copy_config "$REPO_DIR/StildeenecaOpencode/opencode" "$HOME/.config/opencode"
  log_ok "OpenCode config installed"
else
  log_skip "opencode not installed — skipping"
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         ✅  Installation complete!           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Backup saved to: $BACKUP_DIR"
echo ""
echo "  Post-install:"
echo "    • Reload shell:   exec fish  (or exec zsh)"
echo "    • Install plugins: tmux, then press prefix + I"
echo "    • Open nvim:       nvim  (plugins will auto-install)"
echo ""
