"""OpenDotlet brand exploration — shared geometry + helpers. Original artwork by Claude for HeySalad, 2026-11-06."""
import math, functools
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

FONTS = "/home/claude/fonts/ttf/"

# ---------- palette ----------
INK = "#0A0B0D"; PAPER = "#F5F4EF"; GRAPHITE = "#24272C"; MIST = "#8C929B"
CYAN = "#2BE0F0"; DEEP_CYAN = "#0B7F8F"
CORAL = "#FF5C39"; MINT = "#3DF5A0"; VIOLET = "#7C5CFF"
S_THINK = "#A78BFA"; S_WORK = "#4F8DFF"; S_APPROVE = "#FFB21E"; S_DONE = "#3FD07F"
S_ERROR = "#FF5247"; S_OFF = "#5F656E"


@functools.lru_cache(None)
def _font(path):
    blob = hb.Blob.from_file_path(path); face = hb.Face(blob)
    return face, hb.Font(face), TTFont(path)


def text_path(fontfile, text, size, x=0, y=0, track=0.0):
    """Return (svg path d, advance width, cap height px) for outlined text, baseline at y."""
    face, font, tt = _font(FONTS + fontfile)
    upem = face.upem
    buf = hb.Buffer(); buf.add_str(text); buf.guess_segment_properties()
    hb.shape(font, buf, {"kern": True, "liga": True})
    gs = tt.getGlyphSet(); order = tt.getGlyphOrder(); s = size / upem
    pen = SVGPathPen(gs); cx = 0
    n = len(buf.glyph_infos)
    for i, (info, pos) in enumerate(zip(buf.glyph_infos, buf.glyph_positions)):
        g = order[info.codepoint]
        tp = TransformPen(pen, (s, 0, 0, -s, x + (cx + pos.x_offset) * s, y - pos.y_offset * s))
        gs[g].draw(tp)
        cx += pos.x_advance + (track * upem if i < n - 1 else 0)
    cap = getattr(tt["OS/2"], "sCapHeight", 0.7 * upem) * s
    return pen.getCommands(), cx * s, cap


def cap_ratio(fontfile):
    face, font, tt = _font(FONTS + fontfile)
    return tt["OS/2"].sCapHeight / face.upem


def svg_doc(w, h, body, bg=None, extra=""):
    b = f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'viewBox="0 0 {w} {h}" width="{w}" height="{h}" {extra}>{b}{body}</svg>')


def u_eye(cx, top, hw, depth, sw, color):
    """U-shaped eye, OPEN AT THE TOP. hw = half width, depth = straight part."""
    return (f'<path d="M{cx-hw},{top} V{top+depth} A{hw},{hw} 0 0 0 {cx+hw},{top+depth} V{top}" '
            f'fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>')


# =====================================================================
# Direction A — "Dot + Dotlet": a face disc plus its little companion dot
# =====================================================================
def mark_A(disc=INK, eye=CYAN, sat=CYAN):
    return (f'<circle cx="232" cy="232" r="196" fill="{disc}"/>'
            + u_eye(166, 190, 26, 42, 32, eye) + u_eye(298, 190, 26, 42, 32, eye)
            + f'<circle cx="428" cy="428" r="42" fill="{sat}"/>')


def mark_A_small(disc=INK, eye=CYAN, sat=CYAN):
    """Pixel-hinted 16/24 px variant: heavier eyes, larger dotlet."""
    return (f'<circle cx="226" cy="226" r="200" fill="{disc}"/>'
            + u_eye(150, 180, 32, 36, 48, eye) + u_eye(302, 180, 32, 36, 48, eye)
            + f'<circle cx="430" cy="430" r="58" fill="{sat}"/>')


# =====================================================================
# Direction B — "Peel": a sticker lifting off the desk
# =====================================================================
_R, _D = 188, 125
_h = math.sqrt(_R**2 - _D**2); _k = 0.70710678
P1 = (256 + (_D + _h) * _k, 256 + (_D - _h) * _k)
P2 = (256 + (_D - _h) * _k, 256 + (_D + _h) * _k)


