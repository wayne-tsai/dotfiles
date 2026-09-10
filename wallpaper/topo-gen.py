#!/usr/bin/env python3
"""
Generative topographic wallpaper in the Catppuccin Mocha palette.

Pure standard library. Builds a fractal value-noise heightfield, traces
iso-elevation contours with marching squares, and writes an SVG.

    python3 topo-gen.py --width 3456 --height 2234 --seed 7 -o topo.svg

Then rasterise:

    inkscape topo.svg -o topo.png -w 3456 -h 2234
"""

import argparse
import math
import random

# ---------------------------------------------------------------------------
# Catppuccin Mocha
# ---------------------------------------------------------------------------
PALETTE = {
    "crust": "#11111b",
    "mantle": "#181825",
    "base": "#1e1e2e",
    "surface0": "#313244",
    "surface1": "#45475a",
    "surface2": "#585b70",
    "overlay0": "#6c7086",
    "blue": "#89b4fa",
    "lavender": "#b4befe",
    "sapphire": "#74c7ec",
    "teal": "#94e2d5",
    "mauve": "#cba6f7",
    "pink": "#f5c2e7",
    "peach": "#fab387",
}

# Contour colours from low ground to high ground. Deep water reads almost
# black so desktop icons stay legible; peaks pick up the accent hues.
RAMP = ["surface0", "surface1", "surface2", "overlay0",
        "sapphire", "blue", "lavender", "mauve", "pink"]


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lerp_hex(a, b, t):
    ra, ga, ba = hex_to_rgb(a)
    rb, gb, bb = hex_to_rgb(b)
    return "#%02x%02x%02x" % (
        round(ra + (rb - ra) * t),
        round(ga + (gb - ga) * t),
        round(ba + (bb - ba) * t),
    )


def ramp_colour(t):
    """Sample the contour ramp at t in [0, 1]."""
    t = min(max(t, 0.0), 1.0)
    pos = t * (len(RAMP) - 1)
    i = int(pos)
    if i >= len(RAMP) - 1:
        return PALETTE[RAMP[-1]]
    return lerp_hex(PALETTE[RAMP[i]], PALETTE[RAMP[i + 1]], pos - i)


# ---------------------------------------------------------------------------
# Value noise
# ---------------------------------------------------------------------------
class ValueNoise:
    """Fractal value noise on an integer lattice with cosine interpolation."""

    def __init__(self, seed):
        self.seed = seed
        rng = random.Random(seed)
        self.perm = list(range(512))
        rng.shuffle(self.perm)
        self.grad = [rng.random() for _ in range(512)]

    def _lattice(self, xi, yi):
        h = self.perm[(xi & 511)] ^ self.perm[(yi & 511)]
        return self.grad[h & 511]

    @staticmethod
    def _smooth(t):
        # smoothstep, cheaper than cosine and visually equivalent here
        return t * t * (3.0 - 2.0 * t)

    def noise(self, x, y):
        xi, yi = math.floor(x), math.floor(y)
        xf, yf = x - xi, y - yi
        u, v = self._smooth(xf), self._smooth(yf)
        n00 = self._lattice(xi, yi)
        n10 = self._lattice(xi + 1, yi)
        n01 = self._lattice(xi, yi + 1)
        n11 = self._lattice(xi + 1, yi + 1)
        a = n00 + (n10 - n00) * u
        b = n01 + (n11 - n01) * u
        return a + (b - a) * v

    def fractal(self, x, y, octaves=6, lacunarity=2.0, gain=0.5):
        total, amp, freq, norm = 0.0, 1.0, 1.0, 0.0
        for _ in range(octaves):
            total += self.noise(x * freq, y * freq) * amp
            norm += amp
            amp *= gain
            freq *= lacunarity
        return total / norm


