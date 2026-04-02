# dotfiles

Personal dotfiles for **vim · tmux · zsh · zimfw · powerlevel10k · git · SSH · mosh**.
Designed for fast, repeatable setup on any Debian-based Linux system.

---

## Table of contents

1. [What's included](#whats-included)
2. [Prerequisites](#prerequisites)
3. [Quick start — fresh VM](#quick-start--fresh-vm)
4. [Manual setup](#manual-setup)
5. [Repository layout](#repository-layout)
6. [After first setup](#after-first-setup)
7. [Daily-use bin scripts](#daily-use-bin-scripts)
8. [Personalisation](#personalisation)
9. [Adding new dotfiles](#adding-new-dotfiles)
10. [Security notes](#security-notes)

---

## What's included

| Tool | Config file | Notes |
|------|-------------|-------|
| zsh | `home/.zshrc`, `home/.zshenv`, `home/.zimrc` | zimfw module manager, plugins, aliases |
| powerlevel10k | `home/.p10k.zsh` (generate with `p10k configure`) | fast prompt with instant-prompt |
| tmux | `home/.tmux.conf` | `C-a` prefix, vi-keys, true colour, status bar |
| vim | `home/.vimrc` | sane defaults, space leader, split nav |
| git | `home/.gitconfig`, `home/.gitignore_global` | aliases, global ignore |
| SSH | `home/.ssh/config` | ControlMaster multiplexing, ed25519-first |

**Installed packages:** `zsh`, `vim`, `git`, `tmux`, `openssh-client/server`, `mosh`, `gh` (GitHub CLI), `curl`, `wget`, `htop`, `tree`, `jq`, `unzip`, `build-essential`

---

## Prerequisites

- A Debian-based Linux machine (bare metal, VM, or container)
- Internet access to download packages and clone the repo
- A user account with `sudo` privileges (do **not** run as root)

---

## Quick start — fresh VM

### Option A — one-liner bootstrap

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wayne-tsai/dotfiles/main/scripts/bootstrap.sh)
```

The bootstrap script will interactively:

1. Install `git` if missing, then clone this repo to `~/dotfiles`
2. Install all packages via `apt` (including `gh`, `zimfw`, `powerlevel10k`)
3. Symlink every file under `home/` into `$HOME`
4. Offer to append your SSH public key to `~/.ssh/authorized_keys`
5. Offer to set the system timezone

### Option B — clone first, then bootstrap

```bash
git clone https://github.com/wayne-tsai/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/bootstrap.sh
```

---

## Manual setup

If you prefer to run each step yourself:

```bash
# 1. Install all packages (apt + zimfw + powerlevel10k)
bash ~/dotfiles/scripts/install-packages.sh

# 2. Symlink configs into ~/
bash ~/dotfiles/scripts/link-configs.sh

# — or both at once —
make install
```

Other `make` targets:

```
make install      install packages then link configs (full first-time setup)
make link         link configs only — re-run after adding new dotfiles
make update       git pull + re-link
make bootstrap    full one-shot setup (same as bootstrap.sh)
```

---

## Repository layout

```
dotfiles/
│
├── home/                       Files symlinked 1-to-1 into ~/
│   ├── .gitconfig
│   ├── .gitignore_global
│   ├── .vimrc
│   ├── .zshrc
│   ├── .zshenv
│   ├── .zimrc
│   ├── .tmux.conf
│   └── .ssh/
│       └── config
│
├── bin/                        Utility scripts — on $PATH via .zshenv
│   ├── update-system           apt update + upgrade + dist-upgrade + autoremove
│   ├── add-authorized-key      safely append a pubkey to authorized_keys
│   └── gen-ssh-key             generate a new ed25519 keypair
│
├── scripts/                    One-shot setup scripts
│   ├── bootstrap.sh            Full new-machine setup (start here)
│   ├── install-packages.sh     Install all tools via apt
│   └── link-configs.sh         Symlink home/* into ~/
│
├── Makefile                    Convenience targets
├── .gitignore                  Keeps secrets and caches out of git
└── README.md
```

> `link-configs.sh` backs up any pre-existing files to `home.bak/` instead of
> deleting them, so you won't lose your old configs.

---

## After first setup

```bash
exec zsh           # switch to zsh immediately (or log out and back in)
zimfw install      # download and install all zsh modules listed in ~/.zimrc
p10k configure     # interactive prompt wizard — generates ~/.p10k.zsh
```

### Authenticate GitHub CLI

```bash
gh auth login
```

---

## Daily-use bin scripts

These live in `~/dotfiles/bin/` and are on `$PATH` automatically.

### `update-system`

Full system update in one command:

```bash
update-system           # asks for confirmation at each apt step
update-system --yes     # non-interactive (safe for cron / Ansible)
```

Runs `apt update → upgrade → dist-upgrade → autoremove → clean` and prompts
to reboot if a kernel update is pending.

### `add-authorized-key`

Safely add an SSH public key to `~/.ssh/authorized_keys`:

```bash
add-authorized-key ~/.ssh/id_ed25519.pub    # from a .pub file
add-authorized-key "ssh-ed25519 AAAA…"     # paste inline
cat my.pub | add-authorized-key -           # from stdin
```

**Is this safe?**
Yes. The script only *appends* (never overwrites), deduplicates by key material,
and enforces `chmod 700 ~/.ssh` and `chmod 600 authorized_keys`. You must already
be authenticated on the machine to run it. Keep your private key safe, and this
is fine.

### `gen-ssh-key`

Generate a new ed25519 keypair on a machine that doesn't have one yet:

```bash
gen-ssh-key                 # saves to ~/.ssh/id_ed25519, comment = user@host
gen-ssh-key "wayne@pve01"   # custom comment
```

Prints the public key at the end so you can copy it to GitHub or other hosts.

---

## Personalisation

### 1 — Set your git identity

```bash
vim ~/dotfiles/home/.gitconfig
```

Change:
```ini
[user]
    name  = Your Name
    email = your@email.com
```

### 2 — Configure your prompt

```bash
p10k configure     # interactive wizard, writes ~/.p10k.zsh
```

Copy the generated file into the repo so it's versioned:

```bash
cp ~/.p10k.zsh ~/dotfiles/home/.p10k.zsh
make link          # re-link so ~/dotfiles/home/.p10k.zsh is the canonical copy
```

### 3 — Add SSH hosts

Edit `~/dotfiles/home/.ssh/config` and uncomment or add `Host` stanzas.
Templates for a bastion/jump host are already there.

---

## Adding new dotfiles

1. Place the file under `home/`, mirroring its path relative to `~/`
   (e.g., a file that lives at `~/.config/foo/bar.conf` goes into
   `home/.config/foo/bar.conf`)
2. Run `make link`
3. Commit and push

---

## Security notes

| What | Where | Status |
|------|-------|--------|
| SSH private keys (`id_*`) | `home/.ssh/` | In `.gitignore` — never committed |
| `known_hosts`, `authorized_keys` | `home/.ssh/` | In `.gitignore` — never committed |
| ControlMaster sockets | `~/.ssh/sockets/` | In `.gitignore` |
| `ForwardAgent` | `home/.ssh/config` | **Off** by default |
| `.env`, `*.pem`, `*.key` | anywhere | Caught by `.gitignore_global` |
