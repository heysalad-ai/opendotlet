# Cookbook proposal: OpenDotlet

Status: **proposal prepared for maintainer scope review; no recipe has been accepted or merged**.

## Is your feature request related to a problem? Please describe.

Developers building physical AI companions need a reproducible example connecting OpenAI APIs to a constrained display device, including the bridge, asset handling and evidence of what actually reached the hardware.

[OpenDotlet](https://github.com/heysalad-ai/opendotlet) currently runs an offline, touch-controlled gallery on a Waveshare round ESP32-S3 display. Its gallery has pinned dependencies, automated asset tests and firmware CI. Live voice, Decisions and generated artwork are **planned**, not implemented. We are seeking scope review before preparing a recipe PR, following the Cookbook contribution process.

## Describe the solution you'd like

A focused tutorial for one documented board and a small trusted-host companion: a spoken request enters Live voice; a bounded Decisions action selects a device reaction or requests image generation/editing; generated artwork is previewed, converted into validated device assets and staged with a hash; the device acknowledges activation. Ordinary reactions use cached faces. The minimum implementation and API selection would be agreed with maintainers before the recipe is written.

Keep the dedicated OpenAI project key on the trusted host and authenticate devices separately. An API key does not grant access to ChatGPT's Dots assets or personalities. Example artwork must be original or appropriately licensed.

We would distinguish the tutorial from [ElatoAI's earlier contribution](https://github.com/openai/openai-cookbook/pull/1808), the [Decisions voice guide](https://developers.openai.com/api/docs/guides/decisions-voice), and the [physical LED display example](https://developers.openai.com/blog/bringing-my-led-display-to-life). The proposed added value is reproducible round-screen ESP32 integration, constrained asset staging/activation, hardware acknowledgement, reconnect behavior and measured device performance. Voice-driven expressions alone are not claimed as novel.

Before a recipe PR, we would provide:

- A runnable bridge and documented board setup, with pinned versions and offline fixtures.
- Explicitly opted-in live tests and measured latency/cost, with the microphone/speaker path identified.
- A device demonstration showing audible playback and correct display activation, plus failure/reconnect tests.
- Authentication-boundary checks, asset licensing, known limits and a reproducible tagged revision.

## Additional context

Owner: HeySalad / Peter Machona (@chilu18). The [maintenance lifecycle](MAINTENANCE.md) specifies Thursday dependency and build checks, API/deprecation review, physical verification gates and synchronization of an accepted Cookbook recipe with tested revisions. Automated builds do not prove hardware or API behavior.

Could a maintainer confirm whether this is a suitable scope and share the proposal in the review channel described in CONTRIBUTING? We would also welcome guidance on keeping firmware in the external repository while the Cookbook contains the runnable host example and explanation. We will wait for scope feedback before submitting a recipe PR.