# ---------------------------------------------------------------------------
# Marching squares
# ---------------------------------------------------------------------------
def contour_segments(field, cols, rows, level):
    """Return line segments where the field crosses `level`.

    Standard marching squares. Each cell contributes 0, 1 or 2 segments,
    chosen by which of its four corners sit above the level.
    """
    segs = []

    def interp(p1, v1, p2, v2):
        if abs(v2 - v1) < 1e-12:
            t = 0.5
        else:
            t = (level - v1) / (v2 - v1)
        return (p1[0] + (p2[0] - p1[0]) * t, p1[1] + (p2[1] - p1[1]) * t)

    for j in range(rows - 1):
        base = j * cols
        for i in range(cols - 1):
            v0 = field[base + i]            # top-left
            v1 = field[base + i + 1]        # top-right
            v2 = field[base + cols + i + 1] # bottom-right
            v3 = field[base + cols + i]     # bottom-left

            idx = (1 if v0 > level else 0) | (2 if v1 > level else 0) \
                | (4 if v2 > level else 0) | (8 if v3 > level else 0)
            if idx == 0 or idx == 15:
                continue

            p0, p1 = (i, j), (i + 1, j)
            p2, p3 = (i + 1, j + 1), (i, j + 1)
            top = interp(p0, v0, p1, v1)
            right = interp(p1, v1, p2, v2)
            bottom = interp(p3, v3, p2, v2)
            left = interp(p0, v0, p3, v3)

            # Bits: 1=top-left, 2=top-right, 4=bottom-right, 8=bottom-left.
            # Each case cuts the cell edges that separate above from below.
            # Complementary cases (n and 15-n) cut the same edges.
            # 5 and 10 are saddles and emit two segments.
            table = {
                1: [(left, top)],                      # isolates TL
                2: [(top, right)],                     # isolates TR
                3: [(left, right)],                    # top half
                4: [(right, bottom)],                  # isolates BR
                5: [(left, top), (right, bottom)],     # saddle
                6: [(top, bottom)],                    # right half
                7: [(left, bottom)],                   # isolates BL
                8: [(left, bottom)],                   # isolates BL
                9: [(top, bottom)],                    # left half
                10: [(left, bottom), (top, right)],    # saddle
                11: [(right, bottom)],                 # isolates BR
                12: [(left, right)],                   # bottom half
                13: [(top, right)],                    # isolates TR
                14: [(left, top)],                     # isolates TL
            }
            segs.extend(table[idx])
    return segs


def join_segments(segs, tol=1e-7):
    """Chain segments into continuous polylines.

    Endpoints produced on a shared cell edge are computed from identical
    corner values, so they match to within rounding. Index them and walk
    the adjacency graph, consuming each segment once. Linear in segment
    count, and it never bridges two points that are not actually adjacent.
    """
    def key(p):
        return (round(p[0] / tol), round(p[1] / tol))

    # endpoint key -> list of segment indices touching it
    ends = {}
    for i, (a, b) in enumerate(segs):
        ends.setdefault(key(a), []).append(i)
        ends.setdefault(key(b), []).append(i)

    used = [False] * len(segs)

    def step(from_key):
        """Take an unused segment at this endpoint, return (other_end, key)."""
        for i in ends.get(from_key, ()):
            if used[i]:
                continue
            a, b = segs[i]
            used[i] = True
            other = b if key(a) == from_key else a
            return other
        return None

    paths = []
    for i, (a, b) in enumerate(segs):
        if used[i]:
            continue
        used[i] = True
        path = [a, b]

        # extend forward from b
        cur = b
        while True:
            nxt = step(key(cur))
            if nxt is None:
                break
            path.append(nxt)
            cur = nxt

        # extend backward from a
        cur = a
        while True:
            nxt = step(key(cur))
            if nxt is None:
                break
            path.insert(0, nxt)
            cur = nxt

        if len(path) > 2:
            paths.append(path)
    return paths


