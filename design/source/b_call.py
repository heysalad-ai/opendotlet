from common import *


def tile(colour, name, role, state_line, speak=False, extra="", big=False):
    size = 168 if big else 112
    return f'''<div class="card" style="padding: 20px; display: flex; flex-direction: column; align-items: center; gap: 12px; text-align: center; {"grid-row: span 2; justify-content: center; border-color: #ff5c39; box-shadow: 4px 4px 0 0 #ff5c39;" if big else ""}">
{av(colour, size, speak=speak, alt=name)}
<p style="margin: 6px 0 0" class="{"disp" if big else ""}"><span style="font-size: {28 if big else 17}px; font-weight: {900 if big else 600}">{name}</span> <span class="muted" style="font-size: 13px; font-weight: 400; font-family: Inter, sans-serif">· {role}</span></p>
<p style="margin: 0; display: flex; align-items: center; gap: 8px; font-size: 14px">{state_line}</p>{extra}</div>'''


stage = "".join([
    tile("coral", "Kofi", "Lead", f'{bars()} <b>Speaking</b> · voice Cedar', speak=True, big=True,
         extra='<p class="muted" style="margin: 4px 0 0; font-size: 13px">Has the mic. Will pass to Mira for prices.</p>'),
    tile("sky", "Mira", "Research", f'{ic("hand", 16, "var(--approve)")}<b style="color: var(--approve)">Hand up</b> · has the price data'),
    tile("sun", "Sol", "Writer", f'{chip("listening")}'),
    tile("lilac", "Pip", "Builder", f'{chip("working", "Working off-mic")}', extra='<p class="muted" style="margin: 0; font-size: 13px">Rendering demo · 72%</p>'),
    '''<div class="card" style="padding: 20px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px">
<span style="width: 112px; height: 112px; border-radius: 50%; background: #fbf7f0; color: #14110f; display: flex; align-items: center; justify-content: center; font-family: Nunito, sans-serif; font-weight: 900; font-size: 40px; border: 2px solid #fbf7f0">PM</span>
<p style="margin: 6px 0 0; font-weight: 600; font-size: 17px">You</p><p style="margin: 0; display: flex; gap: 8px; align-items: center; font-size: 14px" class="muted">''' + ic("mic", 16) + ''' Mic on</p></div>''',
])

captions = f'''<section class="card" style="padding: 16px 20px; display: flex; flex-direction: column; gap: 8px; box-shadow: none">
<p class="lbl" style="margin: 0; display: flex; gap: 8px; align-items: center">{ic("cc", 16)}Live transcript</p>
<p style="margin: 0"><b>You:</b> <span class="muted">Can we hit Friday?</span></p>
<p style="margin: 0"><b>Kofi:</b> Yes, if the parts land Wednesday. Pip's demo is nearly rendered. Mira, can you give us the supplier numbers?</p>
<p style="margin: 0; display: flex; align-items: center; gap: 8px; font-size: 13px" class="muted">{av("coral", 20)}{ic("arrow", 14)}{av("sky", 20)} Passing the mic to Mira…</p></section>'''

controls = f'''<nav aria-label="Call controls" style="display: flex; gap: 12px; justify-content: center; align-items: center; flex-wrap: wrap">
<button class="btn2" style="border-radius: 999px">{ic("mic", 18)}Mute</button>
<button class="btn2" style="border-radius: 999px">{ic("hand", 18)}Interrupt</button>
<button class="btn2" style="border-radius: 999px">{ic("arrow", 18)}Pass to…</button>
<button class="btn2" style="border-radius: 999px">{ic("plus", 18)}Add Dotlet</button>
<button class="btn2" style="border-radius: 999px">{ic("screen", 18)}Share screen</button>
<button class="btn" style="border-radius: 999px; background: #c4281a; color: #fbf7f0; border-color: #fbf7f0">{ic("end", 18)}End huddle</button></nav>'''

