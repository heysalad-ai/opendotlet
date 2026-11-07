from common import *

# ---------- Desk Dotlet in a huddle ----------
dev = f'''<div class="od" style="width: 640px; height: 844px; background: #e9e3d6; padding: 40px; display: flex; flex-direction: column; align-items: center; gap: 24px; text-align: center">
<span class="concept" style="align-self: flex-end; background: #fbf7f0">Mockup · not shipped firmware</span>
<div style="width: 420px; height: 420px; border-radius: 50%; background: #2a2522; padding: 22px; box-shadow: 6px 6px 0 0 #14110f">
<img src="{B["st_listen"]}" alt="Round display showing the listening face with sound bars on the peel" style="display: block; width: 376px; height: 376px; border-radius: 50%"></div>
<p class="disp" style="margin: 0; font-size: 30px; line-height: 34px">Kofi is speaking</p>
<p style="margin: 0; max-width: 480px">During a huddle the Desk Dotlet becomes the face of whoever holds the mic: their character colour, their eyes, sound bars on the peel. Tap the screen to raise your hand; press and hold to mute.</p>
<div style="display: flex; gap: 18px; margin-top: 8px">
<figure style="margin: 0; display: flex; flex-direction: column; align-items: center; gap: 8px; font-size: 13px; font-weight: 600"><img src="{B["st_work"]}" alt="" style="width: 96px; height: 96px; border-radius: 50%; border: 6px solid #2a2522">Between calls:<br>the Lead's status</figure>
<figure style="margin: 0; display: flex; flex-direction: column; align-items: center; gap: 8px; font-size: 13px; font-weight: 600"><img src="{B["st_approve"]}" alt="" style="width: 96px; height: 96px; border-radius: 50%; border: 6px solid #2a2522">A Dotlet<br>needs your yes</figure></div></div>'''
open("project/DeviceCall.dc.html", "w").write(page("Desk Dotlet in a huddle", 640, 844, dev))

# shared compact app body used inside both desktop windows
def roster(size=32):
    return "".join(f'<li style="display: flex; gap: 10px; align-items: center; padding: 6px 8px; border-radius: 8px; {"background: rgba(20,17,15,.07);" if k == "kofi" else ""}">{av(c, size, st, alt=n)}<span style="flex: 1; min-width: 0"><span style="display: block; font-weight: 600; font-size: 14px; line-height: 18px">{n}</span><span class="muted" style="display: block; font-size: 12px; line-height: 16px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{s}</span></span></li>' for k, n, t, c, st, s in TEAM)


def thread_compact():
    return f'''<div style="display: flex; flex-direction: column; gap: 16px">
<p style="margin: 0; display: flex; gap: 10px">{av("coral", 32, alt="Kofi")}<span><b>Kofi</b> <span class="muted" style="font-size: 12px">09:12</span><br>Split launch week three ways: Mira on prices, Pip on the demo, Sol on the post.</span></p>
<p style="margin: 0; display: flex; gap: 10px">{av("sky", 32, alt="Mira")}<span><b>Mira</b> <span class="muted" style="font-size: 12px">09:40</span><br>Parts price check is done. Two suppliers can ship this week.</span></p>
<div class="card" style="padding: 12px 14px; display: flex; gap: 10px; align-items: center; border-color: var(--approve); box-shadow: 3px 3px 0 0 var(--approve)">{av("sun", 32, "approval", alt="Sol")}<span style="flex: 1"><b>Sol</b> wants to post the launch announcement to X</span><button class="btn btn-s">Approve</button><button class="btn2 btn-s">Review</button></div></div>'''


def mini_call(dark_bg="#14110f"):
    return f'''<div class="od dark card" style="width: 300px; padding: 14px; background: {dark_bg}; display: flex; flex-direction: column; gap: 12px; box-shadow: 0 12px 32px rgba(0,0,0,.35)">
<p style="margin: 0; display: flex; align-items: center; gap: 8px; font-size: 13px"><span class="dot" style="background: #ff7a6b"></span><b>Huddle</b> · #launch-week<span class="muted" style="margin-left: auto">12:41</span></p>
<div style="display: flex; align-items: center; gap: 12px">{av("coral", 52, speak=True, alt="Kofi")}<span style="flex: 1"><b style="display: block">Kofi</b><span style="display: flex; gap: 6px; align-items: center; font-size: 13px">{bars(5)}speaking</span></span>
<span style="display: flex">{"".join(f'<span style="margin-left: -6px">{av(c, 26, alt=n)}</span>' for n, c in [("Mira", "sky"), ("Sol", "sun"), ("Pip", "lilac")])}</span></div>
<div style="display: flex; gap: 8px; justify-content: space-between"><button class="ibtn" style="width: 40px; height: 40px" aria-label="Mute">{ic("mic", 18)}</button><button class="ibtn" style="width: 40px; height: 40px" aria-label="Interrupt">{ic("hand", 18)}</button><button class="ibtn" style="width: 40px; height: 40px" aria-label="Pass the mic">{ic("arrow", 18)}</button><button class="ibtn" style="width: 40px; height: 40px" aria-label="Open full window">{ic("screen", 18)}</button><button class="ibtn" style="width: 40px; height: 40px; background: #c4281a; border-color: #c4281a; color: #fbf7f0" aria-label="End">{ic("end", 18)}</button></div></div>'''