def mark_B(fill=CORAL, line=INK, flap=PAPER, eye=INK, sw=20, shadow=True):
    p1 = f"{P1[0]:.1f},{P1[1]:.1f}"; p2 = f"{P2[0]:.1f},{P2[1]:.1f}"
    body = f'<path d="M{p1} A{_R},{_R} 0 1 0 {p2} Z" fill="{fill}" stroke="{line}" stroke-width="{sw}" stroke-linejoin="round"/>'
    sh = (f'<path d="M{p1} A{_R},{_R} 0 0 0 {p2} Z" transform="translate(-10,-10)" fill="{INK}" opacity="0.18"/>'
          if shadow else "")
    fl = f'<path d="M{p1} A{_R},{_R} 0 0 0 {p2} Z" fill="{flap}" stroke="{line}" stroke-width="{sw}" stroke-linejoin="round"/>'
    eyes = (f'<rect x="{196-18}" y="168" width="36" height="84" rx="18" fill="{eye}"/>'
            f'<rect x="{290-18}" y="168" width="36" height="84" rx="18" fill="{eye}"/>')
    return body + eyes + sh + fl


# =====================================================================
# Direction C — "Puck": the desk device itself as the icon
# =====================================================================
def mark_C(body=INK, ring="#3A3F46", screen="#121417", eye=MINT, port="#3A3F46"):
    return (f'<rect x="56" y="56" width="400" height="400" rx="118" fill="{body}"/>'
            f'<circle cx="256" cy="246" r="150" fill="{screen}" stroke="{ring}" stroke-width="12"/>'
            f'<circle cx="212" cy="246" r="28" fill="{eye}"/><circle cx="300" cy="246" r="28" fill="{eye}"/>'
            f'<rect x="230" y="420" width="52" height="12" rx="6" fill="{port}"/>')


# =====================================================================
# Direction D — "Open Ring": a ring open at the top, two eyes inside
# =====================================================================
def ring_arc(cx, cy, r, gap_deg=60):
    a1 = math.radians(-90 + gap_deg / 2); a2 = math.radians(-90 - gap_deg / 2)
    x1, y1 = cx + r * math.cos(a1), cy + r * math.sin(a1)
    x2, y2 = cx + r * math.cos(a2), cy + r * math.sin(a2)
    return f"M{x1:.1f},{y1:.1f} A{r},{r} 0 1 1 {x2:.1f},{y2:.1f}"


def mark_D(ring=VIOLET, eye=INK, sw=62):
    return (f'<path d="{ring_arc(256, 262, 166)}" fill="none" stroke="{ring}" stroke-width="{sw}" stroke-linecap="round"/>'
            f'<circle cx="208" cy="272" r="30" fill="{eye}"/><circle cx="304" cy="272" r="30" fill="{eye}"/>')


# ---------- device display mockups (412 x 412 round screen) ----------
def device_A(state="idle"):
    return face_A_state(state)


def screen_B():
    R, D = 206, 120; h = math.sqrt(R**2 - D**2); k = 0.70710678
    q1 = (206 + (D + h) * k, 206 + (D - h) * k); q2 = (206 + (D - h) * k, 206 + (D + h) * k)
    p1 = f"{q1[0]:.1f},{q1[1]:.1f}"; p2 = f"{q2[0]:.1f},{q2[1]:.1f}"
    return (f'<circle cx="206" cy="206" r="206" fill="{CORAL}"/>'
            f'<rect x="132" y="120" width="40" height="96" rx="20" fill="{INK}"/>'
            f'<rect x="234" y="120" width="40" height="96" rx="20" fill="{INK}"/>'
            f'<path d="M{p1} A{R},{R} 0 0 1 {p2} Z" fill="{INK}"/>'
            f'<path d="M{p1} A{R},{R} 0 0 0 {p2} Z" transform="translate(-10,-10)" fill="{INK}" opacity="0.25"/>'
            f'<path d="M{p1} A{R},{R} 0 0 0 {p2} Z" fill="{PAPER}"/>')


