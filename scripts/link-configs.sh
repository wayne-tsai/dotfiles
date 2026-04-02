#!/usr/bin/env bash
# link-configs.sh — Symlink every file under home/ into $HOME.
#
# Existing files are moved to home.bak/ (not deleted).
# Run this script again at any time to pick up newly added dotfiles.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="$HOME"
BACKUP_DIR="$DOTFILES_DIR/home.bak"
SOURCE_DIR="$DOTFILES_DIR/home"

# ── Colour helpers ────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
    GREEN=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''
fi

info()    { echo -e "${CYAN}==>${RESET} ${BOLD}$*${RESET}"; }
success() { echo -e "${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "${YELLOW}~${RESET}  $*"; }

# ── Link a single file ────────────────────────────────────────────────────────
link_file() {
    local src="$1"               # absolute path inside home/
    local rel="${src#$SOURCE_DIR/}"  # relative path (e.g. .zshrc or .ssh/config)
    local dst="$HOME_DIR/$rel"

    # Ensure the parent directory exists
    mkdir -p "$(dirname "$dst")"

    # If the destination exists and is NOT already our symlink, back it up
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        local backup="$BACKUP_DIR/$rel"
        mkdir -p "$(dirname "$backup")"
        mv "$dst" "$backup"
        warn "Backed up existing $dst → $backup"
    fi

    # If it's already the correct symlink, skip
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        success "Already linked: ~/$rel"
        return
    fi

    ln -sf "$src" "$dst"
    success "Linked: ~/$rel → $src"
}

# ── Walk the home/ tree ───────────────────────────────────────────────────────
info "Linking dotfiles from $SOURCE_DIR → $HOME_DIR"

# Use find to walk all regular files (handles subdirectories like .ssh/)
while IFS= read -r -d '' file; do
    link_file "$file"
done < <(find "$SOURCE_DIR" -type f -print0)

# ── Ensure correct permissions on .ssh ───────────────────────────────────────
if [[ -d "$HOME_DIR/.ssh" ]]; then
    chmod 700 "$HOME_DIR/.ssh"
    [[ -f "$HOME_DIR/.ssh/config" ]] && chmod 600 "$HOME_DIR/.ssh/config"
fi

# ── SSH socket directory ──────────────────────────────────────────────────────
install -d -m 700 "$HOME_DIR/.ssh/sockets"

# ── Make bin/ scripts executable ─────────────────────────────────────────────
chmod +x "$DOTFILES_DIR"/bin/*

info "Done. You may need to restart your shell:  exec zsh"