# ---------- Windows 11 ----------
cap = lambda glyph: f'<span style="width: 46px; height: 32px; display: flex; align-items: center; justify-content: center">{glyph}</span>'
win = f'''<div style="position: relative; width: 1440px; height: 900px; background: #cfd8e3; font-family: 'Segoe UI Variable', 'Segoe UI', Inter, sans-serif; overflow: hidden">
<div class="od" style="position: absolute; left: 60px; top: 48px; width: 1000px; height: 720px; background: #f3f1ec; border-radius: 8px; border: 1px solid #9aa3ad; box-shadow: 0 24px 60px rgba(0,0,0,.25); overflow: hidden; display: flex; flex-direction: column; font-family: inherit">
<header style="height: 40px; display: flex; align-items: center; gap: 10px; padding-left: 14px; background: #ebe7df">
<img src="{B["symbol"]}" alt="" style="width: 18px; height: 18px"><span style="font-size: 12px">OpenDotlet</span><span class="concept" style="margin-left: 8px; height: 18px; font-size: 10px">Concept</span>
<span style="margin-left: auto; display: flex">{cap('<span style="width: 10px; height: 1px; background: #14110f"></span>')}{cap('<span style="width: 10px; height: 10px; border: 1px solid #14110f"></span>')}{cap(ic("x", 14, sw=1.5))}</span></header>
<div style="flex: 1; display: grid; grid-template-columns: 260px 1fr; min-height: 0">
<nav style="background: #ebe7df; padding: 12px 10px; display: flex; flex-direction: column; gap: 14px">
<button class="btn btn-s" style="justify-content: center">{ic("phone", 16)}Start huddle</button>
<section><p class="lbl" style="margin: 0 0 6px 8px">Team</p><ul style="list-style: none; margin: 0; padding: 0">{roster()}</ul></section>
<section><p class="lbl" style="margin: 0 0 6px 8px">Rooms</p><p style="margin: 0 0 0 8px; font-size: 14px; display: flex; gap: 6px; align-items: center; font-weight: 600">{ic("hash", 14)}launch-week</p></section></nav>
<main style="background: #fbf7f0; padding: 22px 26px; display: flex; flex-direction: column; gap: 18px; border-top-left-radius: 8px">
<h1 class="disp" style="margin: 0; font-size: 26px; line-height: 30px">#launch-week</h1>{thread_compact()}
<form style="margin-top: auto; display: flex; gap: 8px; align-items: center; border: 2px solid #14110f; border-radius: 12px; padding: 6px 6px 6px 12px; background: #fff"><input aria-label="Message" placeholder="Message the team" style="flex: 1; border: 0; outline: 0; font: inherit"><button type="button" class="ibtn" style="width: 36px; height: 36px" aria-label="Talk">{ic("mic", 18)}</button></form></main></div></div>
<div style="position: absolute; right: 40px; top: 120px">{mini_call()}<p style="margin: 8px 0 0; font-size: 12px; color: #14110f">Always-on-top call window</p></div>
<div class="od" role="status" style="position: absolute; right: 16px; bottom: 64px; width: 364px; background: #f9f9f9; border: 1px solid #c6c6c6; border-radius: 8px; box-shadow: 0 12px 32px rgba(0,0,0,.2); padding: 14px 16px; font-family: inherit">
<p style="margin: 0 0 10px; display: flex; gap: 8px; align-items: center; font-size: 12px"><img src="{B["symbol"]}" alt="" style="width: 16px; height: 16px">OpenDotlet<span class="muted" style="margin-left: auto">now</span></p>
<p style="margin: 0 0 12px; display: flex; gap: 12px">{av("sun", 40, "approval", alt="Sol")}<span><b style="display: block">Sol needs a yes</b><span style="font-size: 14px">Post the launch announcement to X?</span></span></p>
<div style="display: flex; gap: 8px"><button class="btn2 btn-s" style="flex: 1; justify-content: center; border-radius: 6px; border-width: 1px">Approve</button><button class="btn2 btn-s" style="flex: 1; justify-content: center; border-radius: 6px; border-width: 1px">Open</button></div></div>
<footer style="position: absolute; left: 0; right: 0; bottom: 0; height: 48px; background: rgba(243,243,243,.92); border-top: 1px solid #c6c6c6; display: flex; align-items: center; justify-content: center; gap: 8px">
<span style="width: 40px; height: 40px; border-radius: 6px; background: rgba(0,0,0,.06); display: flex; align-items: center; justify-content: center; position: relative"><img src="{B["symbol"]}" alt="OpenDotlet in the taskbar" style="width: 26px; height: 26px"><span style="position: absolute; top: 2px; right: 2px; min-width: 16px; height: 16px; border-radius: 8px; background: #a35f00; color: #fff; font-size: 10px; font-weight: 700; display: flex; align-items: center; justify-content: center">2</span></span></footer></div>'''
open("project/Windows.dc.html", "w").write(page("Windows 11 app", 1440, 900, win))

