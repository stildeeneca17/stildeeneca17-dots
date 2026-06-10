# ╔══════════════════════════════════════════════╗
# ║          stildeeneca17 — Fish Config         ║
# ╚══════════════════════════════════════════════╝

# ── 1. Environment variables ─────────────────────
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx DENO_INSTALL $HOME/.deno
set -gx PYENV_ROOT $HOME/.pyenv
set -g fish_greeting ""

# ── 2. PATH setup (fish_add_path is idempotent) ──
fish_add_path -g /opt/homebrew/bin
fish_add_path -g $HOME/.local/bin
fish_add_path -g $PYENV_ROOT/bin
fish_add_path -g $PYENV_ROOT/shims
fish_add_path -g $DENO_INSTALL/bin

# ── 3. Tool initializations (guarded) ────────────
if status is-interactive

    # pyenv
    if command -v pyenv > /dev/null
        pyenv init - fish | source
        pyenv virtualenv-init - fish | source
    end

    # starship prompt
    if command -v starship > /dev/null
        starship init fish | source
    end

    # zoxide (smart cd)
    if command -v zoxide > /dev/null
        zoxide init fish | source
    end

    # fzf keybindings
    if command -v fzf > /dev/null
        fzf --fish | source
    end

    # ── 4. Aliases ────────────────────────────────
    alias k kubectl
    alias lg lazygit
    alias ll 'eza --icons -la'
    alias l 'eza --icons'

    # AI shortcuts (preserved from original)
    alias aitext "opencode run -m opencode/minimax-m2.1-free"
    alias aicode "opencode run -m opencode/glm-4.7-free"

    # ── 5. Vi mode ────────────────────────────────
    fish_vi_key_bindings

end
