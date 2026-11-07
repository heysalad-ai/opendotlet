"""Build the OpenDotlet Peel kit: SVG + PNG logo set, characters, device states, brand board."""
import os, subprocess, shutil
from peel import *

OUT = "/home/claude/out/opendotlet-brand-exploration-claude/04-brand-B-peel"
shutil.rmtree(OUT, ignore_errors=True)
FONT = "font-family:Inter,sans-serif"


def save(rel, svg):
    p = f"{OUT}/{rel}"; os.makedirs(os.path.dirname(p), exist_ok=True); open(p, "w").write(svg); return p


def png(svg, w, out):
    os.makedirs(os.path.dirname(out), exist_ok=True)
    subprocess.run(["rsvg-convert", "-w", str(w), svg, "-o", out], check=True)


def tile(inner, bg, scale=0.80):
    off = 512 * (1 - scale) / 2
    return f'<rect width="512" height="512" rx="115" fill="{bg}"/><g transform="translate({off},{off}) scale({scale})">{inner}</g>'


SYM = {
    "symbol": symbol(),
    "symbol-on-dark": symbol(line=INK, shadow=False),
    "symbol-black": symbol(fill=INK, line=INK, flap=PAPER, eye=PAPER, shadow=False),
    "symbol-white": symbol(fill=PAPER, line=PAPER, flap=INK, eye=INK, shadow=False),
    "favicon": favicon(),
    "app-tile-light": tile(symbol(), PAPER),
    "app-tile-dark": tile(symbol(shadow=False), INK),
    "avatar": f'<rect width="512" height="512" fill="{PAPER}"/><g transform="translate(66,66) scale(0.742)">{symbol()}</g>',
}
SIZES = [16, 32, 64, 128, 256, 512, 1024]
for n, inner in SYM.items():
    p = save(f"logo/svg/opendotlet-{n}.svg", svg_doc(512, 512, inner))
    for s in ([16, 32, 48, 64] if n == "favicon" else SIZES):
        png(p, s, f"{OUT}/logo/png/{n}/opendotlet-{n}-{s}.png")

# lockups — symbol on a dark ground keeps its ink outline: a sticker always has its edge
for n, args in {"lockup-horizontal": (INK, symbol()), "lockup-horizontal-on-dark": (PAPER, symbol(shadow=False)),
                "lockup-horizontal-black": (INK, SYM["symbol-black"]), "lockup-horizontal-white": (PAPER, SYM["symbol-white"])}.items():
    g, w, h = lockup_h(*args, mh=240)
    p = save(f"logo/svg/opendotlet-{n}.svg", svg_doc(int(w) + 40, int(h) + 40, f'<g transform="translate(20,20)">{g}</g>'))
    png(p, 1600, f"{OUT}/logo/png/opendotlet-{n}-1600.png")
for n, args in {"lockup-stacked": (INK, symbol()), "lockup-stacked-on-dark": (PAPER, symbol(shadow=False))}.items():
    g, w, h = lockup_v(*args, mh=360)
    p = save(f"logo/svg/opendotlet-{n}.svg", svg_doc(int(w) + 40, int(h) + 40, f'<g transform="translate(20,20)">{g}</g>'))
    png(p, 1200, f"{OUT}/logo/png/opendotlet-{n}-1200.png")
for n, col in (("wordmark", INK), ("wordmark-on-dark", PAPER)):
    g, w, h = wordmark(col, 120)
    p = save(f"logo/svg/opendotlet-{n}.svg", svg_doc(int(w) + 10, 170, f'<g transform="translate(5,12)">{g}</g>'))
    png(p, 1600, f"{OUT}/logo/png/opendotlet-{n}-1600.png")

# characters
for n in STICKERS:
    p = save(f"characters/svg/dotlet-{n}.svg", svg_doc(512, 512, character(n)))
    png(p, 512, f"{OUT}/characters/png/dotlet-{n}-512.png")

# device states (concepts)
for k, *_ in STATES:
    p = save(f"device/svg/state-{k}-412.svg", svg_doc(412, 412, f'<clipPath id="c"><circle cx="206" cy="206" r="206"/></clipPath><g clip-path="url(#c)">{device_state(k)}</g>'))
    png(p, 412, f"{OUT}/device/png/state-{k}-412.png")
for n in STICKERS:
    p = save(f"device/svg/boot-{n}-412.svg", svg_doc(412, 412, f'<clipPath id="c"><circle cx="206" cy="206" r="206"/></clipPath><g clip-path="url(#c)">{device_state("idle", n)}</g>'))


# ---------- brand board ----------
def T(x, y, s, size=20, weight=400, fill=INK, anchor="start"):
    return f'<text x="{x}" y="{y}" style="{FONT};font-size:{size}px;font-weight:{weight}" fill="{fill}" text-anchor="{anchor}">{s}</text>'


