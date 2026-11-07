from common import *

W, H = 390, 844
tabbar = lambda active: '<nav aria-label="Tabs" style="position: absolute; left: 0; right: 0; bottom: 0; height: 84px; padding: 10px 18px 24px; display: flex; justify-content: space-around; background: var(--surface); border-top: 2px solid var(--ink)">' + "".join(
    f'<a href="#" style="display: flex; flex-direction: column; align-items: center; gap: 2px; font-size: 11px; font-weight: 600; text-decoration: none; color: {"var(--ink)" if n == active else "var(--muted)"}; min-width: 56px">{ic(i, 22)}{n}</a>'
    for i, n in [("users", "Team"), ("hash", "Rooms"), ("phone", "Huddles"), ("settings", "Settings")]) + "</nav>"

# ---------- Mobile home ----------
rows = "".join(f'''<li class="card" style="display: flex; gap: 12px; align-items: center; padding: 12px; box-shadow: none">{av(c, 48, st, alt=n)}
<span style="flex: 1; min-width: 0"><b style="display: block">{n} <span class="muted" style="font-weight: 400; font-size: 13px">· {t}</span></b><span class="muted" style="display: block; font-size: 13px; line-height: 18px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{s}</span></span>{ic("chev", 18)}</li>''' for k, n, t, c, st, s in TEAM)

home = f'''<div class="od" style="position: relative; width: {W}px; height: {H}px; overflow: hidden; background: var(--paper)">
<header style="padding: 24px 20px 12px; display: flex; align-items: center; justify-content: space-between">
<img src="{B["lockup"]}" alt="OpenDotlet" style="height: 26px"><span class="concept">Concept</span></header>
<div style="padding: 0 20px 110px; display: flex; flex-direction: column; gap: 18px">
<h1 class="disp" style="margin: 4px 0 0; font-size: 30px; line-height: 34px">Good morning.<br>Two things need you.</h1>
<section class="card" style="padding: 14px; border-color: var(--approve); box-shadow: 3px 3px 0 0 var(--approve); display: flex; flex-direction: column; gap: 10px">
<p style="margin: 0; display: flex; gap: 10px; align-items: center">{av("sun", 36, "approval")}<span><b>Sol</b> wants to post the launch announcement</span></p>
<div style="display: flex; gap: 8px"><button class="btn btn-s" style="flex: 1; justify-content: center">Approve</button><button class="btn2 btn-s" style="flex: 1; justify-content: center">Review</button></div>
<p class="muted" style="margin: 0; font-size: 13px">+1 more · Juno, supplier payment</p></section>
<section><p class="lbl" style="margin: 0 0 10px">Your team</p><ul style="list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px">{rows}</ul></section></div>
<button class="btn" style="position: absolute; right: 20px; bottom: 104px; border-radius: 999px; padding: 14px 20px">{ic("phone", 18)}Huddle</button>
{tabbar("Team")}</div>'''
open("project/MobileHome.dc.html", "w").write(page("Mobile · Team", W, H, home))

