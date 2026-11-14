# Cookbook proposal: physical buttons for saved Codex tasks

Status: **[Cookbook issue #3291](https://github.com/openai/openai-cookbook/issues/3291), originally opened 6 November 2026, updated to the demonstrated keypad/Codex scope on 14 November 2026. Awaiting maintainer scope review; no recipe has been accepted or merged.**

## Updated scope — 14 November 2026

This updates our 6 November proposal after splitting the project into **Open.Dotlet**, the keypad and saved-task companion, and **OpenPromptlet**, the separate round-screen/four-encoder controller. We propose a narrower **Codex** recipe grounded in the keypad workflow we have demonstrated. The earlier Live voice / Decisions / Images round-screen proposal is deferred.

## Is your feature request related to a problem? Please describe.

Developers can invoke Codex programmatically, but connecting a physical control introduces additional problems: held and repeated key events, stale events after reconnect, accidental duplicate tasks, authentication boundaries, busy/cancel behavior, and making the actual answer visible to the user.

We would like to contribute a practical recipe teaching how to connect a physical button to one saved, read-only Codex task on a trusted computer, with explicit event handling and a visible result. Open.Dotlet is the reference implementation, rather than the subject of a product-promotion article.

## What exists today

- An actual 6-column × 5-row keypad prototype. All 30 physical press/release positions were tested on 13 November.
- The white-logo key triggered a real saved read-only project-summary task, with progress and a completed result observed in the Mac development app.
- [Public Mac and Windows alpha.2 downloads](https://github.com/heysalad-ai/opendotlet/releases/tag/v0.6.0-alpha.2), including an on-screen way to try a saved task without hardware.
- [Companion source pinned to alpha.2](https://github.com/heysalad-ai/opendotlet/tree/v0.6.0-alpha.2/companion), commit `fd9b991db39ecb7ffd3d36455aafeb27954010e9`. This source contains the task host, USB reader and local interface.
- [Release evidence and remaining acceptance work](https://github.com/heysalad-ai/opendotlet/blob/main/docs/RELEASE-STATUS.md): 15 host tests and 32 Swift tests are recorded for the release, with Mac signing/notarization and Windows package/startup checks. These are existing release results, not newly run tests for a finished Cookbook recipe.

Fresh full physical USB → Codex → result acceptance on each portable release, clean-user onboarding and the public keypad firmware/build guide still need work. The default branch retains the earlier round-gallery firmware; the keypad companion source is under the release tag above. Neither compilation nor package startup is being presented as hardware acceptance.

## Describe the solution you'd like

Suggested recipe: **“Run a saved Codex task from a physical button.”**

The reader would learn to:

1. Configure one explicit project directory and a saved prompt: “Summarise the current project and suggest three next steps; do not change files or run external actions.”
2. Accept a physical key's press/release event through a small host adapter. Use an observed released state after connection, event sequencing and held-key suppression to avoid replaying stale or duplicate input.
3. Start one bounded Codex task in a read-only sandbox, using argument arrays rather than shell-interpolated commands. Reject presses while busy; do not silently queue or retry tasks.
4. Parse Codex's JSON event stream, expose progress/error/cancellation state and show the real completed answer.
5. Keep Codex sign-in and any service credentials on the trusted host. Explain the limits of sandboxing, workspace trust and local interface exposure; the hardware contains no OpenAI API key.
6. Exercise the same host path with a documented hardware-free input fixture before attaching the keypad.

The alpha already contains the host/reader/UI pieces. Extracting and validating a minimal standalone teaching example, including the hardware-free fixture, is **proposed work**, not a claim that the finished recipe exists.

The initial scope is one saved read-only task at a time. General writable workflows, concurrent agents, direct API-key keypad execution, packaged Chrome distribution and OpenPromptlet task integration are outside this recipe. The 1/2/4/8-key family images are design concepts and are not submitted as working hardware evidence.

## Relationship to existing examples

We reviewed the [Codex examples](https://github.com/openai/openai-cookbook/tree/main/examples/codex) and the [code-review guide](https://github.com/openai/openai-cookbook/blob/main/examples/codex/build_code_review_with_codex_sdk.md). We are not claiming that headless Codex invocation or JSON output is new. The proposed teaching value is the external physical-input lifecycle: reconnect/held-key boundaries, one-task dispatch, cancellation and showing the actual response in a local companion. We welcome maintainer guidance on whether this is sufficiently distinct and whether a CLI-based recipe or SDK-based adaptation is preferred.

## Validation before a recipe PR

- Extract a small readable host example and hardware-free fixture; document dependencies, the exact supported Codex version, sign-in, account access and normal usage/billing implications.
- Run deterministic tests for press/release, duplicate and stale events, reconnect, busy rejection, cancellation, missing CLI/authentication and invalid workspaces.
- Run the documented live path with explicit opt-in; record the environment and observed results separately from mocked fixture results.
- Publish the exact supported keypad wiring/firmware and repeat the physical path on the supported release setup, with a continuous hardware recording.
- Review credential handling, inherited process environment, sandbox limits and local access with the appropriate maintainer.
- Keep example art original or appropriately licensed. The code's MIT licence does not license third-party sticker artwork.

If scope is approved, the Cookbook would contain the focused runnable host example/guide and tests; firmware, CAD and application distribution would stay in the external project. We would follow the registry, author/profile, validation and Developer Experience review steps in [CONTRIBUTING](https://github.com/openai/openai-cookbook/blob/main/CONTRIBUTING.md).

## References and request for scope review

- [Current public repository and product overview](https://github.com/heysalad-ai/opendotlet)
- [Pinned companion source](https://github.com/heysalad-ai/opendotlet/tree/v0.6.0-alpha.2/companion)
- [Actual development-app task result](https://github.com/heysalad-ai/opendotlet/blob/main/docs/media/prototype-result.png)
- [30-second product film](https://youtu.be/ZTwkPtybRa0): animated actual product photo and app screenshots with AI narration, **not** a continuous hardware recording.
- [Project site](https://opendotlet.com/)

Owner: Peter Machona / HeySalad, GitHub @chilu18. This is an independent community project inspired by developer events and the swag received there; it has not been endorsed or approved by OpenAI. This proposal is not a claim of Cookbook acceptance.

Could a maintainer review this revised Codex-focused scope and share it in the proposal-review channel described in CONTRIBUTING? We have not received scope feedback on the earlier proposal and will wait for that guidance before opening a new-recipe PR.
