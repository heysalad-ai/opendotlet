"""Shared pieces for the OpenDotlet Teams canvas artboards."""
B = {
    "coral": "/_blob/5786a4967249801b7b2aac9e10504ffa", "mint": "/_blob/777e714609c429455241335f26356018",
    "sky": "/_blob/12ad41f580675b5dbed2d869b5ab5452", "lilac": "/_blob/9c3958ae8a65c2ab194cd6a15db1acbd",
    "sun": "/_blob/1a98f5e991fffca01ea12a3edd7c114d", "ink": "/_blob/911da205c7ab2741709d9a9aacf39f60",
    "paper": "/_blob/51f6b2091526bfeee281e22f9957a1b6", "symbol": "/_blob/8e591856360c6351b6d8c39f3a4854f4",
    "lockup": "/_blob/902ff305ab83e9ef7403fea3f3914eb5", "lockup_dark": "/_blob/e6dfd33e6ce2cf6ef11ff1b5339d9b33",
    "st_listen": "/_blob/3ba63073a6470e3ea10c0f64fc6f0f64", "st_work": "/_blob/f0283af65e38d3edfa1f074d020ec03c",
    "st_approve": "/_blob/94b488832cdedc241446fae5ab6694c5",
}

# The example team (invented names)
TEAM = [
    ("kofi", "Kofi", "Lead · chief of staff", "coral", "working", "Planning launch week"),
    ("mira", "Mira", "Research", "sky", "done", "Competitor scan ready"),
    ("sol", "Sol", "Writer", "sun", "approval", "Launch post needs a yes"),
    ("pip", "Pip", "Builder", "lilac", "working", "Building the demo"),
    ("juno", "Juno", "Ops & money", "mint", "idle", "Weekly brief at 9:00 Mon"),
]
COL = {k: c for k, _, _, c, _, _ in TEAM}

FONTS = ('<link rel="preconnect" href="https://fonts.googleapis.com">'
         '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&amp;family=JetBrains+Mono&amp;family=Nunito:wght@800;900&amp;display=swap" rel="stylesheet">')

CSS = """
body{margin:0}
*{box-sizing:border-box}
.od{--coral:#ff5c39;--ink:#14110f;--paper:#fbf7f0;--surface:#ffffff;--backing:#e9e3d6;--muted:#6f6a63;--hair:#d9d2c3;
 --listen:#1f6fd1;--think:#6a3de8;--approve:#a35f00;--done:#1b7f49;--error:#c4281a;
 font-family:Inter,system-ui,sans-serif;color:var(--ink);font-size:15px;line-height:22px}
.od.dark{--ink:#fbf7f0;--paper:#14110f;--surface:#1f1a17;--backing:#2a2522;--muted:#b5ada3;--hair:#3a3430;
 --listen:#6cb4ff;--think:#b79cff;--approve:#ffb547;--done:#4fd18b;--error:#ff7a6b}
.disp{font-family:Nunito,ui-rounded,sans-serif;font-weight:900;letter-spacing:-0.01em}
.h2{font-family:Nunito,ui-rounded,sans-serif;font-weight:800;font-size:20px;line-height:26px;margin:0}
.lbl{font-size:12px;line-height:16px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
.muted{color:var(--muted)}
.mono{font-family:"JetBrains Mono",ui-monospace,monospace;font-size:13px}
.btn{display:inline-flex;align-items:center;gap:8px;font:600 14px/20px Inter,sans-serif;padding:10px 18px;border:2px solid #14110f;border-radius:14px;background:#ff5c39;color:#14110f;box-shadow:3px 3px 0 0 #14110f;cursor:pointer;white-space:nowrap}
.dark .btn{box-shadow:3px 3px 0 0 #000}
.btn2{display:inline-flex;align-items:center;gap:8px;font:600 14px/20px Inter,sans-serif;padding:10px 18px;border:2px solid var(--ink);border-radius:14px;background:var(--surface);color:var(--ink);cursor:pointer;white-space:nowrap}
.btn-s{padding:6px 12px;font-size:13px;border-radius:12px}
.ibtn{display:inline-flex;align-items:center;justify-content:center;width:44px;height:44px;border-radius:50%;border:2px solid var(--ink);background:var(--surface);color:var(--ink);cursor:pointer}
.chip{display:inline-flex;align-items:center;gap:6px;height:26px;padding:0 10px 0 8px;border:2px solid var(--ink);border-radius:999px;background:var(--surface);font-size:12px;font-weight:600;white-space:nowrap}
.dot{width:8px;height:8px;border-radius:50%;display:inline-block;flex:none}
.card{background:var(--surface);border:2px solid var(--ink);border-radius:20px;box-shadow:3px 3px 0 0 #14110f}
.dark .card{box-shadow:3px 3px 0 0 #000}
.av{position:relative;display:inline-block;flex:none}
.av img{display:block;width:100%;height:100%}
.badge{position:absolute;right:-2px;bottom:-2px;width:40%;height:40%;min-width:14px;min-height:14px;border-radius:50%;background:var(--surface);border:2px solid var(--ink);display:flex;align-items:center;justify-content:center}
.badge svg{width:70%;height:70%}
.speak{outline:4px solid #ff5c39;outline-offset:4px;border-radius:50%}
.concept{display:inline-flex;align-items:center;height:22px;padding:0 8px;border-radius:999px;background:var(--backing);color:var(--muted);font-size:11px;font-weight:600;letter-spacing:.06em;text-transform:uppercase}
.bars{display:inline-flex;align-items:flex-end;gap:3px;height:18px}
.bars i{display:block;width:4px;border-radius:2px;background:#ff5c39}
"""

