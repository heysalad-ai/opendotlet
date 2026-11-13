# Open.Dotlet roadmap

Updated **13 November 2026**. [Overview](../README.md) · [Development history](TIMELINE.md) · [Current release evidence](RELEASE-STATUS.md)

**Direction:** assign a prompt, function or workflow to a dotlet; press once; understand what happened. Start with the proven saved read-only Codex task, improve reliability and usability, then expand the execution options and modular hardware.

This is a proposed delivery sequence for an open-source project. Time windows are indicative, depend on verification and contributor capacity, and are not shipping guarantees. Feedback can change the order. No future item below is advertised as already supported.

## Baseline: available now

- Public **0.6.0-alpha.2**: native Apple Silicon Mac app and Windows local browser companion, with bundled Python/runtime.
- Developer ID/Apple-notarized Mac distribution; Azure-signed Windows launcher and verified public checksums.
- Thirty illustrated key positions, a starter Project summary binding, editable saved tasks, progress/results/history and cancel/pause controls.
- One saved read-only Codex task at a time, using the user's existing Codex CLI sign-in.
- Earlier prototype acceptance of all 30 key positions and a real physical-key-to-Codex result.

The portable Windows release still needs complete physical USB/provider acceptance. The separate OpenPromptlet controller has its own source/build status. General workflows, direct API-key execution, supported Chrome/plugin distribution and inter-module task integration are not in this baseline.

## R1 — Make the alpha easy to try and recover

**Target window:** 14–20 November 2026. **Priority:** first. **Depends on:** published alpha.2 and usable feedback reports.

Deliver:

- A short Mac/Windows first-run guide from download to the first completed task, including where Codex CLI/sign-in is required.
- Specific recovery for missing CLI, signed-out/limited accounts, invalid project folders, unavailable USB ports and a stopped local runtime.
- Complete physical acceptance on the portable releases: one deliberate key press, visible progress, completed result and a clean release of the key.
- USB disconnect/reconnect handling, startup with a key held, repeated presses, service restart and cancellation checks.
- A public issue template with OS/app/firmware versions and sanitized reproduction steps. No API keys, private prompts or project files requested.

**Exit checks:** obtain at least three independent first-run reports per supported OS; exercise all 30 press/release positions on a documented keypad; prove the starter task physically on each supported release path; verify no duplicate run after reconnect/restart; publish the supported configuration and unresolved failures. These counts are acceptance targets, not existing tester results.

## R2 — Make every dotlet understandable

**Target window:** 21–27 November. **Depends on:** R1 input/event behavior being stable.

Deliver:

- Clear create/edit/clear assignment flow, project selection, prompt preview and obvious labels for available versus assigned keys.
- A key-learning/calibration flow so rotated or differently wired pads do not require guessing electrical positions.
- Unambiguous idle, queued/working where applicable, completed, cancelled, failed and disconnected states. Alpha remains single-run until an explicit concurrency design is accepted.
- Keyboard navigation, screen-reader labels, contrast and compact-window checks; status must be understandable without colour alone.
- Versioned configuration export/import with preview, validation and recovery. Exclude provider credentials and history/private project contents by default.

**Exit checks:** assign, edit and clear bindings across the full grid; persist the configuration after restart; reject corrupt/unsupported imports without overwriting the last good file; verify both keypad orientations; complete the editing/run/cancel path with keyboard navigation and a screen reader.

## R3 — A dependable CLI and local extension contract

**Target window:** 28 November–4 December. **Depends on:** R1 recovery and R2 stable binding/configuration identities.

Deliver:

- Supported CLI commands to list bindings, run an existing binding, inspect status/result and cancel a run, with documented exit codes and structured output.
- A small versioned local API/extension contract used by the app and adapters, rather than separate execution engines per interface.
- Safe discovery of the owned local service, scoped capability-based authentication, request validation and an explicit supported-version response.
- Example developer integrations and a compatibility table. Existing experimental CLI/MCP/Chrome adapters are reference work until installed/tested through this contract.

**Exit checks:** the same saved task behaves consistently from UI, CLI and one external adapter; anonymous/invalid/stale capability requests fail; malformed requests cannot change arbitrary files or escape the supported task contract; duplicate invocation and reconnect do not silently submit twice.

## R4 — Bounded reusable functions and workflows

**Target window:** 5–11 December. **Depends on:** R3 invocation contract; design review of execution and permission boundaries.

Deliver:

- A portable workflow definition with named inputs, project scope, steps, allowed actions, version and a readable pre-run summary.
- Begin with read-only examples: project briefing, repository review and a recurring checklist run on demand.
- Explicit run/stop behavior, per-step results, timeouts and failure recovery. Prevent automatic replay of partially completed work.
- Separate future write-capable or external-action workflows from the default read-only path. Show the intended action and obtain the appropriate user approval at execution time.
- An extension interface for task functions; no arbitrary downloaded code should become executable merely because a key is assigned to it.