def screen_C():
    d, w, _ = text_path("JetBrainsMono-Regular.ttf", "ready", 26)
    return (f'<circle cx="206" cy="206" r="206" fill="#060708"/>'
            f'<circle cx="150" cy="190" r="38" fill="{MINT}"/><circle cx="262" cy="190" r="38" fill="{MINT}"/>'
            f'<g transform="translate({206 - w/2 - 8},300)"><path d="{d}" fill="{MIST}"/>'
            f'<rect x="{w + 6}" y="-20" width="14" height="24" fill="{MINT}"/></g>')


def screen_D():
    return (f'<circle cx="206" cy="206" r="206" fill="#060708"/>'
            f'<path d="{ring_arc(206, 206, 176, 56)}" fill="none" stroke="{VIOLET}" stroke-width="28" stroke-linecap="round"/>'
            f'<circle cx="158" cy="216" r="34" fill="{PAPER}"/><circle cx="254" cy="216" r="34" fill="{PAPER}"/>')


# ---------- Direction A expression / state system ----------
STATES = [
    ("idle", "Idle", "U U eyes · dotlet resting", CYAN),
    ("listening", "Listening", "O O wide eyes · dotlet emits sound arcs", CYAN),
    ("thinking", "Thinking", "eyes glance up-right · dotlet splits into 3 orbiting dots", S_THINK),
    ("working", "Working", "focused – – eyes · progress arc sweeps the rim", S_WORK),
    ("approval", "Approval needed", "eyes look at you · dotlet grows into a ? button", S_APPROVE),
    ("done", "Done", "happy U U · dotlet carries a check", S_DONE),
    ("offline", "Offline", "sleepy thin lines · dotlet becomes a hollow ring", S_OFF),
    ("error", "Error", "× × eyes · dotlet becomes a ! triangle", S_ERROR),
]


def face_A_state(state):
    c = dict((s[0], s[3]) for s in STATES)[state]
    bg = '<circle cx="206" cy="206" r="206" fill="#060708"/>'
    L, Rr, top = 124, 288, 150
    sx, sy, sr = 206 + 160 * 0.7071, 206 + 160 * 0.7071, 24
    eyes = sat = extra = ""
    if state in ("idle", "done"):
        eyes = u_eye(L, top, 34, 48, 40, c) + u_eye(Rr, top, 34, 48, 40, c)
    if state == "idle":
        sat = f'<circle cx="{sx:.0f}" cy="{sy:.0f}" r="{sr}" fill="{c}"/>'
    if state == "done":
        sat = (f'<circle cx="{sx:.0f}" cy="{sy:.0f}" r="34" fill="{c}"/>'
               f'<path d="M{sx-15:.0f},{sy:.0f} l10,11 l20,-22" fill="none" stroke="#060708" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>')
    if state == "listening":
        eyes = (f'<circle cx="{L}" cy="190" r="36" fill="none" stroke="{c}" stroke-width="20"/>'
                f'<circle cx="{Rr}" cy="190" r="36" fill="none" stroke="{c}" stroke-width="20"/>')
        sat = (f'<circle cx="{sx:.0f}" cy="{sy:.0f}" r="{sr}" fill="{c}"/>'
               + "".join(f'<path d="M{sx-r*0.92:.0f},{sy-r*0.38:.0f} A{r},{r} 0 0 1 {sx-r*0.38:.0f},{sy-r*0.92:.0f}" fill="none" stroke="{c}" stroke-width="8" stroke-linecap="round" opacity="{o}"/>'
                         for r, o in ((44, 0.9), (62, 0.5))))
    if state == "thinking":
        eyes = (f'<circle cx="{L+14}" cy="170" r="24" fill="{c}"/><circle cx="{Rr+14}" cy="170" r="24" fill="{c}"/>')
        sat = "".join(f'<circle cx="{206+150*math.cos(math.radians(a)):.0f}" cy="{206+150*math.sin(math.radians(a)):.0f}" r="{r}" fill="{c}" opacity="{o}"/>'
                      for a, r, o in ((45, 18, 1), (68, 13, 0.7), (88, 9, 0.45)))
    if state == "working":
        eyes = (f'<rect x="{L-38}" y="184" width="76" height="26" rx="13" fill="{c}"/>'
                f'<rect x="{Rr-38}" y="184" width="76" height="26" rx="13" fill="{c}"/>')
        extra = (f'<circle cx="206" cy="206" r="186" fill="none" stroke="{GRAPHITE}" stroke-width="12"/>'
                 f'<path d="M{206+186*math.cos(math.radians(-30)):.0f},{206+186*math.sin(math.radians(-30)):.0f} A186,186 0 0 1 {206+186*math.cos(math.radians(60)):.0f},{206+186*math.sin(math.radians(60)):.0f}" fill="none" stroke="{c}" stroke-width="12" stroke-linecap="round"/>')
    if state == "approval":
        eyes = (f'<circle cx="{L}" cy="194" r="30" fill="{c}"/><circle cx="{Rr}" cy="194" r="30" fill="{c}"/>')
        q, qw, _ = text_path("SpaceGrotesk-Bold.ttf", "?", 56)
        sat = (f'<rect x="{sx-40:.0f}" y="{sy-40:.0f}" width="80" height="80" rx="24" fill="{c}"/>'
               f'<g transform="translate({sx-qw/2:.0f},{sy+20:.0f})"><path d="{q}" fill="#060708"/></g>')
    if state == "offline":
        eyes = (f'<rect x="{L-34}" y="200" width="68" height="10" rx="5" fill="{c}"/>'
                f'<rect x="{Rr-34}" y="200" width="68" height="10" rx="5" fill="{c}"/>')
        sat = f'<circle cx="{sx:.0f}" cy="{sy:.0f}" r="{sr-4}" fill="none" stroke="{c}" stroke-width="7"/>'
    if state == "error":
        eyes = "".join(f'<path d="M{x-28},{166} l56,56 M{x+28},{166} l-56,56" stroke="{c}" stroke-width="20" stroke-linecap="round"/>' for x in (L, Rr))
        sat = (f'<path d="M{sx:.0f},{sy-36:.0f} L{sx+36:.0f},{sy+28:.0f} L{sx-36:.0f},{sy+28:.0f} Z" fill="{c}" stroke="{c}" stroke-width="10" stroke-linejoin="round"/>'
               f'<rect x="{sx-4:.0f}" y="{sy-16:.0f}" width="8" height="24" rx="4" fill="#060708"/><circle cx="{sx:.0f}" cy="{sy+18:.0f}" r="5" fill="#060708"/>')
    return bg + extra + eyes + sat


