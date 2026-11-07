"""OpenDotlet — Peel (Direction B) identity: marks, characters, device states. Original artwork for HeySalad."""
import math
from lib import text_path, cap_ratio, u_eye, svg_doc

# ---------- palette ----------
INK = "#14110F"; PAPER = "#FBF7F0"; BACKING = "#E9E3D6"; CORAL = "#FF5C39"; CORAL_DEEP = "#C2381A"
MIST = "#6F6A63"; GRAPHITE = "#2A2522"
STICKERS = {  # character colour -> (fill, eye, flap back)
    "coral": ("#FF5C39", INK, PAPER), "mint": ("#3DDC97", INK, PAPER), "sky": ("#4DB8FF", INK, PAPER),
    "lilac": ("#B18CFF", INK, PAPER), "sun": ("#FFC83D", INK, PAPER),
    "ink": (INK, PAPER, "#3A3430"), "paper": (PAPER, INK, BACKING),
}
STATE = {"listening": "#1F8FFF", "thinking": "#7A4DFF", "working": "#14110F", "approval": "#E08A00",
         "done": "#1E9E5A", "error": "#E0301E", "offline": "#8A847C"}

# ---------- symbol geometry (512 box) ----------
R0, C0 = 188, 256
K = 0.70710678


def _chord(R, D, c):
    h = math.sqrt(R * R - D * D)
    p1 = (c + (D + h) * K, c + (D - h) * K); p2 = (c + (D - h) * K, c + (D + h) * K)
    return f"{p1[0]:.1f},{p1[1]:.1f}", f"{p2[0]:.1f},{p2[1]:.1f}"


def symbol(fill=CORAL, line=INK, flap=PAPER, eye=INK, sw=20, shadow=True, D=125):
    p1, p2 = _chord(R0, D, C0)
    s = f'<path d="M{p1} A{R0},{R0} 0 1 0 {p2} Z" fill="{fill}" stroke="{line}" stroke-width="{sw}" stroke-linejoin="round"/>'
    s += (f'<rect x="178" y="166" width="36" height="86" rx="18" fill="{eye}"/>'
          f'<rect x="272" y="166" width="36" height="86" rx="18" fill="{eye}"/>')
    if shadow:
        s += f'<path d="M{p1} A{R0},{R0} 0 0 0 {p2} Z" transform="translate(-10,-10)" fill="{INK}" opacity="0.18"/>'
    s += f'<path d="M{p1} A{R0},{R0} 0 0 0 {p2} Z" fill="{flap}" stroke="{line}" stroke-width="{sw}" stroke-linejoin="round"/>'
    return s


def favicon(fill=CORAL, line=INK, flap=PAPER, eye=INK):
    """16–48 px: thicker outline, bigger eyes, bigger simpler peel."""
    R, D, c = 210, 120, 256
    p1, p2 = _chord(R, D, c)
    return (f'<path d="M{p1} A{R},{R} 0 1 0 {p2} Z" fill="{fill}" stroke="{line}" stroke-width="36" stroke-linejoin="round"/>'
            f'<rect x="150" y="140" width="64" height="124" rx="32" fill="{eye}"/>'
            f'<rect x="276" y="140" width="64" height="124" rx="32" fill="{eye}"/>'
            f'<path d="M{p1} A{R},{R} 0 0 0 {p2} Z" fill="{flap}" stroke="{line}" stroke-width="36" stroke-linejoin="round"/>')


def character(name, size_box=512):
    f, e, b = STICKERS[name]
    line = INK if name != "ink" else INK
    return symbol(fill=f, line=line, flap=b, eye=e)


# ---------- wordmark ----------
WM_FONT = "Nunito-Black.ttf"


def wordmark(color, cap=60):
    size = cap / cap_ratio(WM_FONT)
    d, w, _ = text_path(WM_FONT, "OpenDotlet", size, x=0, y=cap, track=-0.01)
    return f'<path d="{d}" fill="{color}"/>', w, cap


def lockup_h(text=INK, sym=None, mh=120):
    sym = sym or symbol()
    cap = mh * 0.40
    g, w, _ = wordmark(text, cap)
    gap = mh * 0.18
    return (f'<g transform="scale({mh/512})">{sym}</g>'
            f'<g transform="translate({mh+gap:.1f},{(mh-cap)/2 + cap*0.02:.1f})">{g}</g>'), mh + gap + w, mh


def lockup_v(text=INK, sym=None, mh=200):
    sym = sym or symbol()
    cap = mh * 0.24
    g, w, _ = wordmark(text, cap)
    W = max(w, mh)
    return (f'<g transform="translate({(W-mh)/2:.1f},0) scale({mh/512})">{sym}</g>'
            f'<g transform="translate({(W-w)/2:.1f},{mh + mh*0.14:.1f})">{g}</g>'), W, mh + mh * 0.14 + cap


# ---------- device (412 round screen) ----------
def _flap_pts(R, D, c):
    return _chord(R, D, c)