# ---------------------------------------------------------------------------
# SVG
# ---------------------------------------------------------------------------
def build_svg(width, height, seed, levels, grid, scale, glow):
    noise = ValueNoise(seed)
    cols = grid
    rows = max(2, round(grid * height / width))

    # Heightfield. A gentle vertical bias makes the composition read as
    # terrain rising toward the lower right rather than uniform mush.
    field = []
    for j in range(rows):
        for i in range(cols):
            nx = i / cols * scale
            ny = j / rows * scale * (rows / cols)
            v = noise.fractal(nx, ny, octaves=6)
            bias = (j / rows) * 0.22 + (i / cols) * 0.10
            field.append(v + bias)

    lo, hi = min(field), max(field)
    span = hi - lo or 1.0

    sx = width / (cols - 1)
    sy = height / (rows - 1)

    out = []
    out.append(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" '
        f'height="{height}" viewBox="0 0 {width} {height}">'
    )

    # --- background: deep vertical wash plus two soft accent glows ---
    out.append("<defs>")
    out.append(
        '<linearGradient id="sky" x1="0" y1="0" x2="0.35" y2="1">'
        f'<stop offset="0%" stop-color="{PALETTE["crust"]}"/>'
        f'<stop offset="55%" stop-color="{PALETTE["mantle"]}"/>'
        f'<stop offset="100%" stop-color="{PALETTE["base"]}"/>'
        "</linearGradient>"
    )
    out.append(
        '<radialGradient id="glowA" cx="0.74" cy="0.72" r="0.62">'
        f'<stop offset="0%" stop-color="{PALETTE["mauve"]}" stop-opacity="{glow}"/>'
        f'<stop offset="55%" stop-color="{PALETTE["blue"]}" stop-opacity="{glow * 0.35:.3f}"/>'
        '<stop offset="100%" stop-color="#000000" stop-opacity="0"/>'
        "</radialGradient>"
    )
    out.append(
        '<radialGradient id="glowB" cx="0.18" cy="0.14" r="0.55">'
        f'<stop offset="0%" stop-color="{PALETTE["sapphire"]}" stop-opacity="{glow * 0.45:.3f}"/>'
        '<stop offset="100%" stop-color="#000000" stop-opacity="0"/>'
        "</radialGradient>"
    )
    out.append("</defs>")
    out.append(f'<rect width="{width}" height="{height}" fill="url(#sky)"/>')
    out.append(f'<rect width="{width}" height="{height}" fill="url(#glowB)"/>')
    out.append(f'<rect width="{width}" height="{height}" fill="url(#glowA)"/>')

    # --- contour lines ---
    # Each level is drawn twice: a wide, faint pass that reads as atmospheric
    # bloom around the ridge, then the crisp line on top. Peaks get more of
    # both, which is what gives the image depth instead of a flat net.
    out.append('<g fill="none" stroke-linecap="round" stroke-linejoin="round">')
    for n in range(levels):
        t = (n + 0.5) / levels
        level = lo + span * t
        segs = contour_segments(field, cols, rows, level)
        if not segs:
            continue

        paths = join_segments(segs)
        if not paths:
            continue
        rendered = [
            " ".join(f"{p[0] * sx:.1f},{p[1] * sy:.1f}" for p in path)
            for path in paths
        ]

        colour = ramp_colour(t)

        # bloom pass, only on the upper half of the elevation range
        if t > 0.45:
            b = (t - 0.45) / 0.55
            out.append(
                f'<g stroke="{colour}" stroke-width="{6 + 14 * b:.1f}" '
                f'opacity="{0.030 + 0.075 * b:.3f}">'
            )
            out.extend(f'<polyline points="{pts}"/>' for pts in rendered)
            out.append("</g>")

        # crisp pass
        opacity = 0.20 + 0.68 * (t ** 1.4)
        stroke = 1.0 + 2.8 * (t ** 2.2)
        out.append(
            f'<g stroke="{colour}" stroke-width="{stroke:.2f}" '
            f'opacity="{opacity:.3f}">'
        )
        out.extend(f'<polyline points="{pts}"/>' for pts in rendered)
        out.append("</g>")
    out.append("</g>")

    # --- vignette so desktop icons in the corners stay readable ---
    out.append(
        '<defs><radialGradient id="vig" cx="0.5" cy="0.45" r="0.78">'
        '<stop offset="55%" stop-color="#000000" stop-opacity="0"/>'
        f'<stop offset="100%" stop-color="{PALETTE["crust"]}" stop-opacity="0.55"/>'
        "</radialGradient></defs>"
    )
    out.append(f'<rect width="{width}" height="{height}" fill="url(#vig)"/>')

    out.append("</svg>")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--width", type=int, default=3456)
    ap.add_argument("--height", type=int, default=2234)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--levels", type=int, default=26,
                    help="number of contour lines")
    ap.add_argument("--grid", type=int, default=220,
                    help="heightfield resolution; higher is smoother and slower")
    ap.add_argument("--scale", type=float, default=3.2,
                    help="noise zoom; lower means broader landforms")
    ap.add_argument("--glow", type=float, default=0.30,
                    help="accent glow strength, 0 to 1")
    ap.add_argument("-o", "--out", default="topo.svg")
    args = ap.parse_args()

    svg = build_svg(args.width, args.height, args.seed,
                    args.levels, args.grid, args.scale, args.glow)
    with open(args.out, "w", encoding="utf8") as fh:
        fh.write(svg)
    print(f"wrote {args.out}  ({len(svg) / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