**Exit checks:** validate a workflow before saving; reject unknown actions and invalid inputs; prove cancel/timeout/failure paths; test restart midway through a run; require a fresh deliberate action before retrying a step with side effects. A completed screenshot or a model saying “done” is not the completion signal for an external action.

## R5 — Chrome extension and API-key execution

**Target window:** 12–25 December. **Depends on:** R3 local contract; R4 execution/permission model for anything beyond saved read-only tasks. These are two separate deliverables and can ship independently.

### Browser extension

- An installable development build followed by a reviewed distribution route, with matching native/local-host setup instructions.
- Choose an existing dotlet, preview the selected task/context, run deliberately, view progress and return to the companion result.
- Make any use of page content explicit; do not automatically collect browsing history or send pages in the background.
- Restrict browser-to-host origins/messages, validate inputs and offer disconnection/revocation. Connection alone must not run a task.

**Exit checks:** fresh Chrome/profile install, paired-host and missing-host behavior, invalid origin/message rejection, a genuine browser-to-companion run, cancellation and removal/revocation tests. Publish actual requested browser permissions before release.

### Bring-your-own API key

- A separate API-key execution mode with clear account/billing ownership, model selection and usage limits.
- Keep credentials in the trusted companion's OS credential store; do not embed them in firmware, export packs, URLs or browser storage.
- Show what prompt/context will be sent, where it will go and how execution is bounded. Keep the current Codex sign-in mode usable separately.
- Publish implementation against the current official provider interfaces at the time the feature is built; do not assume a subscription includes API billing.

**Exit checks:** add/use/remove a key on each supported OS; missing/invalid/revoked key recovery; a real bounded provider response; configured limits and cancellation behavior; a check that logs, exports, crash reports and browser messages contain no credential material.

## R6 — OpenPromptlet feedback and the modular device

**Target window:** 26 December–8 January 2027. **Depends on:** stable task identifiers/state transitions from R3; the controller's independent hardware acceptance. Mechanical and software work can progress separately.

Deliver:

- A documented task-state protocol between companion, keypad and the separate four-knob/round-screen controller.
- A first useful mapping: select a saved task with a knob, deliberately confirm it, then see actual running/completed/error feedback on the screen.
- Firmware compatibility/ownership rules: unsupported versions fail clearly; reconnect never replays a prompt; one host owns a physical session at a time.
- A reproducible modular attachment design, connector orientation, power budget, grounding and wiring plan. Retain independent USB operation of both modules.
- Clearly versioned parts/STL/firmware packages, photos and measured fit checks. Keep the earlier provisional console BOM distinct from an accepted keypad BOM.

**Exit checks:** both modules work independently before and after attachment; all controls still register; real task-state events are shown on hardware; wrong/disconnected module and interrupted connection tests pass; printed parts physically fit and power behavior is measured. A CAD render or serial ACK alone does not satisfy these checks.

## R7 — A supportable beta

**Target window:** 9–22 January 2027, conditional on prior gates. **Depends on:** accepted supported configurations and no unresolved critical execution/recovery issues.

Deliver:

- A reproducible build/release checklist, signed artifact provenance, update/rollback instructions and a supported OS/board/firmware matrix.
- Complete setup/build documentation, contribution guidance and artwork/runtime licence inventory.
- A small curated set of reviewed task/workflow examples, with clear permissions and expected results.
- Fresh-user tests, accessible onboarding and a visible list of known limitations. Intel Mac builds or other boards require their own acceptance before being listed as supported.
- A release decision based on evidence, not elapsed calendar time or download count.

**Exit checks:** independent clean-machine runs on supported platforms, physical acceptance on each advertised hardware path, successful upgrade/recovery without losing bindings, no credential exposure in exported material, and a concise public release note linking the evidence and remaining limits.

## Work we are deliberately not promising yet

A marketplace, a finished-device shipping service, unrestricted desktop automation, 30 simultaneous agents, phone companions, battery operation, cloud sync and support for every board are outside this initial delivery sequence. They can become separate proposals with an owner, user need, permissions and acceptance evidence.

## How to track and contribute

Use [GitHub issues](https://github.com/heysalad-ai/opendotlet/issues) to propose a small piece of one milestone. Include the milestone, problem, expected behavior, dependencies, verification steps and any hardware needed. Agree a concrete scope before changing protocols or introducing external services.

Statuses should mean **planned → in progress → built → locally verified → physically/provider verified where applicable → released**. Publish what was observed and keep open gates visible. This roadmap proposes work; it does not assign dates or obligations to volunteers.

The previous [round-display roadmap](legacy/ROUND-DISPLAY-ROADMAP.md) is preserved for historical context. Its voice/image tracks remain experiments, not features silently included in the keypad download.