ICON = {
    "mic": '<path d="M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3z"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
    "micoff": '<path d="M9 9v3a3 3 0 0 0 5.1 2.1M15 9.3V6a3 3 0 0 0-5.7-1.3"/><path d="M5 11a7 7 0 0 0 11.5 5.3M19 11a7 7 0 0 1-.6 2.8M12 18v3M3 3l18 18"/>',
    "phone": '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>',
    "end": '<path d="M3 15c5-5 13-5 18 0l-2.5 2.5-3.5-1.5v-3a10 10 0 0 0-6 0v3L5.5 17.5z"/>',
    "hand": '<path d="M8 13V5a1.5 1.5 0 0 1 3 0v6M11 11V4a1.5 1.5 0 0 1 3 0v7M14 11V5.5a1.5 1.5 0 0 1 3 0V14a7 7 0 0 1-7 7h-.5a6 6 0 0 1-4.6-2.2L3 15.5a1.6 1.6 0 0 1 2.4-2L8 16"/>',
    "plus": '<path d="M12 5v14M5 12h14"/>',
    "check": '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    "x": '<path d="M6 6l12 12M18 6L6 18"/>',
    "screen": '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>',
    "users": '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.6a3.5 3.5 0 0 1 0 6.8M18 14a6.5 6.5 0 0 1 3.5 6"/>',
    "hash": '<path d="M5 9h14M5 15h14M10 4L8 20M16 4l-2 16"/>',
    "send": '<path d="M4 12l16-8-6 16-2.5-6.5z"/>',
    "settings": '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M2 12h3M19 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/>',
    "clock": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    "arrow": '<path d="M5 12h14M13 6l6 6-6 6"/>',
    "play": '<path d="M8 5v14l11-7z"/>',
    "search": '<circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/>',
    "monitor": '<rect x="3" y="4" width="18" height="13" rx="2"/><path d="M7 8l3 3-3 3M12 14h5"/>',
    "chev": '<path d="M9 6l6 6-6 6"/>',
    "home": '<path d="M4 11l8-7 8 7v9h-5v-6H9v6H4z"/>',
    "lock": '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
    "msg": '<path d="M4 5h16v11H9l-5 4z"/>',
    "cc": '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M10 10.5a2 2 0 1 0 0 3M16 10.5a2 2 0 1 0 0 3"/>',
}


def ic(name, size=20, color="currentColor", sw=2):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="{sw}" '
            f'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">{ICON[name]}</svg>')


GLYPH = {  # status glyphs, same vocabulary as the device peel
    "working": '<svg viewBox="0 0 16 16" aria-hidden="true"><circle cx="8" cy="8" r="5.5" fill="none" stroke="var(--ink)" stroke-opacity=".25" stroke-width="2.4"/><path d="M8 2.5A5.5 5.5 0 0 1 13.5 8" fill="none" stroke="var(--ink)" stroke-width="2.4" stroke-linecap="round"/></svg>',
    "done": '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M3 8.5l3.2 3.2L13 4.8" fill="none" stroke="var(--done)" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    "approval": '<svg viewBox="0 0 16 16" aria-hidden="true"><circle cx="8" cy="8" r="7" fill="var(--approve)"/><path d="M6 6.2a2 2 0 1 1 2.8 1.8c-.5.3-.8.6-.8 1.2v.3" fill="none" stroke="var(--surface)" stroke-width="1.8" stroke-linecap="round"/><circle cx="8" cy="11.8" r="1" fill="var(--surface)"/></svg>',
    "thinking": '<svg viewBox="0 0 16 16" aria-hidden="true"><circle cx="3.5" cy="8" r="1.9" fill="var(--think)"/><circle cx="8" cy="8" r="1.9" fill="var(--think)" opacity=".7"/><circle cx="12.5" cy="8" r="1.9" fill="var(--think)" opacity=".4"/></svg>',
    "listening": '<svg viewBox="0 0 16 16" aria-hidden="true"><rect x="2.5" y="5.5" width="2.4" height="5" rx="1.2" fill="var(--listen)"/><rect x="6.8" y="3" width="2.4" height="10" rx="1.2" fill="var(--listen)"/><rect x="11.1" y="4.5" width="2.4" height="7" rx="1.2" fill="var(--listen)"/></svg>',
    "idle": '<svg viewBox="0 0 16 16" aria-hidden="true"><circle cx="8" cy="8" r="3" fill="var(--muted)"/></svg>',
    "offline": '<svg viewBox="0 0 16 16" aria-hidden="true"><circle cx="8" cy="8" r="4.5" fill="none" stroke="var(--muted)" stroke-width="2.2"/></svg>',
}
WORD = {"working": "Working", "done": "Done", "approval": "Needs you", "thinking": "Thinking", "listening": "Listening", "idle": "Idle", "offline": "Offline"}


def av(colour, size=40, state=None, speak=False, alt=""):
    b = f'<span class="badge">{GLYPH[state]}</span>' if state else ""
    return (f'<span class="av{" speak" if speak else ""}" style="width: {size}px; height: {size}px">'
            f'<img src="{B[colour]}" alt="{alt}">{b}</span>')


def chip(state, text=None):
    return f'<span class="chip">{GLYPH[state].replace("<svg ", "<svg width=\"14\" height=\"14\" ")}{text or WORD[state]}</span>'


def bars(n=7, h=(6, 12, 18, 10, 16, 8, 13)):
    return '<span class="bars" aria-hidden="true">' + "".join(f'<i style="height: {h[i % len(h)]}px"></i>' for i in range(n)) + "</span>"


def page(title, w, h, body, extra_css=""):
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
{FONTS}
<style>
{CSS}
{extra_css}
</style>
</helmet>
{body}
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":{w},"height":{h}}}}}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
"""
