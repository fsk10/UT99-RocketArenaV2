"""Builds the textures of RocketArenaV2Media (the V2 menu and F2 screen).

The menu itself is drawn by code (panels, cards, text). Only what needs a real font or
a shape is a texture: the logo, the game type titles, "SERVER INFO" and the button icons.
They are drawn STY_Translucent (added to what is behind), so black is see-through and
the textures carry no background.

    python make_media.py <out dir> [--preview <png>]

Writes 8-bit BMPs for src/RocketArenaV2Media/Textures and prints the content size of
each text texture (the code draws only that part, see RAMenuTools). Needs Pillow and the
fonts in deps/fonts (Bebas Neue: OFL, Permanent Marker: Apache 2.0).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = os.path.join(ROOT, "deps", "fonts")
BEBAS = os.path.join(FONTS, "BebasNeue-Regular.ttf")
MARKER = os.path.join(FONTS, "PermanentMarker-Regular.ttf")

# UT shows canvas colors brighter than their texel values: about 255*(c/255)^0.3
# (2x blending plus Brightness 1.0, measured in game). The colors are stored through
# the inverse curve so they end up as designed. RASlideMenu's colors use the same curve.
GAMMA = 0.3
GOLD = (245, 197, 66)
TEAL = (38, 200, 214)
RED = (228, 28, 36)
WHITE = (255, 255, 255)

# Flat textures: Panel is drawn STY_Modulated (darkens what is behind it), White is
# tinted with DrawColor for fills and lines.
SOLIDS = {"Panel": (12, 22, 24), "White": (255, 255, 255)}


def stored(c):
    return tuple(int(round(255 * (v / 255) ** (1 / GAMMA))) for v in c)


def text_image(text, font, size, color, stroke=0, stroke_color=None):
    """Tight RGB image of text on black."""
    f = ImageFont.truetype(font, size)
    l, t, r, b = f.getbbox(text, stroke_width=stroke)
    img = Image.new("RGB", (r - l, b - t))
    ImageDraw.Draw(img).text((-l, -t), text, font=f, fill=color, stroke_width=stroke, stroke_fill=stroke_color)
    return img


def on_texture(content, w, h):
    """Content placed top-left on a black w x h texture (content scaled down if needed)."""
    s = min(1.0, w / content.width, h / content.height)
    if s < 1:
        content = content.resize((int(content.width * s), int(content.height * s)), Image.LANCZOS)
    tex = Image.new("RGB", (w, h))
    tex.paste(content, (0, 0))
    return tex, content.size


def make_logo():
    """ROCKET ARENA in gold Bebas Neue + a tilted red marker "V2" with a white stroke."""
    title = text_image("ROCKET ARENA", BEBAS, 200, stored(GOLD))
    v2 = text_image("V2", MARKER, 170, stored(RED), stroke=7, stroke_color=stored(WHITE))
    v2 = v2.convert("RGBA")
    v2.putalpha(v2.convert("L").point(lambda v: 255 if v > 0 else 0))
    v2 = v2.rotate(6, resample=Image.BICUBIC, expand=True)
    gap = 24
    img = Image.new("RGB", (title.width + gap + v2.width, max(title.height, v2.height) + 8))
    img.paste(title, (0, (img.height - title.height) // 2))
    img.paste(v2, (title.width + gap, (img.height - v2.height) // 2 - 4), v2)
    return on_texture(img, 1024, 128)


def make_title(text, color):
    return on_texture(text_image(text, BEBAS, 120, stored(color)), 512, 128)


def icon(draw_fn):
    """64x64 white icon, drawn at 4x and scaled down. Tinted with DrawColor in game."""
    big = Image.new("RGB", (256, 256))
    draw_fn(ImageDraw.Draw(big), stored(WHITE))
    return big.resize((64, 64), Image.LANCZOS)


def draw_create(d, c):
    d.rectangle((40, 40, 216, 216), outline=c, width=22)
    d.rectangle((117, 80, 139, 176), fill=c)
    d.rectangle((80, 117, 176, 139), fill=c)


def draw_join(d, c):
    d.rectangle((48, 36, 128, 112), outline=c, width=20)
    d.rectangle((24, 140, 160, 160), fill=c)
    d.rectangle((24, 140, 44, 216), fill=c)
    d.rectangle((140, 140, 160, 180), fill=c)
    d.rectangle((182, 92, 202, 172), fill=c)
    d.rectangle((152, 122, 232, 142), fill=c)


def draw_enter(d, c):
    d.line([(120, 40), (56, 40), (56, 216), (120, 216)], fill=c, width=22, joint="curve")
    d.rectangle((96, 117, 196, 139), fill=c)
    d.polygon([(232, 128), (172, 72), (172, 184)], fill=c)


def draw_spectate(d, c):
    d.polygon([(20, 128), (72, 60), (184, 60), (236, 128), (184, 196), (72, 196)], outline=c, width=22)
    d.rectangle((104, 104, 152, 152), fill=c)


def draw_auto(d, c):
    d.line([(32, 80), (120, 80), (170, 176), (204, 176)], fill=c, width=22)
    d.line([(32, 176), (120, 176), (170, 80), (204, 80)], fill=c, width=22)
    d.polygon([(240, 80), (196, 44), (196, 116)], fill=c)
    d.polygon([(240, 176), (196, 140), (196, 212)], fill=c)


def draw_admin(d, c):
    """Gear: a ring with eight teeth."""
    import math
    for i in range(8):
        a = i * math.pi / 4
        x, y = 128 + 92 * math.cos(a), 128 + 92 * math.sin(a)
        d.line([(128, 128), (x, y)], fill=c, width=40)
    d.ellipse((52, 52, 204, 204), fill=c)
    d.ellipse((96, 96, 160, 160), fill=(0, 0, 0))


def draw_settings(d, c):
    """Sliders: three lines, each with a knob."""
    for y, x in ((64, 168), (128, 88), (192, 148)):
        d.rectangle((28, y - 10, 228, y + 10), fill=c)
        d.ellipse((x - 30, y - 30, x + 30, y + 30), fill=c)
        d.ellipse((x - 12, y - 12, x + 12, y + 12), fill=(0, 0, 0))


ICONS = {"IconCreate": draw_create, "IconJoin": draw_join, "IconEnter": draw_enter,
         "IconSpectate": draw_spectate, "IconAuto": draw_auto, "IconAdmin": draw_admin,
         "IconSettings": draw_settings}


def build_all():
    tex, sizes = {}, {}
    tex["Logo"], sizes["Logo"] = make_logo()
    for name, text in (("TitleMulti", "MULTI ARENA"), ("TitleClan", "CLAN ARENA"), ("TitleRobin", "ROUND ROBIN")):
        tex[name], sizes[name] = make_title(text, TEAL)
    tex["TitleServerInfo"], sizes["TitleServerInfo"] = make_title("SERVER INFO", GOLD)
    tex["TitleUpNext"], sizes["TitleUpNext"] = make_title("YOU'RE UP NEXT", GOLD)
    tex["TitleGetReady"], sizes["TitleGetReady"] = make_title("GET READY", GOLD)
    for name, fn in ICONS.items():
        tex[name] = icon(fn)
    for name, color in SOLIDS.items():
        tex[name] = Image.new("RGB", (16, 16), color)
    return tex, sizes


if __name__ == "__main__":
    dst = sys.argv[1]
    os.makedirs(dst, exist_ok=True)
    textures, sizes = build_all()
    for name, img in textures.items():
        # 8-bit palettized BMP: what UCC imports, and small to download.
        img.quantize(256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE) \
            .save(os.path.join(dst, name + ".bmp"))
    for name, (w, h) in sizes.items():
        print(f"{name}: content {w}x{h}")
    if "--preview" in sys.argv:
        out = sys.argv[sys.argv.index("--preview") + 1]
        imgs = [t.point(lambda v: int(255 * (v / 255) ** GAMMA)) for t in textures.values()]
        sheet = Image.new("RGB", (1024, sum(i.height + 8 for i in imgs)), (40, 40, 40))
        y = 0
        for i in imgs:
            sheet.paste(i, (0, y))
            y += i.height + 8
        sheet.save(out)