# ---------- wordmarks ----------
WM = {
    "A": dict(font="SpaceGrotesk-Bold.ttf", track=-0.02),
    "B": dict(font="Nunito-Black.ttf", track=-0.01),
    "C": dict(font="JetBrainsMono-Bold.ttf", track=-0.02),
    "D": dict(font="Inter-Bold.ttf", track=-0.03),
}


def wordmark(key, color, cap=60, accent=None):
    """Outlined wordmark group positioned with baseline at y=cap (top of caps at 0). Returns (svg, width, height)."""
    f = WM[key]["font"]; size = cap / cap_ratio(f)
    if key == "D":
        # custom open-ring O with two eyes, then "penDotlet"
        r = cap / 2; sw = cap * 0.2; rc = r - sw / 2
        o = (f'<path d="{ring_arc(r, r, rc, 64)}" fill="none" stroke="{accent or VIOLET}" stroke-width="{sw:.2f}" stroke-linecap="round"/>'
             f'<circle cx="{r-rc*0.36:.2f}" cy="{r+rc*0.12:.2f}" r="{sw*0.5:.2f}" fill="{color}"/>'
             f'<circle cx="{r+rc*0.36:.2f}" cy="{r+rc*0.12:.2f}" r="{sw*0.5:.2f}" fill="{color}"/>')
        d, w, _ = text_path(f, "penDotlet", size, x=cap * 1.06, y=cap, track=WM[key]["track"])
        return o + f'<path d="{d}" fill="{color}"/>', cap * 1.06 + w, cap
    d, w, _ = text_path(f, "OpenDotlet", size, x=0, y=cap, track=WM[key]["track"])
    g = f'<path d="{d}" fill="{color}"/>'
    if key == "C":
        g += f'<rect x="{w + cap*0.12:.1f}" y="0" width="{cap*0.5:.1f}" height="{cap:.1f}" fill="{accent or MINT}"/>'
        w += cap * 0.62
    return g, w, cap
