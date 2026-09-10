# Wallpaper

Generative topographic wallpaper in the Catppuccin Mocha palette, matching the
Ghostty / Neovim / tmux / VS Code setup documented in `../docs/mac-terminal.md`.

## Files

| File | Use |
|---|---|
| `topo-gen.py` | the generator |
| `catppuccin-topo-3456x2234.svg` | built-in 16 inch Liquid Retina XDR display |
| `catppuccin-topo-3840x2160.svg` | 4K, and scales down cleanly to the 1080p externals |

Only the vector sources are tracked. PNGs are 8 to 9 MB each, so they are
gitignored and rendered locally:

```bash
inkscape catppuccin-topo-3456x2234.svg -o catppuccin-topo-3456x2234.png -w 3456 -h 2234
```

Set it: System Settings, Wallpaper, Add Photo, pick the PNG. macOS keeps a copy,
so the file can live anywhere.

## How it is made

No image libraries, standard library only.

1. **Fractal value noise** builds a heightfield on a lattice, six octaves, each
   half the amplitude and twice the frequency of the last. A mild bias toward
   the lower right stops it reading as uniform mush.
2. **Marching squares** traces iso-elevation lines through that field. Each cell
   is classified by which of its four corners sit above the current level, and
   the crossing points are interpolated along the cell edges.
3. **Segment joining** chains the resulting fragments into continuous polylines
   through an endpoint adjacency index, so strokes are unbroken curves.
4. **Rendering** draws each level twice, a wide faint bloom pass on the upper
   elevations and a crisp line on top, coloured along a ramp from `surface0` at
   the low ground to `pink` at the peaks. A vignette keeps the corners dark so
   desktop icons stay readable.

## Re-rolling

Every seed is a different landscape. The generator is deterministic, so a seed
you like is reproducible.

```bash
python3 topo-gen.py --seed 42 -o topo.svg
inkscape topo.svg -o topo.png -w 3456 -h 2234
```

| Flag | Default | Effect |
|---|---|---|
| `--seed` | 7 | different terrain |
| `--levels` | 26 | contour line count. 12 is sparse and calm, 40 is dense |
| `--scale` | 3.2 | noise zoom. Lower gives broader landforms, higher gives busier detail |
| `--grid` | 220 | heightfield resolution. Higher is smoother and slower |
| `--glow` | 0.30 | accent glow strength, 0 to 1 |
| `--width` `--height` | 3456 x 2234 | output size |

To match a different Catppuccin flavour, edit `PALETTE` and `RAMP` at the top of
the script. Latte needs the ramp reversed and the background stops swapped,
since it is a light theme.

## Where to find other wallpapers

- **[Catppuccin wallpapers](https://github.com/catppuccin/wallpapers)** the
  official community collection, everything already in your exact palette.
- **[Unsplash](https://unsplash.com)** free, genuinely high resolution, best
  source for photography. Search with "dark" or "minimal" to keep icons legible.
- **[/r/wallpapers](https://reddit.com/r/wallpapers)** and
  **[/r/unixporn](https://reddit.com/r/unixporn)** the second is where themed
  desktop setups get posted, usually with the wallpaper linked.
- **[Basic Apple Guy](https://basicappleguy.com/basicappleblog)** meticulous
  Apple-style wallpapers, often released at 6K and 8K.
- **[Wallhaven](https://wallhaven.cc)** large searchable archive with a strict
  resolution filter. Set it to at least 3456x2234 to avoid upscaled junk.
- **[Apple Store gallery](https://512pixels.net/projects/default-mac-wallpapers-in-5k/)**
  every default macOS wallpaper ever shipped, at 5K.

For a Retina display, do not accept anything under about 3456 pixels wide.
Anything smaller gets upscaled and looks soft.
