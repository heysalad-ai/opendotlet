# Open.Dotlet public alpha 0.6.0-alpha.2

Download only from opendotlet.com or github.com/heysalad-ai/opendotlet releases.

## Mac
Apple Silicon (M1 or newer), macOS 14+. Unzip, drag OpenDotlet.app into Applications, then open it. The saved-task runtime and Python are bundled; no project checkout is needed. This alpha supports the Agent team saved-task workflow. The development app's voice/Ambi features are not included in the release workflow.

## Windows
Windows 11 x64. Extract the entire ZIP first, then open OpenDotlet/OpenDotlet.exe. Keep its launcher console open while using the local browser companion; closing the console stops it. Python and pyserial are included. This is an unsigned public alpha; it has no Windows publisher signature. No Mac host is required.

## First task — no hardware needed
1. Install the current Codex CLI and sign in with `codex login` in your terminal. Official guide: https://learn.chatgpt.com/docs/codex/cli . Open.Dotlet does not bundle an account, API key or subscription. Your account's normal limits apply.
2. Launch Open.Dotlet. Select the top-left white-logo dotlet. The default Project summary task points to a new Documents/OpenDotlet example folder belonging to you.
3. Edit the project folder and prompt if desired, save, then choose Run task. Read the result beside your dotlets. Only one read-only task runs at a time.
4. Optional hardware: in Device options choose the USB port and Connect USB. Release all keys before connecting. The supported C6 firmware must produce `C6_KEY_PRESS_TEST v1` status and press/release events. No firmware is flashed by the app. The white-logo key is matrix row 5, column 6 on this photographed build. Use the learning action or edit bindings for another pad.

The Windows form needs the full path to an existing local project folder. Close the local companion and launcher when finished. Tasks and results are stored in your user profile, not sent to HeySalad. Prompts and selected project context are processed through your own Codex account.

## Scope
Saved read-only tasks, editable assignments, results/history, cancel/pause and direct USB connection. API-key keypad execution, independent agent teams, general writable automation and OpenPromptlet task-state integration are not part of this alpha.

This is an independent HeySalad project, not affiliated with or endorsed by OpenAI. Code and artwork have separate licence boundaries; see THIRD_PARTY_NOTICES.md. No personal settings, recordings, sign-in tokens or developer mappings are included.
