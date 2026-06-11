#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.stildeeneca_backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
DO_BACKUP="yes"

# ══════════════════════════════════════════════════════════
#   COLORS
# ══════════════════════════════════════════════════════════

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

BLACK="\033[0;30m"
WHITE="\033[0;37m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"

BOLD_WHITE="\033[1;37m"
BOLD_GREEN="\033[1;32m"
BOLD_YELLOW="\033[1;33m"
BOLD_BLUE="\033[1;34m"
BOLD_CYAN="\033[1;36m"
BOLD_MAGENTA="\033[1;35m"
BOLD_RED="\033[1;31m"

# ══════════════════════════════════════════════════════════
#   HELPERS
# ══════════════════════════════════════════════════════════

check_tool() { command -v "$1" &>/dev/null; }

log_step()  { echo ""; echo -e "  ${BOLD_CYAN}$1${RESET}"; }
log_ok()    { echo -e "  ${BOLD_GREEN}✅${RESET}  $1"; }
log_skip()  { echo -e "  ${DIM}⏭   $1${RESET}"; }
log_info()  { echo -e "  ${BLUE}›${RESET}   $1"; }
log_err()   { echo -e "  ${BOLD_RED}✗${RESET}   $1"; }
log_warn()  { echo -e "  ${BOLD_YELLOW}⚠${RESET}   $1"; }

ask_yn() {
  local question="$1"
  local var_name="$2"
  local default="${3:-y}"
  local answer
  while true; do
    if [[ "$default" == "y" ]]; then
      read -r -p "$(echo -e "  ${BOLD_WHITE}$question${RESET} ${DIM}[Y/n]${RESET} ")" answer
      answer="${answer:-y}"
    else
      read -r -p "$(echo -e "  ${BOLD_WHITE}$question${RESET} ${DIM}[y/N]${RESET} ")" answer
      answer="${answer:-n}"
    fi
    case "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" in
      y|yes) printf -v "$var_name" '%s' "yes"; return ;;
      n|no)  printf -v "$var_name" '%s' "no";  return ;;
      *) echo -e "  ${YELLOW}Please answer y or n.${RESET}" ;;
    esac
  done
}

backup_path() {
  local src="$1"
  if [[ -e "$src" ]]; then
    local rel="${src/#$HOME\//}"
    local dest="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$dest")"
    cp -r "$src" "$dest"
    log_ok "Backed up: ${DIM}$src${RESET}"
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
    log_skip "[dry-run] Would copy $(basename "$src") → $dest"
    return
  fi
  if [[ "$DO_BACKUP" == "yes" ]]; then
    backup_path "$dest"
  fi
  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    cp -r "$src/." "$dest/"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  fi
  log_ok "$(basename "$src") → ${DIM}$dest${RESET}"
}

patch_file() {
  local file="$1" search="$2" replacement="$3"
  if [[ -f "$file" ]]; then
    local tmp
    tmp="$(mktemp)"
    sed "s|${search}|${replacement}|g" "$file" > "$tmp" && mv "$tmp" "$file"
  fi
}

install_brew_pkg() {
  local cmd="$1"
  local pkg="${2:-$1}"
  if check_tool "$cmd"; then
    log_skip "$cmd already installed"
  else
    log_info "Installing ${BOLD_WHITE}$pkg${RESET}..."
    if ! $DRY_RUN; then
      brew install "$pkg" 2>/dev/null || log_warn "$pkg install failed — run: brew install $pkg"
    else
      log_skip "[dry-run] Would install $pkg"
    fi
  fi
}

# ══════════════════════════════════════════════════════════
#   PARSE ARGS
# ══════════════════════════════════════════════════════════

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --help)
      echo ""
      echo -e "  ${BOLD_WHITE}stildeeneca17-dots installer${RESET}"
      echo ""
      echo "  Usage: ./install.sh [--dry-run] [--help]"
      echo ""
      echo "  --dry-run   Preview all steps without making any changes"
      echo "  --help      Show this help"
      echo ""
      exit 0 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# ══════════════════════════════════════════════════════════
#   WELCOME SCREEN
# ══════════════════════════════════════════════════════════

clear
echo ""
echo -e "  ${BOLD_CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_WHITE}  stildeeneca17-dots${RESET}"
echo -e "  ${DIM}  Personal dotfiles for macOS${RESET}"
echo -e "  ${BOLD_CYAN}──────────────────────────────────────────────────────${RESET}"
echo ""

# Platform check
if [[ "$(uname)" != "Darwin" ]]; then
  log_err "This installer only supports macOS. Detected: $(uname)"
  exit 1
fi
ARCH="$(uname -m)"
[[ "$ARCH" == "arm64" ]] && ARCH_LABEL="Apple Silicon (arm64)" || ARCH_LABEL="Intel (x86_64)"
echo -e "  ${GREEN}✓${RESET}  macOS detected — ${BOLD_WHITE}$ARCH_LABEL${RESET}"