def device_state(state="idle", colour="coral"):
    fill, eye, back = STICKERS[colour]
    R, c = 206, 206
    D = {"idle": 150, "approval": 104, "offline": None}.get(state, 130)
    o = f'<circle cx="206" cy="206" r="206" fill="{fill}"/>'
    # eyes
    L, Rr = 140, 240  # pill centres
    def pill(cx, cy, w, h):
        return f'<rect x="{cx-w/2:.0f}" y="{cy-h/2:.0f}" width="{w}" height="{h}" rx="{min(w,h)/2:.0f}" fill="{eye}"/>'
    if state in ("idle",):
        o += pill(L, 168, 40, 96) + pill(Rr, 168, 40, 96)
    elif state == "listening":
        o += pill(L, 150, 46, 120) + pill(Rr, 150, 46, 120)
    elif state == "thinking":
        o += pill(L - 14, 138, 40, 84) + pill(Rr - 14, 138, 40, 84)
    elif state == "working":
        o += pill(L, 176, 52, 30) + pill(Rr, 176, 52, 30)
    elif state == "approval":
        o += pill(L - 10, 140, 40, 80) + pill(Rr - 34, 140, 40, 80)
    elif state == "done":
        o += u_eye(L, 126, 28, 34, 32, eye) + u_eye(Rr, 126, 28, 34, 32, eye)
    elif state == "offline":
        o += pill(L, 176, 64, 14) + pill(Rr, 176, 64, 14)
    elif state == "error":
        o += "".join(f'<path d="M{x-26},{124} l52,52 M{x+26},{124} l-52,52" stroke="{eye}" stroke-width="22" stroke-linecap="round"/>' for x in (L, Rr))
    if D is None:  # offline: sticker pressed flat, a hairline seam where it would peel
        p1, p2 = _flap_pts(R, 150, c)
        o += f'<path d="M{p1} L{p2}" stroke="{eye}" stroke-width="5" stroke-dasharray="4 14" stroke-linecap="round" opacity="0.5"/>'
        return o
    p1, p2 = _flap_pts(R, D, c)
    o += f'<path d="M{p1} A{R},{R} 0 0 1 {p2} Z" fill="{INK}"/>'
    o += f'<path d="M{p1} A{R},{R} 0 0 0 {p2} Z" transform="translate(-9,-9)" fill="{INK}" opacity="0.22"/>'
    o += f'<path d="M{p1} A{R},{R} 0 0 0 {p2} Z" fill="{back}"/>'
    # status glyph on the back of the flap
    cen = D - 0.42 * (R - D); gx = c + cen * K; gy = c + cen * K
    s = (R - D) * 0.72  # glyph scale
    col = STATE.get(state, INK)
    if state == "listening":
        o += "".join(f'<rect x="{gx - s*0.55 + i*s*0.4:.0f}" y="{gy - hh*s/2:.0f}" width="{s*0.22:.0f}" height="{hh*s:.0f}" rx="{s*0.11:.0f}" fill="{col}"/>'
                     for i, hh in enumerate((0.5, 1.0, 0.7)))
    elif state == "thinking":
        o += "".join(f'<circle cx="{gx + (i-1)*s*0.42:.0f}" cy="{gy:.0f}" r="{s*0.14:.0f}" fill="{col}" opacity="{op}"/>' for i, op in enumerate((1, .7, .4)))
    elif state == "working":
        r = s * 0.42
        o += (f'<circle cx="{gx:.0f}" cy="{gy:.0f}" r="{r:.0f}" fill="none" stroke="{col}" stroke-opacity="0.2" stroke-width="{s*0.16:.0f}"/>'
              f'<path d="M{gx:.0f},{gy-r:.0f} A{r:.0f},{r:.0f} 0 0 1 {gx+r:.0f},{gy:.0f}" fill="none" stroke="{col}" stroke-width="{s*0.16:.0f}" stroke-linecap="round"/>')
    elif state == "approval":
        q, qw, qc = text_path("Nunito-Black.ttf", "?", s * 1.3)
        o += f'<g transform="translate({gx - qw/2:.0f},{gy + qc/2:.0f})"><path d="{q}" fill="{col}"/></g>'
    elif state == "done":
        o += f'<path d="M{gx-s*0.4:.0f},{gy:.0f} l{s*0.28:.0f},{s*0.3:.0f} l{s*0.52:.0f},{-s*0.58:.0f}" fill="none" stroke="{col}" stroke-width="{s*0.17:.0f}" stroke-linecap="round" stroke-linejoin="round"/>'
    elif state == "error":
        o += (f'<rect x="{gx - s*0.09:.0f}" y="{gy - s*0.5:.0f}" width="{s*0.18:.0f}" height="{s*0.62:.0f}" rx="{s*0.09:.0f}" fill="{col}"/>'
              f'<circle cx="{gx:.0f}" cy="{gy + s*0.36:.0f}" r="{s*0.11:.0f}" fill="{col}"/>')
    return o


STATES = [
    ("idle", "Idle", "pill eyes · small corner lift"),
    ("listening", "Listening", "tall pill eyes · sound bars on the flap"),
    ("thinking", "Thinking", "eyes glance up-left · three dots on the flap"),
    ("working", "Working", "squinting eyes · spinner on the flap"),
    ("approval", "Approval needed", "eyes look at the flap · big peel shows ?"),
    ("done", "Done", "happy U U eyes · check on the flap"),
    ("offline", "Offline", "closed-line eyes · sticker pressed flat"),
    ("error", "Error", "× × eyes · ! on the flap"),
]
