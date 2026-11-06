# Security

OpenDotlet is an early hardware prototype. The current gallery runs offline and has no account, API key, network service, OTA updater or remote device-management endpoint.

## Reporting a concern

For a potential security vulnerability, use the repository's **Security → Report a vulnerability** route if private reporting is available. Otherwise, contact an owner through the [HeySalad organization](https://github.com/heysalad-ai) to establish a private reporting channel. Do not post keys, device backups, personal data or exploit details in a public issue. This project does not promise a response SLA or bounty.

## Project boundaries

- Keep full-flash backups private; they can contain configuration or credentials from earlier firmware.
- Bootstrap dependencies are pinned by commit and checked with SHA256; preserve upstream notices.
- Future OpenAI integrations must keep long-lived project credentials on the trusted host. Per-device pairing, authorization, revocation and usage limits are planned work, not current guarantees.
- Never treat a model decision or generated device identifier as authorization for another user's device or external account.

See [third-party notices](THIRD_PARTY_NOTICES.md), [architecture](docs/ARCHITECTURE.md) and [verification limits](docs/VERIFICATION.md).