# ---------- macOS ----------
tl = '<span style="display: flex; gap: 8px">' + "".join(f'<span style="width: 12px; height: 12px; border-radius: 50%; background: {c}"></span>' for c in ("#ff5f57", "#febc2e", "#28c840")) + "</span>"
menu_items = "".join(f'<span style="{"font-weight: 700" if i == 0 else ""}">{m}</span>' for i, m in enumerate(["OpenDotlet", "File", "Edit", "View", "Team", "Window", "Help"]))
extra = f'''<div class="od card" style="position: absolute; right: 120px; top: 34px; width: 320px; padding: 12px; background: #fbf7f0; box-shadow: 0 16px 40px rgba(0,0,0,.3); font-family: inherit">
<p style="margin: 0 0 8px; display: flex; align-items: center; gap: 8px"><b>Your team</b><span class="muted" style="margin-left: auto; font-size: 12px">2 need you</span></p>
<ul style="list-style: none; margin: 0 0 10px; padding: 0">{roster(28)}</ul>
<div style="display: flex; gap: 8px"><button class="btn btn-s" style="flex: 1; justify-content: center">{ic("phone", 16)}Start huddle</button><button class="btn2 btn-s">⌘⇧H</button></div></div>'''
mac = f'''<div style="position: relative; width: 1440px; height: 900px; background: #d9cfc0; font-family: -apple-system, 'SF Pro Text', Inter, sans-serif; overflow: hidden">
<header style="height: 28px; background: rgba(251,247,240,.85); display: flex; align-items: center; gap: 20px; padding: 0 16px; font-size: 13px">
{menu_items}<span style="margin-left: auto; display: flex; align-items: center; gap: 16px"><span style="display: flex; align-items: center; gap: 6px; padding: 2px 8px; border-radius: 6px; background: rgba(20,17,15,.12)"><img src="{B["symbol"]}" alt="OpenDotlet menu bar extra" style="width: 16px; height: 16px">{bars(4, (5, 10, 7, 12))}</span><span>Sat 01:20</span></span></header>
{extra}
<div class="od" style="position: absolute; left: 70px; top: 70px; width: 1000px; height: 700px; border-radius: 12px; overflow: hidden; box-shadow: 0 30px 70px rgba(0,0,0,.3); border: 1px solid rgba(0,0,0,.25); display: grid; grid-template-columns: 240px 1fr; font-family: inherit">
<nav style="background: rgba(233,227,214,.92); padding: 16px 10px; display: flex; flex-direction: column; gap: 14px">
{tl}<span class="concept" style="align-self: flex-start; margin-top: 4px">Concept</span>
<section><p class="lbl" style="margin: 0 0 6px 8px">Team</p><ul style="list-style: none; margin: 0; padding: 0">{roster()}</ul></section>
<section><p class="lbl" style="margin: 0 0 6px 8px">Rooms</p><p style="margin: 0 0 0 8px; font-size: 14px; display: flex; gap: 6px; align-items: center; font-weight: 600">{ic("hash", 14)}launch-week</p></section></nav>
<main style="background: #fbf7f0; display: flex; flex-direction: column; min-width: 0">
<div style="height: 52px; border-bottom: 1px solid #d9d2c3; display: flex; align-items: center; gap: 12px; padding: 0 20px"><b style="font-size: 15px">#launch-week</b><span class="muted" style="font-size: 13px">4 Dotlets</span><button class="btn btn-s" style="margin-left: auto">{ic("phone", 16)}Huddle</button></div>
<div style="padding: 22px 26px; display: flex; flex-direction: column; gap: 18px; flex: 1">{thread_compact()}</div></main></div>
<div style="position: absolute; right: 60px; top: 380px">{mini_call()}<p style="margin: 8px 0 0; font-size: 12px; color: #14110f">Floating call panel · stays over other apps</p></div>
<div style="position: absolute; left: 50%; transform: translateX(-50%); bottom: 10px; height: 64px; padding: 8px 14px; border-radius: 18px; background: rgba(251,247,240,.6); border: 1px solid rgba(255,255,255,.5); display: flex; gap: 10px; align-items: center">
<span style="position: relative"><img src="{B["symbol"]}" alt="OpenDotlet in the Dock" style="width: 48px; height: 48px"><span style="position: absolute; top: -4px; right: -4px; min-width: 20px; height: 20px; border-radius: 10px; background: #c4281a; color: #fff; font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center">2</span></span></div></div>'''
open("project/MacOS.dc.html", "w").write(page("macOS app", 1440, 900, mac))
print("ok")