if $DRY_RUN; then
  echo ""
  echo -e "  ${BOLD_YELLOW}DRY RUN MODE — no changes will be made${RESET}"
fi

# ══════════════════════════════════════════════════════════
#   PLAN SUMMARY
# ══════════════════════════════════════════════════════════

echo ""
echo -e "  ${BOLD_WHITE}Here's what will be installed:${RESET}"
echo ""
echo -e "  ${CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_MAGENTA}  Shell${RESET}        Fish ${DIM}(default)${RESET} + Zsh"
echo -e "               ${DIM}carapace · zoxide · atuin · starship${RESET}"
echo -e "               ${DIM}direnv · Oh My Zsh · Powerlevel10k${RESET}"
echo -e "  ${CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_MAGENTA}  Multiplexer${RESET}  Tmux ${DIM}+ TPM + plugins (auto-installed)${RESET}"
echo -e "  ${CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_MAGENTA}  Editor${RESET}       Neovim ${DIM}(LazyVim · LSP · treesitter)${RESET}"
echo -e "  ${CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_MAGENTA}  AI tools${RESET}     OpenCode · Claude · Codex · Gemini"
echo -e "               ${DIM}Engram · Gentle-AI · GGA${RESET}"
echo -e "  ${CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_MAGENTA}  CLI utils${RESET}    eza · bat · fzf · fd · delta · btop"
echo -e "               ${DIM}lazydocker · stern · xh · tldr · mkcert${RESET}"
echo -e "  ${CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_MAGENTA}  DevOps${RESET}       kubectl · helm · k9s · argocd · flux"
echo -e "               ${DIM}terraform · azure-cli · skopeo · docker${RESET}"
echo -e "  ${CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_MAGENTA}  Languages${RESET}    Node · Python (pyenv) · Deno"
echo -e "               ${DIM}pnpm · uv · poetry${RESET}"
echo -e "  ${CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_MAGENTA}  Git${RESET}          gitconfig · gitignore · delta diffs"
echo -e "  ${CYAN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_MAGENTA}  Font${RESET}         MesloLGS Nerd Font"
echo -e "  ${CYAN}──────────────────────────────────────────────────────${RESET}"
echo ""

# One question: backup?
ask_yn "Backup existing configs before overwriting?" DO_BACKUP "y"
echo ""

# Final confirm
ask_yn "Proceed with installation?" CONFIRM "y"
if [[ "$CONFIRM" != "yes" ]]; then
  echo ""
  echo -e "  ${DIM}Installation cancelled.${RESET}"
  echo ""
  exit 0
fi

# ══════════════════════════════════════════════════════════
#   BACKUP
# ══════════════════════════════════════════════════════════

if [[ "$DO_BACKUP" == "yes" ]] && ! $DRY_RUN; then
  log_step "📁  Backup"
  mkdir -p "$BACKUP_DIR"
  log_ok "Backup dir: ${DIM}$BACKUP_DIR${RESET}"
fi

# ══════════════════════════════════════════════════════════
#   HOMEBREW
# ══════════════════════════════════════════════════════════

log_step "🍺  Homebrew"
if check_tool brew; then
  log_skip "Already installed ($(brew --version | head -1))"
else
  log_info "Installing Homebrew..."
  if ! $DRY_RUN; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$ARCH" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    log_ok "Homebrew installed"
  else
    log_skip "[dry-run] Would install Homebrew"
  fi
fi

# ══════════════════════════════════════════════════════════
#   SHELL — Fish (default) + Zsh
# ══════════════════════════════════════════════════════════

log_step "🐚  Shell — Fish + Zsh"

if ! $DRY_RUN; then
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.cache/starship"
  mkdir -p "$HOME/.cache/carapace"
  mkdir -p "$HOME/.local/share/atuin"
fi

# Fish + shell tools
log_info "Installing Fish + carapace + zoxide + atuin + starship..."
if ! $DRY_RUN; then
  brew install fish carapace zoxide atuin starship
else
  log_skip "[dry-run] Would install fish carapace zoxide atuin starship"
fi

# Zsh + plugins
log_info "Installing Zsh + plugins + Powerlevel10k..."
if ! $DRY_RUN; then
  brew install zsh zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete powerlevel10k
else
  log_skip "[dry-run] Would install zsh + plugins"
fi

# Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log_info "Installing Oh My Zsh..."
  if ! $DRY_RUN; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null || true
    log_ok "Oh My Zsh installed"
  else
    log_skip "[dry-run] Would install Oh My Zsh"
  fi
else
  log_skip "Oh My Zsh already installed"
fi

