from common import *

steps = ["Identity", "Role & handoffs", "Voice", "Tools", "Permissions", "Routines"]
nav = "".join(f'<li style="display: flex; gap: 10px; align-items: center; padding: 10px 12px; border-radius: 12px; {"background: var(--surface); border: 2px solid var(--ink); font-weight: 600;" if i == 2 else ""}"><span style="width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; {"background: var(--ink); color: var(--paper);" if i < 2 else "border: 2px solid var(--ink);"}">{"✓" if i < 2 else i + 1}</span>{s}</li>' for i, s in enumerate(steps))

chars = "".join(f'<label style="display: flex; flex-direction: column; align-items: center; gap: 6px; font-size: 13px; cursor: pointer"><input type="radio" name="char" {"checked" if c == "sky" else ""} style="position: absolute; opacity: 0"><span style="padding: 4px; border-radius: 50%; {"outline: 3px solid var(--ink); outline-offset: 2px;" if c == "sky" else ""}">{av(c, 52, alt=c)}</span>{c.capitalize()}</label>' for c in ["coral", "mint", "sky", "lilac", "sun", "ink", "paper"])

voices = "".join(f'''<label class="card" style="display: flex; gap: 12px; align-items: center; padding: 12px 14px; box-shadow: none; {"border-width: 3px; background: var(--backing);" if v == "Marin" else ""}">
<input type="radio" name="voice" {"checked" if v == "Marin" else ""} aria-label="{v}"><span style="flex: 1"><b style="display: block">{v}</b><span class="muted" style="font-size: 13px">{d}</span></span>
<button type="button" class="ibtn" style="width: 36px; height: 36px" aria-label="Preview {v}">{ic("play", 16)}</button></label>''' for v, d in [("Marin", "Calm, clear"), ("Cedar", "Warm, low"), ("Alloy", "Neutral"), ("Coral", "Bright, quick")])

tools = "".join(f'''<li style="display: flex; gap: 12px; align-items: center; padding: 10px 0; border-bottom: 1px solid var(--hair)"><span style="flex: 1"><b>{n}</b> <span class="muted" style="font-size: 13px">· {d}</span></span>{'<span class="chip">' + GLYPH["done"].replace("<svg ", '<svg width="14" height="14" ') + 'Connected</span>' if on else '<button type="button" class="btn2 btn-s">Connect</button>'}</li>''' for n, d, on in [("Web browser", "on the Dotlet's computer", True), ("Google Drive", "read only", True), ("Gmail", "drafts; sending needs approval", False), ("GitHub", "issues and PRs", False)])

perms = "".join(f'<li style="display: flex; gap: 10px; align-items: center; padding: 6px 0"><input type="checkbox" id="p{i}" checked><label for="p{i}">{t}</label></li>' for i, t in enumerate(["Send email or messages to anyone", "Post anything public", "Spend money or sign up for things", "Delete or overwrite files"]))

preview = f'''<aside class="card r" style="padding: 24px; display: flex; flex-direction: column; align-items: center; gap: 14px; text-align: center; align-self: start; position: sticky; top: 24px">
<p class="lbl" style="margin: 0">Preview</p>
{av("sky", 132, alt="Mira, sky Dotlet")}
<p class="disp" style="margin: 4px 0 0; font-size: 32px; line-height: 36px">Mira</p>
<p class="muted" style="margin: 0">Research · voice Marin</p>
<p style="margin: 6px 0 0; padding: 12px 14px; border-radius: 14px; background: var(--backing); font-size: 14px; text-align: left">"Hi, I'm Mira. Send me a question and I'll come back with sources. I'll ask before I email anyone."</p>
<div style="display: flex; gap: 10px; flex-wrap: wrap; justify-content: center"><button type="button" class="btn">{ic("phone", 18)}Test call</button><button type="button" class="btn2">{ic("msg", 18)}Test chat</button></div>
<p class="muted" style="margin: 0; font-size: 12px; line-height: 16px">Runs on your OpenAI API key. Voice uses the Realtime API; usage is billed to your key.</p>
</aside>'''

