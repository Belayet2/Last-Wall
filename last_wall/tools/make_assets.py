"""Generates the placeholder pixel-art PNGs in assets/sprites/.

Run from the project folder:  python tools/make_assets.py
Needs Pillow (pip install pillow).

You never have to run this again. To use your own art, just overwrite a PNG in
assets/sprites/ with the same file name (any size works: the game scales each
sprite to its gameplay size). See assets/README.md.
"""
import os
import random
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)

# Palette
OUTLINE = (26, 28, 44, 255)
STONE_L = (170, 176, 186, 255)
STONE_M = (124, 130, 142, 255)
STONE_D = (82, 88, 100, 255)
MORTAR = (58, 62, 74, 255)
HOLE = (34, 30, 36, 255)
SEA_D = (30, 78, 140, 255)
SEA = (43, 108, 176, 255)
SEA_L = (95, 168, 224, 255)
FOAM = (220, 236, 248, 255)
SAND = (224, 196, 138, 255)
SAND_D = (196, 166, 110, 255)
GRASS = (74, 122, 58, 255)
GRASS_L = (93, 143, 69, 255)
GRASS_D = (58, 98, 46, 255)
BLUE = (59, 111, 182, 255)
BLUE_D = (38, 74, 128, 255)
STEEL = (200, 208, 216, 255)
STEEL_D = (140, 150, 162, 255)
GOLD = (232, 184, 74, 255)
GOLD_L = (255, 215, 94, 255)
RED = (184, 58, 58, 255)
RED_D = (128, 36, 40, 255)
SKIN = (240, 200, 160, 255)
WOOD = (138, 90, 43, 255)
WOOD_D = (100, 64, 30, 255)
ROCK = (122, 122, 128, 255)
ROCK_L = (168, 168, 176, 255)
ROCK_D = (80, 80, 88, 255)
CLEAR = (0, 0, 0, 0)


def save(img, name):
    img.save(os.path.join(OUT, name))
    print("wrote", name, img.size)


def ellipse(d, cx, cy, rx, ry, fill, outline=None):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=fill, outline=outline)


def hero():
    img = Image.new("RGBA", (32, 32), CLEAR)
    d = ImageDraw.Draw(img)
    # arms reaching up to hold the shield
    d.rectangle([5, 4, 8, 16], fill=BLUE_D, outline=OUTLINE)
    d.rectangle([23, 4, 26, 16], fill=BLUE_D, outline=OUTLINE)
    d.rectangle([5, 3, 8, 5], fill=SKIN, outline=OUTLINE)
    d.rectangle([23, 3, 26, 5], fill=SKIN, outline=OUTLINE)
    # shoulders / body (seen from above)
    ellipse(d, 16, 19, 12, 8, BLUE, OUTLINE)
    d.line([8, 21, 24, 21], fill=BLUE_D)
    # helmet
    ellipse(d, 16, 17, 6, 6, STEEL, OUTLINE)
    d.line([16, 11, 16, 23], fill=RED, width=2)  # plume
    d.point([(13, 14), (14, 14)], fill=(255, 255, 255, 255))
    save(img, "hero.png")
    save(hero_icon(img), "icon.png")


def hero_icon(hero_img):
    bg = Image.new("RGBA", (64, 64), SEA_D)
    big = hero_img.resize((64, 64), Image.NEAREST)
    bg.alpha_composite(big)
    return bg


def shield():
    img = Image.new("RGBA", (55, 8), CLEAR)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, 54, 7], radius=3, fill=GOLD, outline=OUTLINE)
    d.rectangle([3, 2, 51, 5], fill=STEEL)
    d.line([3, 5, 51, 5], fill=STEEL_D)
    ellipse(d, 27, 3, 3, 2, GOLD_L, OUTLINE)  # center boss
    save(img, "shield.png")


def thrower():
    img = Image.new("RGBA", (32, 32), CLEAR)
    d = ImageDraw.Draw(img)
    # little boat
    d.polygon([(2, 20), (29, 20), (25, 29), (6, 29)], fill=WOOD, outline=OUTLINE)
    d.line([4, 23, 27, 23], fill=WOOD_D)
    d.line([5, 26, 26, 26], fill=WOOD_D)
    # thrower standing in the boat
    ellipse(d, 16, 16, 6, 5, RED, OUTLINE)
    d.line([12, 18, 20, 18], fill=RED_D)
    ellipse(d, 16, 10, 4, 4, SKIN, OUTLINE)
    d.rectangle([12, 6, 20, 8], fill=RED_D)  # bandana
    # raised arm with a rock
    d.line([21, 14, 25, 7], fill=SKIN, width=2)
    ellipse(d, 26, 5, 2, 2, ROCK, OUTLINE)
    save(img, "thrower.png")