side = f'''<aside class="r" style="border-left: 2px solid var(--hair); padding: 24px 20px; display: flex; flex-direction: column; gap: 26px">
<section><p class="lbl" style="margin: 0 0 10px">Agenda · Kofi keeps it</p>
<ol style="margin: 0; padding-left: 20px; display: flex; flex-direction: column; gap: 6px; font-size: 14px">
<li style="text-decoration: line-through" class="muted">Demo status</li><li><b>Parts and price</b> · now</li><li>Launch post</li><li>Who does what by Friday</li></ol></section>
<section><p class="lbl" style="margin: 0 0 10px">Decided</p>
<ul style="margin: 0; padding: 0; list-style: none; display: flex; flex-direction: column; gap: 8px; font-size: 14px">
<li style="display: flex; gap: 8px">{ic("check", 18, "var(--done)")}Launch on Friday 10:00</li><li style="display: flex; gap: 8px">{ic("check", 18, "var(--done)")}Demo shows the gallery only</li></ul></section>
<section><p class="lbl" style="margin: 0 0 10px">Started during this call</p>
<ul style="margin: 0; padding: 0; list-style: none; display: flex; flex-direction: column; gap: 10px; font-size: 14px">
<li style="display: flex; gap: 10px; align-items: center">{av("lilac", 28, "working")}<span style="flex: 1">Cut 30 s demo</span><span class="muted">72%</span></li>
<li style="display: flex; gap: 10px; align-items: center">{av("sky", 28, "thinking")}<span style="flex: 1">Ask 2 suppliers for dates</span><span class="muted">queued</span></li>
<li style="display: flex; gap: 10px; align-items: center">{av("sun", 28, "approval")}<span style="flex: 1">Post draft v2</span><span style="color: var(--approve); font-weight: 600">Needs you</span></li></ul></section>
<section class="card" style="padding: 14px; box-shadow: none; font-size: 13px; line-height: 19px">
<p style="margin: 0 0 6px; font-weight: 600">How a huddle works</p>
<p class="muted" style="margin: 0">One live voice session. One Dotlet speaks at a time and hands the mic on; its voice changes, the call doesn't drop. Everyone else keeps working and raises a hand to speak. Audio stays between you and your OpenAI key.</p></section>
</aside>'''

body = f'''<div class="od dark app" style="min-height: 960px; background: #14110f; display: grid; grid-template-columns: 1fr 360px">
<main style="display: flex; flex-direction: column; gap: 22px; padding: 22px 28px; min-width: 0">
<header style="display: flex; align-items: center; gap: 14px; flex-wrap: wrap">
<img src="{B["lockup_dark"]}" alt="OpenDotlet" style="height: 26px">
<span style="width: 2px; height: 24px; background: var(--hair)"></span>
<h1 class="disp" style="margin: 0; font-size: 24px; line-height: 30px">Huddle · #launch-week</h1>
<span class="chip" style="background: #c4281a; color: #fbf7f0; border-color: #c4281a"><span class="dot" style="background: #fbf7f0"></span>Live 12:41</span>
<span class="concept" style="background: #2a2522; color: #b5ada3">Concept</span>
<span class="muted" style="margin-left: auto; font-size: 13px; display: flex; gap: 6px; align-items: center">{ic("lock", 14)}Realtime voice via your key · transcript saved to the room</span></header>
<section aria-label="Participants" style="display: grid; grid-template-columns: 1.4fr 1fr 1fr; grid-template-rows: auto auto; gap: 18px">{stage}</section>
{captions}
{controls}
</main>
{side}
</div>'''
css = "@media (max-width: 1100px){.app{grid-template-columns: 1fr !important}.r{display: none !important}}@media (max-width: 760px){.app section[aria-label=Participants]{grid-template-columns: 1fr 1fr !important}}"
open("project/WebCall.dc.html", "w").write(page("Web · Huddle", 1440, 960, body, css))
print("ok")