# Powerlevel10k — must be cloned into OMZ custom themes (brew install alone is not enough)
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
  log_info "Installing Powerlevel10k theme into Oh My Zsh..."
  if ! $DRY_RUN; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" 2>/dev/null || \
      log_warn "Powerlevel10k clone failed — run manually: git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $P10K_DIR"
    log_ok "Powerlevel10k installed"
  else
    log_skip "[dry-run] Would clone Powerlevel10k into $P10K_DIR"
  fi
else
  log_skip "Powerlevel10k already in OMZ themes"
fi

# direnv
install_brew_pkg direnv direnv

# Copy Fish config + Starship
copy_config "$REPO_DIR/stildeeneca17-fish/fish" "$HOME/.config/fish"
copy_config "$REPO_DIR/starship.toml" "$HOME/.config/starship.toml"

# Copy Zsh config
copy_config "$REPO_DIR/stildeeneca17-zsh/.zshrc" "$HOME/.zshrc"
copy_config "$REPO_DIR/stildeeneca17-zsh/.p10k.zsh" "$HOME/.p10k.zsh"

log_ok "Fish + Zsh configured"

# ══════════════════════════════════════════════════════════
#   TMUX
# ══════════════════════════════════════════════════════════

log_step "🪟  Tmux"

install_brew_pkg tmux tmux

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  log_info "Cloning TPM..."
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

# Auto-install plugins
log_info "Installing Tmux plugins via TPM..."
if ! $DRY_RUN; then
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || \
    log_warn "TPM plugin install had issues — press Ctrl+b I in tmux to retry"
  log_ok "Tmux plugins installed"
else
  log_skip "[dry-run] Would run TPM install_plugins"
fi

# ══════════════════════════════════════════════════════════
#   NEOVIM
# ══════════════════════════════════════════════════════════

log_step "📝  Neovim"

# Node.js (LSP requirement)
if ! check_tool node; then
  log_info "Installing Node.js..."
  $DRY_RUN || brew install node
else
  log_skip "Node.js already installed ($(node --version))"
fi

# Neovim + deps
log_info "Installing Neovim and dependencies..."
if ! $DRY_RUN; then
  brew install nvim git gcc fzf fd ripgrep coreutils bat curl lazygit tree-sitter
else
  log_skip "[dry-run] Would install nvim + deps"
fi

if ! $DRY_RUN; then
  mkdir -p "$HOME/.config/obsidian/templates"
fi

copy_config "$REPO_DIR/stildeeneca17-nvim/nvim" "$HOME/.config/nvim"
log_ok "Neovim configured"

# ══════════════════════════════════════════════════════════
#   AI TOOLS
# ══════════════════════════════════════════════════════════

log_step "🤖  AI tools"

# OpenCode
if check_tool opencode; then
  log_skip "OpenCode already installed"
else
  log_info "Installing OpenCode..."
  $DRY_RUN || curl -fsSL https://opencode.ai/install | bash || \
    log_warn "OpenCode failed — install manually: https://opencode.ai"
fi
copy_config "$REPO_DIR/stildeeneca17-opencode/opencode" "$HOME/.config/opencode"

# Claude Code
if check_tool claude; then
  log_skip "Claude Code already installed"
else
  log_info "Installing Claude Code..."
  $DRY_RUN || curl -fsSL https://claude.ai/install.sh | bash || \
    log_warn "Claude Code failed — install manually: https://claude.ai/code"
fi

# Codex CLI
if check_tool codex; then
  log_skip "Codex CLI already installed"
else
  log_info "Installing Codex CLI..."
  $DRY_RUN || curl -fsSL https://chatgpt.com/codex/install.sh | sh || \
    log_warn "Codex CLI failed — install manually: https://developers.openai.com/codex/cli"
fi

# Gemini CLI
install_brew_pkg gemini gemini-cli

# Engram
if check_tool engram; then
  log_skip "Engram already installed ($(engram version 2>/dev/null || echo 'ok'))"
else
  log_info "Installing Engram..."
  $DRY_RUN || brew install gentleman-programming/tap/engram || \
    log_warn "Engram failed — install manually: https://github.com/Gentleman-Programming/engram"
fi

# Gentle-AI
if check_tool gentle-ai; then
  log_skip "Gentle-AI already installed"
else
  log_info "Installing Gentle-AI..."
  $DRY_RUN || brew install gentleman-programming/tap/gentle-ai || \
    log_warn "Gentle-AI failed — https://github.com/Gentleman-Programming/gentle-ai"
fi

# GGA
if check_tool gga; then
  log_skip "GGA already installed"
else
  log_info "Installing GGA..."
  $DRY_RUN || brew install gentleman-programming/tap/gga || \
    log_warn "GGA failed — https://github.com/Gentleman-Programming/gentleman-guardian-angel"
