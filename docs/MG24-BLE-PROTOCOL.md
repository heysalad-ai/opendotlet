# OpenDotlet BLE protocol v1

Native companion and Silicon Labs MG24 firmware. Record first, transfer after release. The board microphone is PC9 with PC8 power; key is D2, pixel is D3. The USB serial endpoint is not used to transport these clips. A receiver/companion application is required and is not included in this firmware-only addition.

Service UUID: `5F31A700-6D6C-4B7D-9F7C-0A2D6E010001`.

| Characteristic | UUID prefix | Operation |
| --- | --- | --- |
| Control | `5F31A701` (same suffix) | Encrypted write with response: 1 arm one clip, 2 cancel/disarm, 3 heartbeat. |
| Status | `5F31A702` | Encrypted read/notify, 20 bytes. |
| Audio | `5F31A703` | Encrypted notify, ordered byte fragments. |

BLE pairing uses the Silicon Labs no-input/no-output bonding flow. The application checks the custom service after attaching; it also handles the board already being connected through the earlier MG24 keyboard pairing. This development firmware does not implement a separate account or owner-enrolment system.

Status is little endian: byte 0 protocol version (1); byte 1 state; bytes 2–3 clip ID; 4–7 sample count; 8–11 capture duration in microseconds; 12–15 FNV-1a checksum of raw sample bytes; 16–17 maximum sample lateness in microseconds (saturated at 65535); byte 18 stop reason; byte 19 flags (1 encrypted, 2 microphone power, 4 both notification subscriptions active).

States: 0 idle, 1 armed, 2 recording, 3 transferring, 4 transfer complete, 5 error. Stop reasons: 0 release, 1 ten-second limit, 2 cancellation, 3 disconnect, 4 host-heartbeat expiry. Each status fits the minimum ATT MTU of 23. A transfer status must arrive before the first audio fragment; the complete status follows queued audio notifications.

Audio packets: byte 0 `0xA1`; bytes 1–2 clip ID; bytes 3–6 byte offset; bytes 7 onward raw little-endian uint16 ADC values (0–4095). Fragments can split a sample. The receiver requires sequential offsets, the expected clip ID, a maximum 160,000 bytes, exact final length, and matching FNV-1a checksum. Corrupt or incomplete clips are not sent to the transcriber.

Firmware requests ATT MTU 247 and 30–50 ms connection intervals; actual negotiation depends on macOS. Packets carry at most 180 audio bytes, bounded by negotiated MTU. Transfer retries when controller buffers are full. The fallback transfer deadline is 75 seconds on firmware and 80 seconds in the app.

Explicit arming plus a fresh key press is required. A held key at boot/after a clip must be released before another capture can begin. Green indicates microphone capture; blue indicates transfer; microphone power is removed before transfer. Capture ends on release (20 ms debounce), ten seconds, cancellation, disconnect or five seconds without host heartbeat. The development Mac companion maintains a heartbeat while enabled/recording. Other receivers should disarm on shutdown and use an 80-second receive deadline, longer than the firmware deadline.

The microphone library uses completed single-shot ADC reads. Its core 4.0.0 `end()` path is avoided because it frees a DMA channel even though this acquisition mode did not allocate one; this was observed to interrupt UART receive during the USB experiment. Power is switched off directly after the last conversion. Silicon Labs library files are not modified.
