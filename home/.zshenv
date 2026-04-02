# .zshenv — sourced for ALL zsh sessions (login, non-login, scripts)
# Keep this minimal: only env vars that must be universally available.

# ── XDG Base Directories ──────────────────────────────────────────────────────
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ── Path ──────────────────────────────────────────────────────────────────────
typeset -U path  # deduplicate PATH entries
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/dotfiles/bin"
    /usr/local/bin
    /usr/bin
    /bin
    /usr/local/sbin
    /usr/sbin
    /sbin
    $path
)
export PATH

# ── Default programs ──────────────────────────────────────────────────────────
export EDITOR="vim"
export VISUAL="vim"
export PAGER="less"
export LESS="-FRX"

# ── Locale ────────────────────────────────────────────────────────────────────
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