# ---------- Mobile call ----------
small = "".join(f'<li style="display: flex; flex-direction: column; align-items: center; gap: 6px; font-size: 12px; font-weight: 600">{av(c, 56, st, alt=n)}{n}{"<span style=\"color: var(--approve)\">hand up</span>" if n == "Mira" else ""}</li>' for n, c, st in [("Mira", "sky", None), ("Sol", "sun", "listening"), ("Pip", "lilac", "working")])
call = f'''<div class="od dark" style="position: relative; width: {W}px; height: {H}px; overflow: hidden; background: #14110f; display: flex; flex-direction: column; align-items: center; padding: 28px 22px 30px">
<header style="width: 100%; display: flex; align-items: center; justify-content: space-between">
<span class="chip" style="background: #c4281a; color: #fbf7f0; border-color: #c4281a"><span class="dot" style="background: #fbf7f0"></span>12:41</span>
<b style="font-size: 14px">#launch-week</b><span class="concept" style="background: #2a2522; color: #b5ada3">Concept</span></header>
<div style="margin-top: 40px">{av("coral", 180, speak=True, alt="Kofi")}</div>
<p class="disp" style="margin: 26px 0 0; font-size: 34px; line-height: 38px">Kofi</p>
<p style="margin: 6px 0 0; display: flex; gap: 8px; align-items: center">{bars()}<b>Speaking</b><span class="muted">· Lead</span></p>
<p style="margin: 22px 0 0; padding: 12px 14px; border-radius: 16px; background: #2a2522; font-size: 14px; line-height: 20px; width: 100%">"Yes, if the parts land Wednesday. Mira, can you give us the supplier numbers?"</p>
<ul style="list-style: none; margin: 26px 0 0; padding: 0; display: flex; gap: 26px">{small}</ul>
<nav aria-label="Call controls" style="margin-top: auto; width: 100%; display: flex; justify-content: space-between; align-items: center">
<button class="ibtn" style="width: 60px; height: 60px" aria-label="Mute">{ic("mic", 24)}</button>
<button class="ibtn" style="width: 60px; height: 60px" aria-label="Interrupt">{ic("hand", 24)}</button>
<button class="ibtn" style="width: 60px; height: 60px" aria-label="Pass the mic">{ic("arrow", 24)}</button>
<button class="ibtn" style="width: 60px; height: 60px" aria-label="Transcript">{ic("cc", 24)}</button>
<button class="ibtn" style="width: 60px; height: 60px; background: #c4281a; border-color: #c4281a; color: #fbf7f0" aria-label="End huddle">{ic("end", 24)}</button></nav></div>'''
open("project/MobileCall.dc.html", "w").write(page("Mobile · Huddle", W, H, call))

# ---------- Incoming call from a Dotlet ----------
inc = f'''<div class="od" style="position: relative; width: {W}px; height: {H}px; overflow: hidden; background: #3ddc97; display: flex; flex-direction: column; align-items: center; padding: 56px 24px 40px; text-align: center">
<span class="concept" style="position: absolute; top: 20px; right: 20px; background: rgba(20,17,15,.12); color: #14110f">Concept</span>
<p style="margin: 0; font-weight: 600; color: #14110f">OpenDotlet · incoming huddle</p>
<div style="margin-top: 40px">{av("mint", 168, alt="Juno")}</div>
<p class="disp" style="margin: 26px 0 0; font-size: 40px; line-height: 44px; color: #14110f">Juno is calling</p>
<p style="margin: 8px 0 0; color: #14110f">Ops &amp; money · voice Alloy</p>
<section class="card" style="margin-top: 28px; padding: 16px; text-align: left; width: 100%; --surface: #ffffff; --ink: #14110f">
<p style="margin: 0 0 6px; display: flex; gap: 8px; align-items: center">{chip("approval", "Needs a yes")}</p>
<p style="margin: 0; font-size: 15px; line-height: 22px; color: #14110f">"The display supplier wants [AMOUNT] today to hold 100 units for Friday. Shall I pay it?"</p></section>
<div style="margin-top: 16px; display: flex; gap: 10px; width: 100%"><button class="btn2 btn-s" style="flex: 1; justify-content: center; --surface: #ffffff; --ink: #14110f; color: #14110f">{ic("check", 16)}Approve by text</button><button class="btn2 btn-s" style="flex: 1; justify-content: center; --surface: #ffffff; --ink: #14110f; color: #14110f">{ic("msg", 16)}Reply</button></div>
<div style="margin-top: auto; display: flex; justify-content: space-between; width: 100%; padding: 0 20px">
<span style="display: flex; flex-direction: column; align-items: center; gap: 8px; font-weight: 600; color: #14110f"><button class="ibtn" style="width: 72px; height: 72px; background: #c4281a; border-color: #14110f; color: #fbf7f0" aria-label="Decline">{ic("end", 28)}</button>Later</span>
<span style="display: flex; flex-direction: column; align-items: center; gap: 8px; font-weight: 600; color: #14110f"><button class="ibtn" style="width: 72px; height: 72px; background: #14110f; border-color: #14110f; color: #fbf7f0" aria-label="Answer">{ic("phone", 28)}</button>Answer</span></div>
<p style="margin: 18px 0 0; font-size: 12px; color: #14110f">Juno only calls for approvals. Change this in Juno › Permissions.</p></div>'''
open("project/MobileIncoming.dc.html", "w").write(page("Mobile · A Dotlet calls you", W, H, inc))
print("ok")
