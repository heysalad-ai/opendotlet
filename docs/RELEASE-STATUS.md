# Public alpha status — 13 November 2026

Release: [0.6.0-alpha.2](https://github.com/heysalad-ai/opendotlet/releases/tag/v0.6.0-alpha.2). Companion source: [`fd9b991`](https://github.com/heysalad-ai/opendotlet/commit/fd9b991db39ecb7ffd3d36455aafeb27954010e9), in `companion/`.

| Layer | Evidence reviewed | What this establishes |
| --- | --- | --- |
| Saved-task host | 15 Python tests passed locally and in Windows CI | Read-only execution boundaries, host behavior and local access checks exercised by the suite. |
| Mac interface | 32 Swift tests, release build and native opening of the extracted final ZIP | The packaged Apple Silicon app opens and its bundled helper runs without a checkout or system Python. |
| Mac distribution | Apple notarization **Accepted**; ticket stapled; strict codesign, Gatekeeper and distribution assessment passed | Signed and notarized Mac alpha available for Apple Silicon/macOS 14+. |
| Windows build | [CI run 43508292999](https://github.com/heysalad-ai/opendotlet/actions/runs/43508292999) | Standalone executable, bundled Python/UI and clean-state local-API checks passed on a Windows runner. |
| Windows signing | SignTool `/pa /all /v`: zero errors/warnings; Authenticode **Valid**, exact **HeySalad Inc.** publisher and Microsoft timestamp | The `OpenDotlet.exe` launcher in the **Signed** ZIP is publisher-signed. The ZIP itself is checked with SHA-256. |
| Signed Windows runtime | Fresh-state startup on a physical Windows 11 machine; UI and JavaScript HTTP 200; anonymous API 401; authenticated API passed | The signed launcher starts its bundled local companion. This does not establish a new physical keypad-to-provider test. |
| Package integrity | Signed package compared with CI: launcher signature and setup README changed; 1,004 other payload files identical | Signing preserved the tested dependencies and bundled UI. |
| Public delivery | Fresh unauthenticated Mac/Signed-Windows downloads matched SHA-256; both domain names served the updated links | The downloads are publicly reachable and match the checked release artifacts. |
| Physical prototype | 30 press/release positions tested; white-logo key triggered a real saved Codex task; progress and completed response observed | The earlier Mac-plus-Windows-serial development setup demonstrated the intended interaction. |

Use the **Windows-x64-Signed.zip** asset. The original unsigned ZIP remains for provenance with a separate checksum. Mac publisher signing is under SALADHR TECHNOLOGY LTD; Windows publisher signing is under HeySalad Inc.

## Remaining acceptance work

- Complete first-time setup with fresh users on clean Mac and Windows environments, including Codex installation/sign-in and missing-access recovery.
- Repeat physical USB → key binding → Codex → result on each portable release. Test cable removal, reconnect, held keys, rapid presses and cancellation.
- Verify supported firmware/pin maps and publish a repeatable keypad build guide and hardware release package.
- Validate Intel Mac support separately before offering a download for it.
- Treat API-key mode, general workflows, supported Chrome/plugin distribution and OpenPromptlet task integration as future work.

No account, API key, subscription or Codex binary is bundled. Public alpha tests do not establish battery operation, manufacturing readiness, performance guarantees or support for every USB/board variant.
