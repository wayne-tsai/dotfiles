#!/usr/bin/env bash
# bootstrap.sh — One-shot new-machine setup script.
#
# What it does:
#   1. Clones this dotfiles repo (if not already cloned)
#   2. Installs all packages (apt)
#   3. Symlinks all configs
#   4. Optionally adds your SSH public key to authorized_keys
#
# Usage on a fresh VM (run as your normal user, NOT root):
#
#   curl -fsSL https://raw.githubusercontent.com/YOU/dotfiles/main/scripts/bootstrap.sh | bash
#
#   — OR, if already cloned —
#
#   bash ~/dotfiles/scripts/bootstrap.sh

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/YOU/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

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

# ── Sanity ────────────────────────────────────────────────────────────────────
[[ "$EUID" -eq 0 ]] && die "Do not run bootstrap as root. Run as your normal user; sudo will be used where needed."

# ── 1. Clone repo ─────────────────────────────────────────────────────────────
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    # git may not be installed yet — use apt to get it
    if ! command -v git &>/dev/null; then
        info "Installing git (pre-requisite)…"
        sudo apt-get update -qq
        sudo apt-get install -y git
    fi
    info "Cloning dotfiles repo…"
    git clone "$REPO_URL" "$DOTFILES_DIR"
    success "Cloned to $DOTFILES_DIR"
else
    info "Dotfiles already cloned at $DOTFILES_DIR — pulling latest…"
    git -C "$DOTFILES_DIR" pull --ff-only
fi

cd "$DOTFILES_DIR"

# ── 2. Install packages ───────────────────────────────────────────────────────
info "Running install-packages.sh…"
bash "$DOTFILES_DIR/scripts/install-packages.sh"

# ── 3. Link configs ───────────────────────────────────────────────────────────
info "Running link-configs.sh…"
bash "$DOTFILES_DIR/scripts/link-configs.sh"

# ── 4. Optionally add SSH key ─────────────────────────────────────────────────
echo ""
read -rp "Add an SSH public key to authorized_keys now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    echo "Paste your public key (single line), then press Enter:"
    read -r pubkey
    bash "$DOTFILES_DIR/bin/add-authorized-key" "$pubkey"
fi

# ── 5. Set timezone ───────────────────────────────────────────────────────────
echo ""
read -rp "Set timezone? (e.g. Asia/Taipei, America/New_York — leave blank to skip): " tz
if [[ -n "$tz" ]]; then
    sudo timedatectl set-timezone "$tz"
    success "Timezone set to $tz"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
success "Bootstrap complete!"
echo ""
echo "  Suggested next steps:"
echo "  • Run 'exec zsh' or log out and back in"
echo "  • Edit ~/dotfiles/home/.gitconfig with your name/email"
echo "  • Run 'p10k configure' to set up your prompt"
echo "  • Run 'zimfw install' to install zsh modules"