body = f'''<div class="od app" style="min-height: 960px; background: var(--paper); display: grid; grid-template-columns: 260px 1fr 380px; gap: 0">
<nav class="l" style="border-right: 2px solid var(--hair); padding: 24px 16px; display: flex; flex-direction: column; gap: 20px">
<img src="{B["lockup"]}" alt="OpenDotlet" style="height: 28px; align-self: flex-start">
<div><p class="lbl" style="margin: 0 0 4px">New Dotlet</p><p class="disp" style="margin: 0; font-size: 26px; line-height: 30px">Set up Mira</p></div>
<ol style="list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 4px">{nav}</ol>
<span class="concept" style="align-self: flex-start; margin-top: auto">Concept</span></nav>
<main style="padding: 32px 40px; display: flex; flex-direction: column; gap: 32px; max-width: 760px">
<section><h2 class="h2" style="margin-bottom: 14px">Identity</h2>
<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 16px">
<label style="display: flex; flex-direction: column; gap: 6px"><span class="lbl">Name</span><input value="Mira" style="font: inherit; padding: 10px 12px; border: 2px solid var(--ink); border-radius: 10px; background: var(--surface)"></label>
<label style="display: flex; flex-direction: column; gap: 6px"><span class="lbl">Title</span><input value="Research" style="font: inherit; padding: 10px 12px; border: 2px solid var(--ink); border-radius: 10px; background: var(--surface)"></label></div>
<fieldset style="border: 0; padding: 0; margin: 0"><legend class="lbl" style="margin-bottom: 10px">Character</legend><div style="display: flex; gap: 14px; flex-wrap: wrap">{chars}</div></fieldset></section>
<section><h2 class="h2" style="margin-bottom: 6px">Role &amp; handoffs</h2>
<p class="muted" style="margin: 0 0 10px; font-size: 14px">Kofi (Lead) reads this to decide what to hand Mira. Be specific.</p>
<textarea rows="3" aria-label="Role description" style="width: 100%; font: inherit; padding: 12px; border: 2px solid var(--ink); border-radius: 12px; background: var(--surface); resize: vertical">Finds facts, prices and sources. Returns a short summary with links. Doesn't write marketing copy (that's Sol).</textarea></section>
<section><h2 class="h2" style="margin-bottom: 14px">Voice for huddles</h2>
<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px">{voices}</div></section>
<section><h2 class="h2" style="margin-bottom: 6px">Tools</h2><ul style="list-style: none; margin: 0; padding: 0">{tools}</ul></section>
<section><h2 class="h2" style="margin-bottom: 6px">Ask me before</h2><ul style="list-style: none; margin: 0; padding: 0">{perms}</ul>
<label style="display: flex; gap: 10px; align-items: center; margin-top: 10px"><span class="lbl">Can call me</span><select style="font: inherit; padding: 8px 10px; border: 2px solid var(--ink); border-radius: 10px; background: var(--surface)"><option>Only for approvals</option><option>Urgent only</option><option>Never</option></select></label></section>
<div style="display: flex; gap: 12px; padding-top: 8px; border-top: 2px solid var(--hair)"><button type="button" class="btn2">Back</button><button type="button" class="btn" style="margin-left: auto">Save &amp; continue</button></div>
</main>
<div style="padding: 32px 28px 32px 0">{preview}</div>
</div>'''
css = "@media (max-width: 1100px){.app{grid-template-columns: 220px 1fr !important}.app > div:last-child{display: none}}@media (max-width: 760px){.app{grid-template-columns: 1fr !important}.l{display: none !important}}"
open("project/WebBuilder.dc.html", "w").write(page("Web · Set up a Dotlet", 1440, 960, body, css))
print("ok")
