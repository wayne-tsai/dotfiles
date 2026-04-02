#!/usr/bin/env bash
# install-packages.sh — Install all tools needed for the dotfiles setup.
# Targets Debian / Ubuntu / Pop!_OS (apt-based).

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'
    YELLOW='\033[1;33m'; CYAN='\033[0;36m'
    BOLD='\033[1m'; RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''
fi

info()    { echo -e "${CYAN}==>${RESET} ${BOLD}$*${RESET}"; }
success() { echo -e "${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
die()     { echo -e "${RED}✖${RESET}  $*" >&2; exit 1; }

command -v apt &>/dev/null || die "apt not found — Debian/Ubuntu only."
[[ "$EUID" -eq 0 ]] || SUDO="sudo"
SUDO="${SUDO:-}"

# ── Base packages ─────────────────────────────────────────────────────────────
BASE_PKGS=(
    # shells & editors
    zsh
    vim
    # version control
    git
    # terminal multiplexer
    tmux
    # SSH
    openssh-client
    openssh-server
    # mobile shell (survives roaming / packet loss)
    mosh
    # conveniences
    curl
    wget
    htop
    tree
    unzip
    jq
    # build tools (needed by some zsh plugins / compiled tools)
    build-essential
    # locale
    locales
    # time
    tzdata
)

# ── GitHub CLI (requires its own apt repository) ──────────────────────────────
install_gh() {
    if command -v gh &>/dev/null; then
        success "gh already installed ($(gh --version | head -1))."
        return
    fi
    info "Adding GitHub CLI apt repository…"
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    $SUDO chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    $SUDO apt update -qq
    $SUDO apt install -y gh
    success "gh installed."
}

info "Updating package lists…"
$SUDO apt update -qq

info "Installing base packages…"
$SUDO apt install -y "${BASE_PKGS[@]}"

install_gh

# ── Change default shell to zsh ───────────────────────────────────────────────
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
ZSH_BIN="$(command -v zsh)"
if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
    info "Changing default shell to zsh for $USER…"
    $SUDO chsh -s "$ZSH_BIN" "$USER"
    success "Shell changed. Re-login or run 'exec zsh' to activate."
else
    success "Default shell is already zsh."
fi

# ── Install zimfw ─────────────────────────────────────────────────────────────
ZIM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zim"
if [[ ! -e "$ZIM_HOME/zimfw.zsh" ]]; then
    info "Installing zimfw…"
    curl -fsSL --create-dirs \
        -o "$ZIM_HOME/zimfw.zsh" \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
    success "zimfw installed."
else
    success "zimfw already installed."
fi

# ── Install Powerlevel10k (standalone, if zimfw isn't used) ───────────────────
P10K_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    info "Cloning Powerlevel10k…"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    success "Powerlevel10k cloned."
else
    success "Powerlevel10k already present."
fi

# ── Locale ────────────────────────────────────────────────────────────────────
info "Ensuring en_US.UTF-8 locale…"
if ! locale -a 2>/dev/null | grep -q "en_US.utf8"; then
    $SUDO locale-gen en_US.UTF-8
    $SUDO update-locale LANG=en_US.UTF-8
fi

# ── SSH socket directory ──────────────────────────────────────────────────────
install -d -m 700 "$HOME/.ssh/sockets"

success "All packages installed."
echo ""
echo "Next step: run  scripts/link-configs.sh"
