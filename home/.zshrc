# .zshrc — interactive shell configuration
#
# One file, two machines. Shared config sits at the top level; anything that
# only makes sense on one OS is guarded by $OSTYPE:
#   both   → starship prompt (~/.config/starship.toml)
#   macOS  → eza/bat/fzf/zoxide/atuin, nvm + conda
#   Linux  → apt/ss/free system aliases
# The Mac setup is documented in docs/mac-terminal.md.

# ── Zim module settings (must be set BEFORE init.zsh is sourced) ──────────────
WORDCHARS=${WORDCHARS//[\/]}          # treat / as a word separator

ZSH_AUTOSUGGEST_MANUAL_REBIND=1       # autosuggestions is last in .zimrc
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'   # Ghostty ansi bright-black
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# ── Zimfw ─────────────────────────────────────────────────────────────────────
ZIM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zim"

# Auto-install zimfw if missing
if [[ ! -e "$ZIM_HOME/zimfw.zsh" ]]; then
    curl -fsSL --create-dirs \
        -o "$ZIM_HOME/zimfw.zsh" \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Rebuild init.zsh when .zimrc changes (also installs missing modules)
if [[ ! "$ZIM_HOME/init.zsh" -nt "${ZDOTDIR:-$HOME}/.zimrc" ]]; then
    source "$ZIM_HOME/zimfw.zsh" init -q
fi

source "$ZIM_HOME/init.zsh"

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
# compinit is run by zim's `completion` module — do not call it again here.
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion::complete:*' gain-privileges 1

# ── Keybindings ───────────────────────────────────────────────────────────────
bindkey -e                            # Emacs-style line editing
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# Up/down search history by what is already typed (zsh-history-substring-search).
# Bound manually so they work both before and after zle-line-init.
zmodload -F zsh/terminfo +p:terminfo
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key

# ── Aliases — navigation ──────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

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
alias gds='git diff --staged'
alias gco='git checkout'
alias gb='git branch'
alias gbr='git branch'
alias gst='git stash'
alias gstp='git stash pop'

# ── Aliases — tmux ────────────────────────────────────────────────────────────
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux ls'
alias tk='tmux kill-session -t'

# ── Aliases — misc ────────────────────────────────────────────────────────────
alias reload='exec zsh'
alias dotfiles='cd ~/Developer/dotfiles'
alias df='df -h'
alias du='du -h'
alias myip='curl -s ifconfig.me && echo'

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

# SSH wrapper that persists the session name
ssht() {
    local host="${1:?Usage: ssht <host> [session-name]}"
    local session="${2:-main}"
    ssh -t "$host" "tmux new-session -A -s $session"
}

# ══════════════════════════════════════════════════════════════════════════════
# macOS workstation
# ══════════════════════════════════════════════════════════════════════════════
if [[ $OSTYPE == darwin* ]]; then

    # ── PATH ──────────────────────────────────────────────────────────────────
    export PATH="$HOME/.local/bin:$PATH"
    export PATH="$HOME/Library/Python/3.9/bin:$PATH"
    export PATH="$HOME/.grok/bin:$PATH"
    fpath=(~/.grok/completions/zsh $fpath)

    # ── Editor ────────────────────────────────────────────────────────────────
    export EDITOR=nvim VISUAL=nvim
    alias vim='nvim'
    alias vi='nvim'
    alias oldvim='command vim'    # legacy ~/.vimrc setup

    # ── Modern CLI replacements ───────────────────────────────────────────────
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -la --icons --git --group-directories-first'
    alias la='eza -la --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
    alias cat='bat'
    alias top='htop 2>/dev/null || top'
    alias lg='lazygit'
    alias gs='git st'             # git-st alias from ~/.gitconfig

    # ── Tools ─────────────────────────────────────────────────────────────────
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=bg+:#313244,bg:#141414,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    (( ${+commands[fzf]} ))    && eval "$(fzf --zsh)"        # Ctrl+R history, Ctrl+T files
    (( ${+commands[zoxide]} )) && eval "$(zoxide init zsh)"  # z <dir> jumps to frecent dirs
    (( ${+commands[atuin]} ))  && eval "$(atuin init zsh --disable-up-arrow)"
    [[ -r /opt/homebrew/etc/profile.d/z.sh ]] && . /opt/homebrew/etc/profile.d/z.sh

    # ── nvm ───────────────────────────────────────────────────────────────────
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"

    # ── conda ─────────────────────────────────────────────────────────────────
    # Contents of this block are managed by `conda init`
    __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
    if [[ $? -eq 0 ]]; then
        eval "$__conda_setup"
    elif [[ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
    unset __conda_setup

    # ── Claude Code work profile ──────────────────────────────────────────────
    claude-work() { CLAUDE_CONFIG_DIR=~/.claude-work claude "$@"; }

# ══════════════════════════════════════════════════════════════════════════════
# Linux servers
# ══════════════════════════════════════════════════════════════════════════════
else

    # ── Editor ────────────────────────────────────────────────────────────────
    alias vi='vim'

    # ── Listing ───────────────────────────────────────────────────────────────
    alias ls='ls --color=auto -h'
    alias ll='ls -lh'
    alias la='ls -lAh'
    alias lt='ls -lht'            # sort by time
    alias lS='ls -lhS'            # sort by size

    # ── System ────────────────────────────────────────────────────────────────
    alias update='sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y'
    alias ports='ss -tulnp'
    alias localip="ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127"
    alias free='free -h'
    alias top='htop 2>/dev/null || top'

    # ── Show which process is using a port ────────────────────────────────────
    whoisport() { ss -tulnp | grep ":${1}"; }

fi

# ── Prompt (must stay last) ───────────────────────────────────────────────────
(( ${+commands[starship]} )) && eval "$(starship init zsh)"
