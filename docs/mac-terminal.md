# macOS terminal setup (Ghostty + zsh + Neovim)

Written 2026-09-08, updated 2026-09-10. This is the Mac workstation setup, separate from the Debian server configs under `home/`. Most live files here are listed per section and are not symlinked. The exception is Ghostty: `home/.config/ghostty/` is tracked and symlinked by `scripts/link-configs.sh` like any other dotfile.

## Table of contents

1. [Ghostty](#ghostty)
2. [Font](#font)
3. [Shell: zsh + zim + starship](#shell-zsh--zim--starship)
4. [CLI tools](#cli-tools)
5. [git + delta](#git--delta)
6. [atuin (history)](#atuin-history)
7. [tmux](#tmux)
8. [Neovim (LazyVim)](#neovim-lazyvim)
9. [Claude Code sessions](#claude-code-sessions)
10. [Backups](#backups)
11. [Gotchas](#gotchas)

---

## Ghostty

Config: `~/.config/ghostty/config`. Reload: `Cmd+Shift+,`. Validate: `ghostty +validate-config`.

Key settings and why:

| Setting | Value | Why |
|---|---|---|
| `theme` | `Catppuccin Mocha` | soft pastels, no pure white |
| `background` | `#141414` | near-black gray. Pure black causes halation on Retina/OLED |
| `foreground` | `#d0d0d0` | off-white, not `#ffffff` |
| `background-opacity` / `background-blur` | `0.85` / `20` | see-through with blur so text stays readable |
| `minimum-contrast` | `1.5` | rescues invisible text only. At 3 it flips dim text to pure white |
| `palette = 8=#6c7086` | | ansi bright-black. zsh-autosuggest ghost text uses this |
| `font-thicken` | `true` | macOS only, thicker strokes at large sizes |
| `adjust-cell-height` | `15%` | line spacing |
| `window-colorspace` | `display-p3` | wide gamut |
| `cursor-style-blink` | `false` | blinking pulls the eye |
| `macos-icon` | `glass` | others: holographic, microchip, chalkboard, paper, retro, xray |

Keys worth knowing (defaults):

| Key | Action |
|---|---|
| `Cmd+T` / `Cmd+W` | new / close tab |
| `Cmd+D` / `Cmd+Shift+D` | split right / down |
| `Cmd+]` / `Cmd+[` | next / previous split |
| `Cmd+Shift+Enter` | zoom current split |
| Cmd+backtick | quick dropdown terminal from any app (custom keybind, global) |

Shaders are tracked at `home/.config/ghostty/shaders/` and symlinked into `~/.config/ghostty/shaders/`. Stack any number of `custom-shader = shaders/<name>.glsl` lines; each shader reads the previous one's output through `iChannel0`, so order matters and post-process effects like `bloom` go last.

Active stack:

| Shader | Fires on | Tuning |
|---|---|---|
| `cursor_blaze` | cursor jumps over `DRAW_THRESHOLD` (1.5 cell heights) | `DURATION = 1.0`, `ease` exponent `10.0` |
| `typing_pop` | any cursor move, so every keystroke | `DURATION = 0.15`, `MAX_RADIUS = 0.05` (about one cell radius) |

`typing_pop` is a local edit of `ripple_cursor`, rewritten to trigger on cursor movement instead of cursor width change. The original fires on vim normal/insert switches, not on typing.

`bloom` is present but commented out. It is a 24-tap luminance-weighted blur, the most expensive shader in the directory.

Cursor alternatives: `cursor_warp`, `cursor_lightning`, `cursor_sweep`, `cursor_tail`, `sonic_boom_cursor`, `ripple_cursor`. Background effects (`just-snow`, `starfield`, `galaxy`, `crt`, `glow-rgbsplit-twitchy`) cost GPU and attention. Source: `github.com/hackr-sh/ghostty-shaders`.

Any shader that animates off a cursor or time uniform needs an `iFocus > 0` guard around its draw branch. See the Gotchas section for why.

Preview any built-in theme interactively: `ghostty +list-themes`.

## Font

`font-family = BlexMono Nerd Font Mono`, size 20. BlexMono is IBM Plex Mono patched with Nerd Font glyphs, so powerline arrows, rounded separators, and file icons render in the same weight as text. Installed via `brew install --cask font-blex-mono-nerd-font`.

Also installed for comparison: `IBM Plex Mono` (no glyphs), `Monaspace Neon`, `Iosevka`. Swap the one line and reload.

If icons look small, use the non-Mono variant: `BlexMono Nerd Font`.

## Shell: zsh + zim + starship

Files: `~/.zshrc`, `~/.zimrc`, `~/.config/starship.toml`.

`~/.zshrc` and `~/.zimrc` are now symlinks into `home/` and are shared with the
Linux servers. Both branch on `$OSTYPE`: macOS gets starship plus the eza / bat /
fzf / zoxide / atuin stack, Linux gets powerlevel10k and the apt / ss aliases.
Add anything Mac-only inside the `if [[ $OSTYPE == darwin* ]]` block.

- zim loads: git, completion, syntax-highlighting, history-substring-search, autosuggestions.
- starship prompt, Catppuccin Mocha palette, segments: user, directory, git branch/status, language versions, time. Uses starship's named palette so colors read as `bg:blue` not hex.
- powerlevel10k never loads on this Mac: `.zimrc` only declares the module when `$OSTYPE` is not `darwin*`. Leftovers `~/.zim/` (the old non-XDG zim home) and `~/.p10k.zsh` are dead weight here; zim now lives at `~/.local/share/zim`.
- zsh has `noclobber` on: `cmd > existing` fails with `file exists`. Use `>|` to force.

Aliases added at the bottom of `~/.zshrc`:

| Alias | Runs |
|---|---|
| `ls`, `ll`, `lt` | eza with icons, dirs first, git column, tree |
| `cat` | bat (syntax highlight, line numbers). Raw bytes: `command cat` |
| `vim`, `vi` | nvim. Old vimrc setup: `oldvim` |
| `gs gl gd gds ga gc gco gp gpl gb` | git status/log/diff/diff --staged/add/commit/checkout/push/pull/branch |
| `lg` | lazygit |
| `claude-work` | function: runs Claude with `CLAUDE_CONFIG_DIR=~/.claude-work` (separate settings, plugins, sessions, auth) |

## CLI tools

| Tool | Use | Note |
|---|---|---|
| `fzf` | `Ctrl+T` fuzzy file picker | `Ctrl+R` is taken by atuin |
| `zoxide` | `z <partial>` jumps to frecent dir, `zi` interactive | learns as you cd |
| `eza` | ls replacement | |
| `bat` | cat replacement, Catppuccin Mocha theme in `~/.config/bat/config` | `bat cache --build` after adding themes |
| `yazi` | terminal file manager | |
| `btop` | system monitor, Catppuccin, transparent, vim keys | config `~/.config/btop/btop.conf` |
| `uv` | Python venvs and installs | `uv venv`, `uv pip install`, `uv run x.py`. Replaces conda for new projects |
| `lazygit` | git TUI | `<Space>gg` inside nvim |
| `gh` | GitHub CLI | |

## git + delta

Global `~/.gitconfig`. Pager is delta: syntax highlight, line numbers, Catppuccin Mocha (`~/.config/delta/catppuccin.gitconfig`), clickable file links. `merge.conflictstyle = zdiff3` shows the common ancestor in conflicts.

Git-level aliases: `git st`, `git lg` (graph, all branches), `git last`, `git unstage`, `git amend`.

Delta only activates when output is a terminal. Piping `git diff | something` gives plain output by design.

## atuin (history)

Config `~/.config/atuin/config.toml`. Local only, `auto_sync = false`, no account. Old zsh history was imported (6164 entries).

- `Ctrl+R`: fuzzy search all history. Type, arrows, Enter runs.
- Up arrow: plain zsh (atuin started with `--disable-up-arrow`).
- `atuin stats`: most used commands.
- `atuin login` if sync across machines is ever wanted.

## tmux

`~/.tmux.conf` (Mac version, prefix stays `Ctrl+b`). Plugins via TPM in `~/.tmux/plugins/`: tmux-sensible, catppuccin, tmux-resurrect, tmux-continuum.

| Key (after prefix) | Action |
|---|---|
| `\|` / `-` | split right / down, keeps current directory |
| `h j k l` | move between panes |
| `H J K L` | resize (repeatable) |
| `c` | new window in current directory |
| `r` | reload config |
| `Ctrl+s` / `Ctrl+r` | save / restore session (resurrect) |
| `I` | install plugins listed in config |

Continuum autosaves every 15 minutes and restores on tmux start. Copy mode is vi: `v` select, `y` copies to macOS clipboard.

Ghostty splits cover most local needs. tmux is for sessions that must survive a closed window or an SSH drop.

## Neovim (LazyVim)

Config `~/.config/nvim/`. Plugin manager: lazy.nvim, every plugin pinned in `lazy-lock.json`. Update with `:Lazy update`, review the diff of the lock file.

Customization is deliberately small:

| File | Contains |
|---|---|
| `lua/plugins/colorscheme.lua` | Catppuccin Mocha, transparent, solid floats, LazyVim colorscheme set to `catppuccin-mocha` |
| `lua/plugins/ui.lua` | dashboard header, snacks toggles (smooth scroll, indent guides, zen) |
| `lua/config/options.lua` | scrolloff 8, relative numbers, no wrap, undofile |
| `lua/config/keymaps.lua` | see below |
| `lazyvim.json` | enabled extras |

The colorscheme name must be `catppuccin-mocha`, not `catppuccin`. LazyVim's stock statusline uses lualine theme `auto`, which looks for a theme file named after the colorscheme, and catppuccin ships it under the `-mocha` name. With the short name you get gray auto-derived colors.

Extras enabled: typescript, python (basedpyright), go, json, yaml, toml, markdown, tailwind, docker, git, inc-rename, treesitter-context, yanky, mini-hipatterns. Add more with `:LazyExtras`. Language servers install through Mason on first open of that filetype.

Keys (leader is Space):

| Key | Action |
|---|---|
| `Space Space` | find file |
| `Space /` | grep project |
| `Space e` | file tree |
| `Space gg` | lazygit |
| `Space cr` / `Space ca` | rename symbol / code action |
| `gd` / `K` | definition / hover docs |
| `s` + 2 chars | jump anywhere on screen (flash) |
| `Shift+h` / `Shift+l` | previous / next buffer |
| `Space bd` | close buffer |
| `Space uz` | zen mode |
| `jk` | escape (custom) |
| `Ctrl+d` / `Ctrl+u` / `n` / `N` | scroll or search, cursor stays centered (custom) |
| `J` / `K` in visual | move selected lines (custom) |
| `Space w` / `Space q` | save / quit (custom) |
| `Space p` in visual | paste without clobbering register (custom) |
| `Space` alone | wait, which-key shows every group |

## Claude Code sessions

Two config dirs: `~/.claude` (personal) and `~/.claude-work` (dareesoft). Themes differ so they are never confused:

| Session | Theme | Extra cue |
|---|---|---|
| `claude` | `dark` | status bar text `🚀 Personal 🚀` |
| `claude-work` | `dark-ansi` (uses terminal palette) | status bar text `🚨 Dareesoft 🚨` |

Both use ccstatusline for the bar under the input. Change theme in-session with `/theme`. Theme lives in each dir's `settings.json`, which overrides `.claude.json`.

ccstatusline widget config is tracked in this repo and symlinked by `make link`:

| Session | `statusLine.command` in `settings.json` | ccstatusline config |
|---|---|---|
| `claude` | `npx -y ccstatusline@latest` | `~/.config/ccstatusline/settings.json` (ccstatusline default path) |
| `claude-work` | `npx -y ccstatusline@latest --config $HOME/.config/ccstatusline/work.json` | `~/.config/ccstatusline/work.json` |

Both files are identical except the `customText` widget. `~/.claude/settings.json` and `~/.claude-work/settings.json` themselves are not tracked (they hold plugin state and machine-local paths).

## Backups

Made during setup, safe to delete once happy:

```
~/.config/ghostty/config.bak, config.bak2
~/.config/starship.toml.bak
~/.zshrc.bak, .bak2, .bak3
~/.tmux.conf.bak
~/.config/nvim.bak-2026-09-08/
~/.claude.json.bak, ~/.claude-work/.claude.json.bak, ~/.claude-work/settings.json.bak
```

## Gotchas

- **Nerd Font glyphs in config files.** They are Unicode private-use characters and some editors or agents silently drop them. In TOML write `"\uE0B4"`, in Lua `"\u{e0b4}"`. Verify with a byte search, never by eye.
- **Ghost text turned white.** `minimum-contrast` above ~2 flips borderline-dim text to pure white instead of nudging it. Keep it at 1.5 and set `palette = 8=` explicitly.
- **Duplicate `compinit` warning.** zim's completion module already runs it. Do not add another `compinit` call after zim init.
- **`zimfw: Unknown action` on every new shell.** `.zshrc` was sourcing `$ZIM_HOME/zimfw.zsh` (the CLI) instead of `$ZIM_HOME/init.zsh` (the built module file). Sourcing the CLI with no action prints its usage text and loads nothing, so the prompt silently falls back to bare zsh.
- **`make link` overwrites the Mac config with the Linux one.** `scripts/link-configs.sh` symlinks everything under `home/` into `$HOME`, moving the existing file to `home.bak/` first. Nothing is lost, but the live config becomes whatever the repo tracks. Git identity is the easy one to miss: it now comes from the untracked `~/.gitconfig.local`, included by `home/.gitconfig`, so the public repo carries no personal email.
- **Padding and font changes** apply to new tabs only after reload.
- **Shader artifacts frozen on screen when unfocused.** `iTime` is seconds since the *first frame rendered*, not wall clock, and `custom-shader-animation = true` (the default) only runs the animation loop while the surface is focused. So `iTime` nearly stops when you switch away, and one isolated frame later (a modifier keypress, a link hover) can still compute `iTime - iTimeCursorChange` inside the animation window, painting a stale effect that then sits there until refocus. Guard every draw branch with `iFocus > 0`. Ghostty exposes that uniform for exactly this. `custom-shader-animation = always` also works but burns CPU on every unfocused surface.
- **Ghostty reads two config files.** `~/.config/ghostty/config` and `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` are both loaded and merged last-write-wins per key. A stray copy of the latter silently overrode `font-size` and injected an extra `custom-shader` for three months. When a config change appears not to take, check `ghostty +show-config` for the resolved values rather than trusting the file you edited.
- **Shader compile errors are invisible.** A broken shader is ignored, and `ghostty +validate-config` still exits 0 because compilation happens on the render thread after config load. Check with `/usr/bin/log show --predicate 'process == "ghostty"' --last 10m --style compact | grep -i shader`.
