# OpenDotlet

**Your own AI agent. A little face on your desk.**

OpenDotlet is HeySalad's independent, open-source personal AI companion. Each one runs on its owner's own OpenAI API key and lives in a small round-screen device called a **Dotlet** (plural **Dotlets**). The identity is called **Peel**: a sticker that peeled itself off the sheet and came alive.

> **Product truth.** The working product today is the offline touch gallery on the Waveshare ESP32-S3-Touch-LCD-1.46 (412×412 round screen). Voice, Decisions, image generation, persistent agents and device management are **planned**. Describe them as planned, label every device face as a mockup, and never imply that OpenAI made or endorses OpenDotlet.

## Brand idea

- **The sticker is the character.** A round sticker with a thick ink edge and two pill eyes. Its corner is always lifting: it's ready to move.
- **The peel is the voice.** On the device, the back of the peel shows what the Dotlet is doing: listening, thinking, working, waiting for you, done. Personality lives on the front; status lives on the back.
- **Owners choose the colour.** Coral is the brand. Mint, Sky, Lilac, Sun, Ink and Paper are characters people pick for their own Dotlet.

## Principles

1. **Playful, never silly.** The face is cute, but the product is a capable tool. Keep the type bold and plain and the layouts calm.
2. **Edges, not glow.** Use ink outlines and hard offset shadows ({shadow-sticker}). No gradients, glows or glass.
3. **Shape before colour.** Every state changes the eyes *and* the peel glyph. Colour is the third cue, never the only one.
4. **Honest by default.** Say what works today. Mark keys as masked. Never ask for an API key on the device itself.

## Voice

Warm, short and specific. The Dotlet speaks in first person on the device and in notifications; product docs use plain second person.

| Do | Don't |
|---|---|
| "Got it. Working on that now." | "Processing your request…" |
| "I need a yes from you before I send this." | "Action requires authorisation." |
| "I'm offline. Check Wi-Fi, then tap me." | "Error 0x1F: network unreachable." |
| "Voice is coming soon." | "Talk to your Dotlet!" (not shipped) |
| "Inspired by Dots, built in the open." | "The official Dots device." |

Write "OpenDotlet" (one word, capital O and D) for the project, and "Dotlet" for a device. Don't write "Open Dotlet", "Opendotlet" or "DotLet".

## Logo

The logo is the coral sticker with an ink outline, pill eyes and a peeled corner showing its paper back.

- **Never drop the outline or the peel.** Together they are what makes the mark ownable: a coloured circle with eyes is generic.
- **Lockups.** Horizontal: symbol, a gap of 0.18 × symbol height, then the wordmark at cap height 0.40 × symbol height. Stacked: the wordmark is centred under the symbol.
- **Clear space.** At least the peel's height (≈ 25% of the symbol) on every side.
- **Minimum sizes.** Use `opendotlet-favicon` from 16 to 48 px (it has a thicker edge, bigger eyes and no shadow). The full symbol works from 56 px; the horizontal lockup from 120 px wide.
- **On dark grounds,** use `symbol-on-dark` (no drop shadow). The ink edge stays: on Ink it simply merges with the ground, which is fine.
- **One colour.** `symbol-black` and `symbol-white` are for engraving, stamps and single-ink print.
- **Don't** rotate the mark, peel a different corner, add a mouth, recolour the outline, or use a character colour for the logo itself (characters belong to owners; the logo is Coral).
- **The wordmark** is outlined from Nunito Black at −1% tracking. Don't retype it.

## Characters

| Character | Fill | Eyes | Peel back |
|---|---|---|---|
| Coral (default) | {sticker-coral} | ink | paper |
| Mint | {sticker-mint} | ink | paper |
| Sky | {sticker-sky} | ink | paper |
| Lilac | {sticker-lilac} | ink | paper |
| Sun | {sticker-sun} | ink | paper |
| Ink (black family) | {sticker-ink} | paper | #3a3430 |
| Paper (white family) | {sticker-paper} | ink | #e9e3d6 |

Character colours express personality only. They never mean a status.

## Device states (412×412, concepts)

| State | Eyes | Peel | Colour cue |
|---|---|---|---|
| Idle | pill eyes | small corner lift | none |
| Listening | tall pills | sound bars | {state-listening} |
| Thinking | glance up-left | three dots | {state-thinking} |
| Working | squint | spinner | {state-working} |
| Approval needed | look toward the peel | big peel showing **?** | {state-approval} |
| Done | happy U U, **open at the top** | check | {state-done} |
| Offline | closed lines | none: pressed flat, dashed seam | {state-offline} |
| Error | × × | **!** | {state-error} |

The exposed corner under the peel is device black. On the device, show at most one word under the face (`device-label`).

## Colour

- **Light (Paper)** is the default for web and docs. **Dark (Ink)** matches the device and the approved all-black presentation.
- Text: {ink} on {surface-100}/{surface-200}; secondary text {ink-muted}; links {coral-text}.
- On coral or any sticker fill, text and icons are {ink-fixed}. Never white on coral.
- Controls and cards carry a {border-sticker} {outline}. Use {hairline} only for dividers.

## Type

- **Nunito** (800/900) for display: rounded terminals that echo the sticker. Use the `display-xl`, `display-l`, `title` and `device-label` styles.
- **Inter** (400/600) for interface and body text.
- **JetBrains Mono** (400) for commands, serial output and masked keys.
- All three are SIL Open Font License 1.1. Upstream sources: github.com/googlefonts/nunito, github.com/rsms/inter, github.com/JetBrains/JetBrainsMono. Licence texts are in `licenses/`.

## Shape, space and motion

- Corners come from the die-cut: {radius-lg} on cards, {radius-md} on buttons, {radius-pill} on chips.
- Spacing uses a 4 px base: {space-4} inside compact cards, {space-6} in standard ones, {space-8} between sections.
- Interaction: on hover the sticker lifts ({shadow-lift}); on press it drops flat (shadow none, translate 3 px). Motion lasts 120–180 ms with an ease-out. On the device, the peel lifts open over 200 ms when a state starts and settles back when it ends.

## Iconography

Rounded 2 px strokes with round caps, drawn on a 24 px grid, in {ink}. Status glyphs reuse the peel glyphs (bars, dots, spinner, ?, check, !) so the app and the device share one vocabulary. Don't use emoji as UI icons.

## Accessibility

- Text reaches at least 4.5:1 in both themes (checked values are in each token's usage note). The only colour pair that would fail, coral text on Paper, is not allowed.
- Never show a state by colour alone; chips always carry a glyph and a word.
- Focus: a 3 px {focus} ring outside the outline.

## Files

- `assets/Logos`: symbol (colour, on-dark, black, white), favicon, avatar, app tiles, lockups, wordmark.
- `assets/Characters`: the seven character stickers.
- `assets/Device states`: the eight 412×412 state faces (mockups).
- `components/`: Button, StatusChip, Sticker, DeviceFace, Card, Toast and SerialLog. Static HTML/CSS lives in `components/bundle.css` with `od-` class names.

## Provenance

All marks, characters and faces are original artwork made for HeySalad in November 2026. The OpenAI event stickers were used only as mood reference: no OpenAI logo, knot, sticker artwork or "[build]" lettering is used. No trademark clearance search has been done yet. OpenDotlet is not affiliated with, sponsored by or endorsed by OpenAI.
