# Open.Dotlet development timeline

Updated **13 November 2026**. [Project overview](../README.md) · [Forward roadmap](ROADMAP.md) · [Release status](RELEASE-STATUS.md)

This history separates design decisions, local prototypes, physical observations and public releases. A dated prototype result does not automatically describe the downloadable alpha. Historical dates come from reviewed project notes and public Git history; future windows are proposals unless a platform-confirmed launch date is stated.

## The journey so far

| Date | Milestone | What changed and why | Evidence/status |
| --- | --- | --- | --- |
| **19 August 2026** | Early OpenPromptlet control-deck brief | Explored a screen-free USB controller with RGB buttons, mechanical command keys and a push encoder. The purpose was to make AI tools and repeatable actions physical. | Historical design brief; an earlier hardware concept, not the current 30-key specification. |
| **6 November** | Round-display gallery published | OpenDotlet initially described the Waveshare ESP32-S3 round-screen gallery. Pinned dependencies, deterministic artwork export, firmware checks and setup documentation made the experiment reproducible. | [Initial public source](https://github.com/heysalad-ai/opendotlet/commit/e916571) and [clean-checkout build record](https://github.com/heysalad-ai/opendotlet/commit/564dd28). |
| **6 November** | Artwork orientation corrected | Individual blue/cyan smile views gained upright U-shaped eyes in both themes. Asset checks protected orientation and unchanged frames. | [Public correction](https://github.com/heysalad-ai/opendotlet/commit/3f12a0e); this verifies gallery artwork, not a keypad or voice session. |
| **6 November** | Early local voice-button experiment | A USB microphone/local-transcription experiment was exercised with a spoken phrase. This contributed reusable companion work. | Historical local prototype evidence; speech capture is not included in the public saved-task alpha. |
| **7 November** | Task keys and agent feedback explored | Codex Micro research informed the idea of a distinct task/agent function per key and lighting that communicates state. Existing companion/agent work was investigated for reuse. | Research and development direction; 30 independent concurrent agents were not established. |
| **9 November** | Provisional console parts list | The public repository added a console BOM to make hardware exploration more concrete. | [Parts-list commit](https://github.com/heysalad-ai/opendotlet/commit/300ba21). Provisional exploration, not an accepted current keypad build package. |
| **10 November** | Four-knob controller exercised | The separate control brick's four encoders and push buttons were physically accepted on its prototype. | Reported in the public [OpenPromptlet build repository](https://github.com/heysalad-ai/openpromptlet#what-works-today). Separate from keypad acceptance. |
| **12 November** | Modular direction proposed | The combined device became two independently useful modules that could eventually attach. Round-display orientation and all four knobs were reconfirmed on the controller prototype. | Design discussion plus the [controller's published status](https://github.com/heysalad-ai/openpromptlet#what-works-today). Mechanical attachment remained open. |
| **13 November** | Product names and boundaries clarified | **Open.Dotlet** became the 30-key keypad/prompting tablet. **OpenPromptlet** became the four-knob round-screen controller. Each coloured face became a “dotlet”: an assignable entry point to a saved task. | Current product decision. Shared task state and physical/electrical attachment were not declared finished. |
| **13 November** | All 30 key positions tested | The C6 keypad diagnostic registered press/release positions and illuminated keys while held. | Physical prototype test with user confirmation; this did not by itself prove prompt execution. |
| **13 November** | First physical saved-prompt run | The white-logo key sent a fresh event through the Windows serial client to the Mac saved-task service. A real read-only project-summary response returned and was shown in the app. | Development setup demonstrated end to end. One starter binding was assigned; repeated/held events were constrained. |
| **13 November** | Agent team workspace | The illustrated 6×5 map, selected task, progress and history were brought together. A later physical run completed and the view followed its running/completed states. | Native development interface observed; “team” describes task bindings here, not automatic agent delegation. |
| **13 November** | Public identity and landing page | Neutral black/white styling and green accents replaced the coral-led direction. The product image, source links, setup requirements and module relationship were simplified at opendotlet.com. | Public landing page deployed; actual photo with AI background removal. |
| **13 November** | First portable Windows alpha | A standalone Windows launcher, bundled Python and local browser interface were built and published as alpha.1. Source was retained under its release tag. | [Historical alpha.1 release](https://github.com/heysalad-ai/opendotlet/releases/tag/v0.6.0-alpha.1); that original Windows artifact was unsigned. |
| **13 November** | Mac notarization and alpha.2 | The Mac helper was packaged as a standard nested app, signed and submitted to Apple. Notarization was accepted; ticket stapling, Gatekeeper and distribution checks passed. | [Public alpha.2](https://github.com/heysalad-ai/opendotlet/releases/tag/v0.6.0-alpha.2), Apple Silicon/macOS 14+; [validation summary](RELEASE-STATUS.md). |
| **13 November** | Windows publisher signing | The existing HeySalad Azure signing account signed the tested launcher as **HeySalad Inc.** Windows trust, timestamp and fresh-state runtime checks passed. Signed downloads and checksums went live. | Signed alpha.2 asset; 1,004 dependency/UI files matched the CI payload. Remaining USB/provider test is explicit. |
| **13 November** | Launch materials and scheduling | Product image, app gallery, maker story, setup/source links and platform availability were saved on the existing Product Hunt product. | Product Hunt confirmed **Scheduled** for **14 November, 08:01 GMT / 00:01 PT**. Scheduled is distinct from a live launch. |

## What happened inside the 13 November milestone

The order matters because it keeps a working device from being mistaken for a fully released product:

1. **Validate inputs.** Test every row/column position and distinguish a key's electrical position from its photographed orientation. The white-logo starter key is matrix row 5, column 6 on this build.
2. **Prove one useful action.** Bind a small project-summary prompt with read-only access. Show a real result before expanding the action system.
3. **Make that action understandable.** Match the app's faces to the physical pad and keep the selected task, progress, errors and result together.
4. **Keep the interaction deliberate.** A fresh press starts a task; a held key or repeated event should not repeatedly submit work. Only one task runs at a time in the alpha.
5. **Remove development-machine dependencies.** Package the local runtime/Python and verify that a user does not need the original checkout. Keep Codex CLI/account setup explicit.
6. **Establish distribution trust.** Separate a successful build from Apple acceptance, Windows publisher signing and public download checksums.
7. **Invite testing with accurate claims.** Release the saved-task alpha and show what remains experimental. Preserve the earlier gallery and separate controller work without presenting every experiment as part of the download.

## The product decisions behind the timeline

### A modular product

A keypad and an encoder/display controller have different jobs and build constraints. The split makes it possible to test each on its own. A connection between them is a future milestone with mechanical, electrical, firmware and task-state acceptance criteria; it is not just a naming change.

### A dotlet starts as a task binding

The first reliable building block is a saved prompt plus a chosen project. A workflow, function or specialized agent can later use that same physical entry point, but needs a clear execution contract, permissions, cancellation and feedback. The current release keeps the saved read-only path as its baseline.

### Software before a hardware purchase

The on-screen Run task path lets people test the idea before sourcing a keypad. This is why signed downloads, clear Codex setup and good error messages are ahead of additional hardware features in the roadmap.

## Proposed next timeline

| Window | Focus | Observable outcome before moving on |
| --- | --- | --- |
| **14–20 November** | Launch feedback, setup and reliability | Fresh Mac/Windows setup reports, reproducible issues, complete physical tests and documented reconnect behavior. |
| **21–27 November** | Key assignments and feedback | Reliable editing/learning of mappings, accessible status/result handling and configuration recovery. |
| **28 November–11 December** | CLI, local extension contract and bounded workflows | Versioned invocation API, portable read-only examples, cancellation/error behavior and duplicate-execution tests. |
| **12–25 December** | Chrome extension and API-key mode, as separate acceptance tracks | Browser-to-local authorization checks; keys retained by the trusted host; explicit execution and usage boundaries. |
| **26 December–8 January 2027** | OpenPromptlet task feedback and modular hardware | Agreed protocol, real status shown on the controller, both modules still useful separately, repeatable fit/wiring evidence. |
| **9–22 January** | Beta readiness | Supported configurations, fresh-user acceptance, complete licence/build documentation and no unresolved critical execution/recovery failures. |

These are indicative planning windows, not fixed release commitments or work already completed. The detailed [roadmap](ROADMAP.md) lists dependencies, deliverables and exit checks. A failed safety, recovery or physical test moves the next milestone rather than being hidden by a date.

## How this page will be maintained

Completed entries should link to a release, source change, test record or clearly described physical observation. Record the configuration and limitation beside the result. Future work moves to completed only when its acceptance criteria pass; a mockup, CI build or serial acknowledgement alone is insufficient proof of a physical result.

The older [round-display roadmap](legacy/ROUND-DISPLAY-ROADMAP.md) remains available as historical context. Its voice/image experiments are not silently promoted into current keypad features.