W, H = 2400, 2200
b = [f'<rect width="{W}" height="{H}" fill="{PAPER}"/>']
g, w, h = lockup_h(INK, symbol(), mh=200); b.append(f'<g transform="translate(80,70)">{g}</g>')
b.append(T(80, 340, "Peel · brand kit v0.1 · a sticker that came alive", 22, 400, MIST))
# hero dark panel
b.append(f'<rect x="1300" y="60" width="1020" height="300" rx="40" fill="{INK}"/>')
g, w, h = lockup_h(PAPER, symbol(shadow=False), mh=150); b.append(f'<g transform="translate({1810 - w/2},{210 - h/2})">{g}</g>')
# characters row
b.append(T(80, 440, "CHARACTERS — personality is the sticker colour, chosen by the owner", 18, 700, MIST))
for i, n in enumerate(STICKERS):
    b.append(f'<g transform="translate({80 + i*320},470) scale(0.53)">{character(n)}</g>')
    b.append(T(80 + i * 320 + 136, 770, n.capitalize(), 22, 700, INK, "middle"))
    b.append(T(80 + i * 320 + 136, 798, STICKERS[n][0], 17, 400, MIST, "middle"))
# device states
b.append(T(80, 880, "DEVICE STATES — status lives on the back of the peel; eyes change too (412×412 mockups)", 18, 700, MIST))
for i, (k, name, desc) in enumerate(STATES):
    cx = 80 + i * 290 + 125
    b.append(f'<circle cx="{cx}" cy="1040" r="130" fill="#2A2522"/>')
    b.append(f'<clipPath id="d{i}"><circle cx="{cx}" cy="1040" r="120"/></clipPath><g clip-path="url(#d{i})"><g transform="translate({cx-120},920) scale({240/412})">{device_state(k)}</g></g>')
    b.append(T(cx, 1205, name, 22, 700, INK, "middle"))
    for j, part in enumerate(desc.split(" · ")): b.append(T(cx, 1233 + j * 24, part, 16, 400, MIST, "middle"))
# one-colour + tiles + small sizes
b.append(T(80, 1350, "ONE-COLOUR · APP TILES · AVATAR", 18, 700, MIST))
b.append(f'<rect x="80" y="1370" width="260" height="260" rx="24" fill="#FFFFFF" stroke="{BACKING}" stroke-width="2"/><g transform="translate(110,1400) scale(0.39)">{SYM["symbol-black"]}</g>')
b.append(f'<rect x="360" y="1370" width="260" height="260" rx="24" fill="{INK}"/><g transform="translate(390,1400) scale(0.39)">{SYM["symbol-white"]}</g>')
b.append(f'<g transform="translate(660,1370) scale(0.508)">{SYM["app-tile-light"]}</g><rect x="660" y="1370" width="260" height="260" rx="58" fill="none" stroke="{BACKING}" stroke-width="2"/>')
b.append(f'<g transform="translate(940,1370) scale(0.508)">{SYM["app-tile-dark"]}</g>')
b.append(f'<clipPath id="av"><circle cx="1350" cy="1500" r="130"/></clipPath><g clip-path="url(#av)"><g transform="translate(1220,1370) scale(0.508)">{SYM["avatar"]}</g></g><circle cx="1350" cy="1500" r="130" fill="none" stroke="{BACKING}" stroke-width="2"/>')
b.append(T(1350, 1660, "GitHub avatar (circle crop)", 16, 400, MIST, "middle"))
# favicon sizes
import base64
x = 1560
for s in (16, 32, 48, 64):
    data = base64.b64encode(open(f"{OUT}/logo/png/favicon/opendotlet-favicon-{s}.png", "rb").read()).decode()
    b.append(f'<image x="{x}" y="{1500 - s/2}" width="{s}" height="{s}" xlink:href="data:image/png;base64,{data}"/>'); x += s + 30
b.append(T(1560, 1660, "favicon 16 · 32 · 48 · 64 px (actual)", 16, 400, MIST))
# palette
b.append(T(80, 1760, "COLOUR", 18, 700, MIST))
pal = [("Coral", CORAL), ("Ink", INK), ("Paper", PAPER), ("Backing", BACKING), ("Coral Deep", CORAL_DEEP), ("Mist", MIST)]
for i, (n, c) in enumerate(pal):
    x = 80 + i * 230
    b.append(f'<rect x="{x}" y="1780" width="210" height="150" rx="24" fill="{c}" stroke="{INK}" stroke-width="3"/>')
    b.append(T(x, 1965, n, 20, 700)); b.append(T(x, 1990, c, 17, 400, MIST))
b.append(T(1500, 1760, "TYPE (SIL OFL 1.1)", 18, 700, MIST))
d, w, _ = text_path("Nunito-Black.ttf", "Nunito Black", 64); b.append(f'<g transform="translate(1500,1850)"><path d="{d}" fill="{INK}"/></g>')
d, w, _ = text_path("Inter-Medium.ttf", "Inter — interface and body text", 32); b.append(f'<g transform="translate(1500,1910)"><path d="{d}" fill="{INK}"/></g>')
d, w, _ = text_path("JetBrainsMono-Regular.ttf", "JetBrains Mono — serial & code", 28); b.append(f'<g transform="translate(1500,1965)"><path d="{d}" fill="{INK}"/></g>')
b.append(T(80, 2120, "Rules: the ink outline and the peel are the logo — never drop either. Coral never carries white text (use Ink). Status is shown by eye shape + flap glyph, colour is a third cue.  Concept artwork · not affiliated with OpenAI · device faces are mockups.", 20, 400, GRAPHITE))
p = save("peel-brand-board.svg", svg_doc(W, H, "".join(b)))
png(p, 2400, f"{OUT}/peel-brand-board.png")
print("ok")
