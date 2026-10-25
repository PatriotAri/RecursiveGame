"""Placeholder pixel art for Recursive, drawn as ASCII grids.

Each sprite is a list of equal-length strings; every character is looked up
in PALETTE ('.' is transparent). Grids are centred on a canvas of the given
size, so a sprite can be drawn small and still land on the 32x32 item grid
the existing art uses.

    python3 tools/pixel_art.py
"""
import os

from PIL import Image, ImageDraw

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

ACID_GLOB = [
    "..ee..",
    ".eEEe.",
    "eEwEEe",
    "eEEEEe",
    ".eEEe.",
    "..ee..",
]

BAT_UP = [
    "k..................k",
    "kk................kk",
    "kPk..............kPk",
    "kPPk....k..k....kPPk",
    ".kPPk...kkkk...kPPk.",
    ".kPPPk.kPPPPk.kPPPk.",
    "..kPPPkPrPPrPkPPPk..",
    "..kPPPPPPPPPPPPPPk..",
    "...kPPPkPPPPkPPPk...",
    "....kkk.kPPk.kkk....",
    ".........kk.........",
]

BAT_DOWN = [
    "........k..k........",
    "........kkkk........",
    ".......kPPPPk.......",
    "......kPrPPrPk......",
    "...kkkPPPPPPPPkkk...",
    "..kPPPPkPPPPkPPPPk..",
    ".kPPPPk.kPPk.kPPPPk.",
    "kPPPPk...kk...kPPPPk",
    "kPPk............kPPk",
    "kPk..............kPk",
    "kk................kk",
]

BAT_DEAD = [
    "....................",
    "....................",
    "........k..k........",
    "........kkkk........",
    ".......kPPPPk.......",
    "......kPkPPkPk......",
    "......kPPPPPPk......",
    ".....kPPkPPkPPk.....",
    ".....kPk.kk.kPk.....",
    "......k......k......",
    "....................",
]

SHADOW = [
    "....dddddd....",
    "..dddddddddd..",
    ".dddddddddddd.",
    "..dddddddddd..",
    "....dddddd....",
]

def sheet(frames, size):
    img = Image.new("RGBA", (size[0] * len(frames), size[1]), (0, 0, 0, 0))
    for i, grid in enumerate(frames):
        img.paste(render(grid, size), (i * size[0], 0))
    return img

SPRITES = {
    "items/equipment/weapons/tier_1/throwing_dagger/Throwing Dagger.png": (THROWING_DAGGER, (32, 32)),
    # Tight canvas for the thrown version so its collision shape and sprite agree.
    "items/equipment/weapons/tier_1/throwing_dagger/throwing_dagger_projectile.png": (THROWING_DAGGER, (5, 15)),
    "spells/fireball/fireball.png": (FIREBALL, (10, 10)),
    "spells/fireball/Fireball Icon.png": (FIREBALL, (32, 32)),
    "items/equipment/weapons/tier_1/apprentice_staff/Apprentice Staff.png": (STAFF, (32, 32)),
    "actors/enemies/types/ranged/spitter/assets/acid_glob.png": (ACID_GLOB, (6, 6)),
    "actors/enemies/types/flyer/bat/assets/bat_shadow.png": (SHADOW, (14, 5)),
}

# --- larger props, drawn with shapes rather than grids ---------------------

def C(ch):
    return PALETTE[ch]


def door_closed():
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 63, 63], fill=C("d"))                 # stone frame
    d.rectangle([6, 4, 57, 63], fill=C("k"))
    d.rectangle([7, 5, 56, 63], fill=C("b"))                 # planks
    for x in range(7, 57, 10):
        d.line([x, 5, x, 63], fill=C("B"))
    for y in (16, 46):
        d.rectangle([7, y, 56, y + 3], fill=C("D"))          # iron bands
        for x in (12, 32, 51):
            d.point((x, y + 1), fill=C("l"))
    d.rectangle([47, 30, 50, 34], fill=C("g"))               # handle
    return img


def door_open():
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 63, 63], fill=C("d"))
    d.rectangle([6, 4, 57, 63], fill=(30, 26, 24, 255))      # dark doorway
    d.rectangle([6, 4, 12, 63], fill=C("k"))                 # door swung against the frame
    d.rectangle([7, 5, 11, 63], fill=C("b"))
    d.rectangle([7, 16, 11, 19], fill=C("D"))
    d.rectangle([7, 46, 11, 49], fill=C("D"))
    return img


def round_button(pressed):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([6, 18, 25, 31], fill=C("k"))                # pedestal
    d.rectangle([7, 19, 24, 31], fill=C("D"))
    d.rectangle([7, 19, 24, 21], fill=C("l"))
    top = 13 if not pressed else 16
    d.ellipse([9, top, 22, top + 7], fill=C("k"))
    d.ellipse([10, top + 1, 21, top + 6], fill=C("r") if not pressed else (110, 40, 40, 255))
    if not pressed:
        d.point((13, top + 2), fill=C("w"))
    return img


def shop_counter():
    img = Image.new("RGBA", (64, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 20, 63, 47], fill=C("k"))                # counter body
    d.rectangle([1, 21, 62, 47], fill=C("b"))
    d.rectangle([1, 21, 62, 25], fill=C("B"))
    for x in range(8, 63, 12):
        d.line([x, 26, x, 47], fill=C("B"))
    d.ellipse([6, 12, 15, 21], fill=C("k"))                  # red potion
    d.ellipse([7, 13, 14, 20], fill=C("r"))
    d.rectangle([9, 9, 12, 12], fill=C("y"))
    d.ellipse([20, 12, 29, 21], fill=C("k"))                 # blue potion
    d.ellipse([21, 13, 28, 20], fill=C("C"))
    d.rectangle([23, 9, 26, 12], fill=C("y"))
    for i, (x, y) in enumerate([(40, 17), (45, 15), (50, 17), (43, 12), (48, 12)]):
        d.ellipse([x, y, x + 5, y + 4], fill=C("G"))         # coin pile
        d.ellipse([x, y - 1, x + 5, y + 3], fill=C("g"))
    return img


PROPS = {
    "components/doors/assets/door_closed.png": door_closed,
    "components/doors/assets/door_open.png": door_open,
    "components/rounds/round_button/assets/round_button.png": lambda: round_button(False),
    "components/rounds/round_button/assets/round_button_pressed.png": lambda: round_button(True),
    "components/shop/assets/shop_counter.png": shop_counter,
}

SHEETS = {
    # idle/walk = frames 0-1, dead = frame 2.
    "actors/enemies/types/flyer/bat/assets/bat_sheet.png": ([BAT_UP, BAT_DOWN, BAT_DEAD], (32, 32)),
}

if __name__ == "__main__":
    for rel, (grid, size) in SPRITES.items():
        save(render(grid, size), rel)
    for rel, (frames, size) in SHEETS.items():
        save(sheet(frames, size), rel)
    for rel, draw in PROPS.items():
        save(draw(), rel)