def projectile():
    img = Image.new("RGBA", (12, 12), CLEAR)
    d = ImageDraw.Draw(img)
    ellipse(d, 5.5, 5.5, 5, 5, ROCK, OUTLINE)
    ellipse(d, 6.5, 6.5, 2.5, 2.5, ROCK_D)
    d.point([(3, 3), (4, 3), (3, 4)], fill=ROCK_L)
    save(img, "projectile_hostile.png")

    img = Image.new("RGBA", (12, 12), CLEAR)
    d = ImageDraw.Draw(img)
    ellipse(d, 5.5, 5.5, 5, 5, GOLD, (180, 120, 30, 255))
    ellipse(d, 5.5, 5.5, 3, 3, GOLD_L)
    ellipse(d, 5, 5, 1, 1, (255, 255, 240, 255))
    save(img, "projectile_returned.png")


def puff():
    size = 16
    img = Image.new("RGBA", (size, size), CLEAR)
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            dist = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / c
            if dist <= 1.0:
                a = int(255 * min(1.0, (1.0 - dist) * 2.2))
                img.putpixel((x, y), (255, 255, 255, a))
    save(img, "puff.png")


def wall(name, damage):
    w, h = 140, 20
    rnd = random.Random(7)
    img = Image.new("RGBA", (w, h), CLEAR)
    d = ImageDraw.Draw(img)
    top = 4
    # battlements (merlons)
    x = 0
    while x < w:
        missing = damage >= 2 and rnd.random() < 0.55
        if not missing:
            d.rectangle([x, 0, min(x + 7, w - 1), top], fill=STONE_L, outline=MORTAR)
        x += 12
    # body
    d.rectangle([0, top, w - 1, h - 1], fill=STONE_M)
    for row in range(top, h, 4):
        d.line([0, row, w - 1, row], fill=MORTAR)
        offset = 0 if ((row - top) // 4) % 2 == 0 else 5
        for bx in range(-offset, w, 10):
            d.line([bx, row, bx, min(row + 4, h - 1)], fill=MORTAR)
            shade = rnd.choice([STONE_M, STONE_M, STONE_L, STONE_D])
            d.rectangle([bx + 1, row + 1, bx + 8, min(row + 3, h - 1)], fill=shade)
    d.line([0, top, w - 1, top], fill=STONE_L)
    d.line([0, h - 1, w - 1, h - 1], fill=OUTLINE)
    # cracks
    if damage >= 1:
        for _ in range(6 if damage == 1 else 10):
            cx, cy = rnd.randint(4, w - 5), rnd.randint(top + 1, h - 3)
            for _ in range(5):
                nx, ny = cx + rnd.randint(-3, 3), cy + rnd.randint(1, 3)
                d.line([cx, cy, nx, ny], fill=OUTLINE)
                cx, cy = nx, min(ny, h - 2)
    # holes / missing chunks
    if damage >= 2:
        for _ in range(9):
            hx, hy = rnd.randint(2, w - 10), rnd.randint(top, h - 6)
            d.rectangle([hx, hy, hx + rnd.randint(4, 9), hy + rnd.randint(2, 5)], fill=HOLE)
    save(img, name)


def background():
    w, h = 140, 180
    rnd = random.Random(3)
    img = Image.new("RGBA", (w, h), GRASS)
    d = ImageDraw.Draw(img)
    sea_end = 38
    d.rectangle([0, 0, w - 1, sea_end], fill=SEA)
    d.rectangle([0, 0, w - 1, 10], fill=SEA_D)
    for _ in range(45):
        x, y = rnd.randint(0, w - 6), rnd.randint(2, sea_end - 3)
        d.line([x, y, x + rnd.randint(2, 5), y], fill=SEA_L)
    # shore foam + sand
    for x in range(w):
        fy = sea_end + (1 if (x // 6) % 2 else 0)
        d.point((x, fy), fill=FOAM)
    d.rectangle([0, sea_end + 2, w - 1, sea_end + 9], fill=SAND)
    for _ in range(40):
        d.point((rnd.randint(0, w - 1), rnd.randint(sea_end + 2, sea_end + 9)), fill=SAND_D)
    # grass tufts
    for _ in range(140):
        x, y = rnd.randint(0, w - 1), rnd.randint(sea_end + 11, h - 1)
        d.point((x, y), fill=rnd.choice([GRASS_L, GRASS_D]))
    save(img, "background.png")


if __name__ == "__main__":
    hero()
    shield()
    thrower()
    projectile()
    puff()
    wall("wall_full.png", 0)
    wall("wall_cracked.png", 1)
    wall("wall_broken.png", 2)
    background()
