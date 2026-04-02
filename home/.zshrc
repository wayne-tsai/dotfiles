# .zshrc — interactive shell configuration

# ── Powerlevel10k instant prompt ──────────────────────────────────────────────
# Must be near the top of .zshrc. No console output before this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Zimfw ─────────────────────────────────────────────────────────────────────
ZIM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zim"

# Auto-install zimfw if missing
if [[ ! -e "$ZIM_HOME/zimfw.zsh" ]]; then
    curl -fsSL --create-dirs \
        -o "$ZIM_HOME/zimfw.zsh" \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Auto-install missing modules
if [[ ! "$ZIM_HOME/modules/git/init.zsh" -nt "$ZIM_HOME/.zimrc" ]] 2>/dev/null; then
    source "$ZIM_HOME/zimfw.zsh" init -q
fi

source "$ZIM_HOME/zimfw.zsh"

# ── Zim modules (edit ~/.zimrc for module list) ───────────────────────────────

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

# ── Options ───────────────────────────────────────────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# ── Completion ────────────────────────────────────────────────────────────────
autoload -Uz compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion::complete:*' gain-privileges 1
compinit -C -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-${ZSH_VERSION}"

# ── Keybindings ───────────────────────────────────────────────────────────────
bindkey -e                            # Emacs-style line editing
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# ── Aliases — navigation ──────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# ── Aliases — listing ─────────────────────────────────────────────────────────
alias ls='ls --color=auto -h'
alias ll='ls -lh'
alias la='ls -lAh'
alias lt='ls -lht'          # sort by time
alias lS='ls -lhS'          # sort by size

# ── Aliases — safety ─────────────────────────────────────────────────────────
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# ── Aliases — git ─────────────────────────────────────────────────────────────
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git lg'
alias gd='git diff'
alias gco='git checkout'
alias gbr='git branch'
alias gst='git stash'
alias gstp='git stash pop'

# ── Aliases — system ──────────────────────────────────────────────────────────
alias update='sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo'
alias localip="ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127"
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='htop 2>/dev/null || top'

# ── Aliases — tmux ────────────────────────────────────────────────────────────
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux ls'
alias tk='tmux kill-session -t'

# ── Aliases — tools ───────────────────────────────────────────────────────────
alias vi='vim'
alias reload='exec zsh'
alias dotfiles='cd ~/dotfiles'

# ── Functions ─────────────────────────────────────────────────────────────────

# Create and enter directory
mkcd() { mkdir -p "$1" && cd "$1"; }

# Extract any archive
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.gz|*.tgz) tar xzf "$1"    ;;
            *.tar.bz2)      tar xjf "$1"    ;;
            *.tar.xz)       tar xJf "$1"    ;;
            *.tar)          tar xf  "$1"    ;;
            *.gz)           gunzip  "$1"    ;;
            *.bz2)          bunzip2 "$1"    ;;
            *.zip)          unzip   "$1"    ;;
            *.7z)           7z x    "$1"    ;;
            *)              echo "Cannot extract '$1'" ;;
        esac
    else
        echo "'$1' is not a file"
    fi
}

# Quick HTTP server in current directory
serve() { python3 -m http.server "${1:-8000}"; }

# Show which process is using a port
whoisport() { ss -tulnp | grep ":${1}"; }

# SSH wrapper that persists the session name
ssht() {
    local host="${1:?Usage: ssht <host> [session-name]}"
    local session="${2:-main}"
    ssh -t "$host" "tmux new-session -A -s $session"
}

# ── Powerlevel10k ─────────────────────────────────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
