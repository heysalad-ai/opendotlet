from common import *

roster = "".join(f'''<li style="display: flex; gap: 12px; align-items: center; padding: 8px 10px; border-radius: 14px; {"background: var(--backing);" if k == "kofi" else ""}">
{av(c, 40, st, alt=n)}
<span style="min-width: 0; flex: 1"><span style="display: block; font-weight: 600">{n} <span class="muted" style="font-weight: 400">· {t}</span></span>
<span class="muted" style="display: block; font-size: 13px; line-height: 18px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{s}</span></span></li>''' for k, n, t, c, st, s in TEAM)

rooms = "".join(f'<li style="display: flex; gap: 10px; align-items: center; padding: 6px 10px; border-radius: 10px; {"font-weight: 600; background: var(--surface); border: 2px solid var(--ink);" if i == 0 else ""}">{ic("hash", 16)}{r}</li>'
                for i, r in enumerate(["launch-week", "inbox-zero", "device-firmware", "weekly-money"]))


def msg(colour, name, role, time, inner, you=False):
    who = ('<span style="width: 40px; height: 40px; border-radius: 50%; background: var(--ink); color: var(--paper); display: flex; align-items: center; justify-content: center; font-weight: 600; flex: none">PM</span>'
           if you else av(colour, 40, alt=name))
    return f'''<article style="display: flex; gap: 14px; align-items: flex-start">{who}
<div style="flex: 1; min-width: 0"><p style="margin: 0 0 4px"><b>{name}</b> <span class="muted" style="font-size: 13px">{role} · {time}</span></p>{inner}</div></article>'''


handoff = lambda a, b, task: f'''<p style="margin: 8px 0 0; display: inline-flex; align-items: center; gap: 8px; font-size: 13px; padding: 4px 10px 4px 4px; border-radius: 999px; background: var(--backing)">
{av(COL[a], 22)}{ic("arrow", 14)}{av(COL[b], 22)}<span><b>Handoff</b> · {task}</span></p>'''

thread = "".join([
    msg(None, "You", "", "09:12", "<p style=\"margin: 0\">Plan the OpenDotlet launch week. I want a post, a demo video and a price check on the parts before Friday.</p>", you=True),
    msg("coral", "Kofi", "Lead", "09:12", "<p style=\"margin: 0\">On it. I've split this three ways and I'll keep you posted here.</p>"
        + handoff("kofi", "mira", "parts price check") + " " + handoff("kofi", "pip", "demo build") + " " + handoff("kofi", "sol", "launch post")),
    msg("sky", "Mira", "Research", "09:40", f'''<p style="margin: 0 0 10px">Done. Display + board come to [PRICE] per unit at 100 units. Two suppliers can ship this week.</p>
<div class="card" style="display: flex; gap: 12px; align-items: center; padding: 12px 14px; max-width: 420px; box-shadow: none">
<span style="width: 40px; height: 48px; border-radius: 8px; background: var(--backing); display: flex; align-items: center; justify-content: center">{ic("msg", 20)}</span>
<span style="flex: 1"><b style="display: block">Parts price check.md</b><span class="muted" style="font-size: 13px">Document · 6 sources</span></span>{chip("done")}</div>'''),
    msg("lilac", "Pip", "Builder", "10:05", f'''<p style="margin: 0 0 10px">Recording the gallery demo on my computer. About 60% through.</p>
<div class="card" style="padding: 0; overflow: hidden; max-width: 460px; box-shadow: none">
<div style="background: #14110f; color: #fbf7f0; padding: 12px 14px; font-family: 'JetBrains Mono', monospace; font-size: 12px; line-height: 18px">$ idf.py -p /dev/ttyACM0 monitor<br>I (318) dotlet: gallery loaded 28 views<br>rec ● 00:41</div>
<div style="display: flex; align-items: center; gap: 10px; padding: 10px 14px">{chip("working")}<span style="flex: 1; height: 8px; border-radius: 4px; background: var(--backing); position: relative"><span style="position: absolute; left: 0; top: 0; bottom: 0; width: 60%; border-radius: 4px; background: var(--ink)"></span></span><a href="#" style="color: var(--ink); font-size: 13px; font-weight: 600">Watch Pip's screen</a></div></div>'''),
    msg("sun", "Sol", "Writer", "10:21", f'''<p style="margin: 0 0 10px">Draft's ready. I won't post anything public without your yes.</p>
<div class="card" style="padding: 16px; max-width: 520px; border-color: var(--approve); box-shadow: 3px 3px 0 0 var(--approve)">
<p style="margin: 0 0 6px; display: flex; gap: 8px; align-items: center">{chip("approval", "Approval needed")}<span class="muted" style="font-size: 13px">Post to X · @heysalad</span></p>
<p style="margin: 0 0 14px">"Meet OpenDotlet: an open-source AI companion with a little face on your desk. Bring your own API key…"</p>
<div style="display: flex; gap: 10px; flex-wrap: wrap"><button class="btn btn-s">{ic("check", 16)}Approve &amp; post</button><button class="btn2 btn-s">Edit</button><button class="btn2 btn-s">Not yet</button></div></div>'''),
])