fi

log_ok "AI tools done"

# ══════════════════════════════════════════════════════════
#   CLI UTILITIES
# ══════════════════════════════════════════════════════════

log_step "🛠   CLI utilities"

CLI_UTILS=(
  "eza:eza"
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
  "pnpm:pnpm"
  "poetry:poetry"
)

for entry in "${CLI_UTILS[@]}"; do
  install_brew_pkg "${entry%%:*}" "${entry##*:}"
done

log_ok "CLI utilities done"

# ══════════════════════════════════════════════════════════
#   DEVOPS
# ══════════════════════════════════════════════════════════

log_step "☁   DevOps"

DEVOPS_UTILS=(
  "kubectl:kubernetes-cli"
  "helm:helm"
  "k9s:k9s"
  "stern:stern"
  "argocd:argocd"
  "flux:fluxcd/tap/flux"
  "terraform:hashicorp/tap/terraform"
  "skopeo:skopeo"
  "az:azure-cli"
)

for entry in "${DEVOPS_UTILS[@]}"; do
  install_brew_pkg "${entry%%:*}" "${entry##*:}"
done

log_ok "DevOps tools done"

# ══════════════════════════════════════════════════════════
#   FONT
# ══════════════════════════════════════════════════════════

log_step "🔤  Nerd Font"

log_info "Installing MesloLGS Nerd Font..."
if ! $DRY_RUN; then
  brew tap homebrew/cask-fonts 2>/dev/null || true
  brew install --cask font-meslo-lg-nerd-font 2>/dev/null || \
    log_skip "Font already installed or unavailable — check Font Book"
  log_ok "MesloLGS Nerd Font installed"
else
  log_skip "[dry-run] Would install MesloLGS Nerd Font"
fi

# ══════════════════════════════════════════════════════════
#   GIT
# ══════════════════════════════════════════════════════════

log_step "🔧  Git"

install_brew_pkg git git
install_brew_pkg gh gh
install_brew_pkg lazygit lazygit
install_brew_pkg delta git-delta

copy_config "$REPO_DIR/stildeeneca17-git/.gitconfig" "$HOME/.gitconfig"
copy_config "$REPO_DIR/stildeeneca17-git/.gitignore_global" "$HOME/.gitignore_global"
if ! $DRY_RUN; then
  git config --global core.excludesfile "$HOME/.gitignore_global" 2>/dev/null || true
fi
log_ok "Git configured"

# ══════════════════════════════════════════════════════════
#   SET DEFAULT SHELL → Fish
# ══════════════════════════════════════════════════════════

log_step "🐚  Setting Fish as default shell"

FISH_PATH="$(which fish 2>/dev/null || echo /opt/homebrew/bin/fish)"
if [[ "$SHELL" == "$FISH_PATH" ]]; then
  log_skip "Fish is already the default shell"
else
  if ! $DRY_RUN; then
    if ! grep -qF "$FISH_PATH" /etc/shells 2>/dev/null; then
      echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
    chsh -s "$FISH_PATH"
    log_ok "Default shell set to Fish ($FISH_PATH)"
  else
    log_skip "[dry-run] Would set default shell to $FISH_PATH"
  fi
fi

# ══════════════════════════════════════════════════════════
#   DONE
# ══════════════════════════════════════════════════════════

echo ""
echo -e "  ${BOLD_GREEN}──────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD_WHITE}  ✅  Installation complete!${RESET}"
echo -e "  ${BOLD_GREEN}──────────────────────────────────────────────────────${RESET}"
echo ""

if [[ "$DO_BACKUP" == "yes" ]] && ! $DRY_RUN; then
  echo -e "  ${DIM}📁 Backup saved to: $BACKUP_DIR${RESET}"
  echo ""
fi

echo -e "  ${BOLD_WHITE}Next steps:${RESET}"
echo ""
echo -e "  ${CYAN}1.${RESET}  Reload shell          ${DIM}exec fish${RESET}"
  echo -e "  ${CYAN}2.${RESET}  Tmux plugins          ${DIM}already installed — or Ctrl+b I to retry${RESET}"
echo -e "  ${CYAN}3.${RESET}  Neovim plugins        ${DIM}nvim  (auto-installs on first open)${RESET}"
echo -e "  ${CYAN}4.${RESET}  Set Git identity      ${DIM}git config --global user.name \"Your Name\"${RESET}"
echo -e "                         ${DIM}git config --global user.email \"you@example.com\"${RESET}"
echo -e "  ${CYAN}5.${RESET}  Engram setup          ${DIM}engram setup opencode && engram setup claude-code${RESET}"
echo -e "  ${CYAN}6.${RESET}  Set font in iTerm2    ${DIM}Preferences → Profiles → Text → MesloLGS NF${RESET}"
echo ""
