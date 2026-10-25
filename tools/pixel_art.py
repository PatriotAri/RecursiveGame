"""Placeholder pixel art for Recursive, drawn as ASCII grids.

Each sprite is a list of equal-length strings; every character is looked up
in PALETTE ('.' is transparent). Grids are centred on a canvas of the given
size, so a sprite can be drawn small and still land on the 32x32 item grid
the existing art uses.

    python3 tools/pixel_art.py
"""
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "recursive", "game")

PALETTE = {
    ".": (0, 0, 0, 0),
    "k": (16, 16, 20, 255),       # outline
    "w": (240, 240, 245, 255),    # highlight
    "s": (170, 175, 185, 255),    # steel
    "S": (115, 120, 132, 255),    # steel shade
    "b": (110, 64, 36, 255),      # wood / leather
    "B": (72, 40, 22, 255),       # wood shade
    "g": (230, 190, 60, 255),     # gold
    "G": (170, 125, 30, 255),     # gold shade
    "r": (200, 50, 50, 255),      # red
    "o": (245, 140, 40, 255),     # orange
    "y": (255, 230, 110, 255),    # yellow
    "p": (150, 80, 220, 255),     # purple
    "P": (95, 45, 160, 255),      # purple shade
    "c": (120, 220, 255, 255),    # cyan
    "C": (60, 140, 220, 255),     # blue
    "e": (90, 200, 90, 255),      # green
    "E": (50, 130, 60, 255),      # green shade
    "d": (60, 60, 70, 255),       # dark grey
    "D": (95, 95, 105, 255),      # mid grey
    "l": (140, 140, 150, 255),    # light grey
}


def render(grid, size=(32, 32)):
    h, w = len(grid), len(grid[0])
    assert all(len(r) == w for r in grid), "ragged grid"
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    ox, oy = (size[0] - w) // 2, (size[1] - h) // 2
    for y, row in enumerate(grid):
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((ox + x, oy + y), PALETTE[ch])
    return img


def save(img, rel):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("wrote", rel)


THROWING_DAGGER = [
    "..k..",
    ".kwk.",
    ".kwk.",
    ".ksk.",
    ".ksk.",
    ".ksk.",
    ".kSk.",
    "kkkkk",
    "kgGgk",
    "kkkkk",
    ".kbk.",
    ".kBk.",
    ".kbk.",
    ".kgk.",
    "..k..",
]

FIREBALL = [
    "....oo....",
    "...oyyo...",
    "..oyyyyo..",
    ".oyywwyyo.",
    "oyywwwwyyo",
    "oyywwwwyyo",
    ".oyywwyyo.",
    "..oyyyyo..",
    "...ryyr...",
    "....rr....",
]

STAFF = [
    "...kkk...",
    "..kcCck..",
    ".kcwcCck.",
    ".kCccCCk.",
    "..kCCCk..",
    "...kgk...",
    "...kGk...",
    "...kbk...",
    "...kbk...",
    "...kBk...",
    "...kbk...",
    "...kbk...",
    "...kBk...",
    "...kbk...",
    "...kbk...",
    "...kBk...",
    "...kbk...",
    "...kbk...",
    "...kBk...",
    "...kbk...",
    "...kbk...",
    "...kBk...",
    "...kbk...",
    "...kgk...",
    "....k....",
]

SPRITES = {
    "items/equipment/weapons/tier_1/throwing_dagger/Throwing Dagger.png": (THROWING_DAGGER, (32, 32)),
    # Tight canvas for the thrown version so its collision shape and sprite agree.
    "items/equipment/weapons/tier_1/throwing_dagger/throwing_dagger_projectile.png": (THROWING_DAGGER, (5, 15)),
    "spells/fireball/fireball.png": (FIREBALL, (10, 10)),
    "spells/fireball/Fireball Icon.png": (FIREBALL, (32, 32)),
    "items/equipment/weapons/tier_1/apprentice_staff/Apprentice Staff.png": (STAFF, (32, 32)),
}

if __name__ == "__main__":
    for rel, (grid, size) in SPRITES.items():
        save(render(grid, size), rel)