right = f'''<aside class="r" style="border-left: 2px solid var(--hair); padding: 24px 20px; display: flex; flex-direction: column; gap: 28px">
<section><p class="lbl" style="margin: 0 0 10px">Needs you · 2</p>
<div class="card" style="padding: 12px; display: flex; gap: 10px; align-items: center; margin-bottom: 10px">{av("sun", 32, "approval")}<span style="flex: 1; font-size: 14px; line-height: 20px"><b>Sol</b> wants to post to X</span><button class="btn2 btn-s">Review</button></div>
<div class="card" style="padding: 12px; display: flex; gap: 10px; align-items: center">{av("mint", 32, "approval")}<span style="flex: 1; font-size: 14px; line-height: 20px"><b>Juno</b> wants to pay a supplier</span><button class="btn2 btn-s">Review</button></div></section>
<section><p class="lbl" style="margin: 0 0 10px">Running now</p>
<ul style="list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; font-size: 14px">
<li style="display: flex; gap: 10px; align-items: center">{av("lilac", 28, "working")}<span style="flex: 1">Demo video</span><span class="muted">60%</span></li>
<li style="display: flex; gap: 10px; align-items: center">{av("coral", 28, "working")}<span style="flex: 1">Launch plan</span><span class="muted">3 of 5</span></li></ul></section>
<section><p class="lbl" style="margin: 0 0 10px">Routines</p>
<ul style="list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; font-size: 14px">
<li style="display: flex; gap: 10px; align-items: center">{ic("clock", 18)}<span style="flex: 1">Weekly money brief</span><span class="muted">Mon 9:00 · Juno</span></li>
<li style="display: flex; gap: 10px; align-items: center">{ic("clock", 18)}<span style="flex: 1">Inbox sweep</span><span class="muted">Daily 8:00 · Kofi</span></li></ul></section>
<section class="card" style="padding: 16px; display: flex; gap: 14px; align-items: center; box-shadow: none">
<img src="{B["st_work"]}" alt="Desk Dotlet showing the working face" style="width: 64px; height: 64px; border-radius: 50%; border: 4px solid #2a2522">
<span><b style="display: block">Desk Dotlet</b><span class="muted" style="font-size: 13px; line-height: 18px">Showing Kofi · working<br>Tap it to join a huddle</span></span></section>
</aside>'''

body = f'''<div class="od app" style="min-height: 960px; background: var(--paper); display: grid; grid-template-columns: 300px 1fr 340px">
<nav class="l" style="border-right: 2px solid var(--hair); padding: 20px 16px; display: flex; flex-direction: column; gap: 22px">
<div style="display: flex; align-items: center; justify-content: space-between"><img src="{B["lockup"]}" alt="OpenDotlet" style="height: 30px"><span class="concept">Concept</span></div>
<label style="display: flex; align-items: center; gap: 8px; border: 2px solid var(--ink); border-radius: 12px; padding: 8px 12px; background: var(--surface)">{ic("search", 18)}<input aria-label="Search" placeholder="Search Dotlets, rooms, files" style="border: 0; outline: 0; font: inherit; background: transparent; width: 100%"></label>
<section><p class="lbl" style="margin: 0 0 8px 10px">Your team</p><ul style="list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 2px">{roster}</ul>
<button class="btn2 btn-s" style="margin: 10px 0 0 10px">{ic("plus", 16)}New Dotlet</button></section>
<section><p class="lbl" style="margin: 0 0 8px 10px">Rooms</p><ul style="list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 4px">{rooms}</ul></section>
<p class="mono muted" style="margin: auto 0 0 10px; display: flex; gap: 6px; align-items: center">{ic("lock", 14)}Your key · sk-••••3fa2</p>
</nav>
<main style="display: flex; flex-direction: column; min-width: 0">
<header style="display: flex; align-items: center; gap: 16px; padding: 16px 28px; border-bottom: 2px solid var(--hair); flex-wrap: wrap">
<h1 class="disp" style="margin: 0; font-size: 28px; line-height: 34px; display: flex; align-items: center; gap: 6px">{ic("hash", 24)}launch-week</h1>
<span style="display: flex; padding-left: 8px">{"".join(f'<span style="margin-left: -8px">{av(t[3], 30, alt=t[1])}</span>' for t in TEAM[:4])}</span>
<span class="muted" style="font-size: 13px">4 Dotlets · you</span>
<span style="margin-left: auto; display: flex; gap: 10px"><button class="btn2">{ic("users", 18)}Members</button><button class="btn">{ic("phone", 18)}Start huddle</button></span>
</header>
<div style="flex: 1; padding: 28px; display: flex; flex-direction: column; gap: 26px; max-width: 860px">{thread}
<p class="muted" style="margin: 0; display: flex; align-items: center; gap: 10px; font-size: 14px">{av("coral", 24, "thinking")} Kofi is lining up the next step…</p></div>
<form style="margin: 0 28px 24px; display: flex; gap: 10px; align-items: center; border: 2px solid var(--ink); border-radius: 18px; padding: 8px 8px 8px 16px; background: var(--surface); box-shadow: 3px 3px 0 0 #14110f">
<label style="flex: 1"><span class="lbl" style="position: absolute; left: -9999px">Message</span><input placeholder="Message the team, or @mention a Dotlet" style="border: 0; outline: 0; font: inherit; width: 100%; background: transparent"></label>
<button type="button" class="ibtn" aria-label="Talk">{ic("mic", 20)}</button><button type="submit" class="btn btn-s">{ic("send", 16)}Send</button></form>
</main>
{right}
</div>'''

css = "@media (max-width: 1100px){.app{grid-template-columns: 260px 1fr !important}.r{display: none !important}}@media (max-width: 760px){.app{grid-template-columns: 1fr !important}.l{display: none !important}}"
open("project/Main.dc.html", "w").write(page("Web · Team home", 1440, 960, body, css))
print("ok")
