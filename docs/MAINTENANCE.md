# Maintenance and update lifecycle

OpenDotlet is maintained by HeySalad, with Peter Machona ([@chilu18](https://github.com/chilu18)) as the current owner. A backup maintainer has not yet been appointed. This is a prototype: the running feature is the offline gallery; Live voice, Decisions and Images remain roadmap work.

## Thursday cadence

All review times use **Europe/London**, including daylight saving time.

| Time | Activity | Result |
| --- | --- | --- |
| Thursday 07:00 | Dependabot checks Python packages and GitHub Actions | Reviewable dependency PRs, at most three open per ecosystem |
| Thursday 08:17 | Scheduled firmware CI builds the default branch | Asset tests, asset validation and an ESP32-S3 build, even without a code push |
| Thursday 09:00 | Maintainer / Codex review | Triage failures, dependency PRs, issues, upstream changes and Cookbook feedback |
| First Thursday of each month | Broader compatibility and release review | Check pinned ESP-IDF, LVGL and board support; arrange physical tests when hardware is available |

GitHub schedules can be delayed, and public-repository schedules can be disabled after 60 days without repository activity. Check that the schedule remains enabled. The Codex reminder is local to the configured chat/environment; it is not a replacement for CI or a hosted monitoring SLA.

## Weekly review checklist

1. Inspect the latest default-branch CI run and any failed or disabled scheduled runs. Check new issues and security reports, and give reproducible regressions priority.
2. Review Dependabot PRs individually. Read upstream release notes and compatibility changes; preserve dependency pins and immutable Action references. Do not auto-merge updates.
3. Check official OpenAI API documentation, SDK releases and deprecation notices against integrations that actually exist. Record the date, models/endpoints checked and any required action. A model-name change is not a safe automatic substitution.
4. Review vendor board, ESP-IDF and LVGL changes. These are currently pinned outside Dependabot's coverage and need a deliberate upgrade plus hardware verification.
5. Read Cookbook proposal/PR feedback. Prepare a focused response or implementation change; avoid repeated promotional follow-ups. Any published recipe must remain aligned with a reproducible tagged OpenDotlet revision.
6. Record actionable findings in a GitHub issue or focused PR, with links to evidence. Notify Peter when a failure, compatibility break, maintainer response or decision needs attention; unchanged checks can remain quiet.

## Change to release

**Triage → focused PR → automated checks → relevant physical acceptance → versioned release → documentation / Cookbook sync.**

- Use a separate branch and explain the behavior change, affected hardware and validation in the PR. Do not mix dependency upgrades with unrelated feature work.
- Run the checks in [Contributing](../CONTRIBUTING.md). Validate both themes if rendering changes affect both. A successful build proves compilation, not display, touch or audio behavior.
- For firmware/driver/rendering changes, physically verify startup, all affected faces (including blue U U eyes), navigation, touch and long press on the documented board. For future voice changes, additionally verify microphone input, audible playback, interruption, reconnect and cancellation on the actual claimed audio path. Clearly label laptop audio if used.
- For future API changes, use offline fixtures in normal CI. Live tests must be explicitly opted into using a dedicated project key on a trusted host, with a bounded budget. Verify response handling, device acknowledgement, retries/cancellation, authentication boundaries and failures. Never place a standard project key in firmware or public logs.
- Release only after the relevant checks pass. Use `v0.x.y` tags while the interface is experimental, with a changelog, exact commit, supported board, dependency versions, checks performed and known limits. Keep source releases distinct from redistributable firmware binaries; resolve third-party redistribution permissions before publishing binaries.
- Retain the previous known-good tag and flashing instructions. If a release regresses, mark it affected, document the regression and publish a fix or rollback instructions. Do not silently replace an existing tagged release.
- Update README, quickstart and API examples in the same change. If an accepted Cookbook recipe is affected, open a matching Cookbook correction with the new tested revision and migration notes. Do not advertise Cookbook inclusion before acceptance.

## Cookbook readiness gates

See [the proposal](COOKBOOK_PROPOSAL.md). The offline gallery is not yet a complete API recipe. Before a recipe PR, require maintainer scope approval, a runnable minimal API example, reproducible setup, original or appropriately licensed example artwork, real device evidence, cost/latency measurements and documented limitations. These are gates, not completed features.

## Evidence log

For each substantive review or release, retain: date, reviewer, commit/tag, CI URL, dependencies/API versions reviewed, physical checks actually performed, findings, linked issue/PR and next owner/action. Create an issue only for actionable work; a no-change week does not require a public commit.

Initial lifecycle configured on 6 November 2026. The first Thursday review is 12 November 2026. The weekly schedule must not automatically release, merge, spend API credits or flash hardware.

Sources: [GitHub scheduled workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule), [Dependabot configuration](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference), [Cookbook contribution process](https://github.com/openai/openai-cookbook/blob/main/CONTRIBUTING.md).
