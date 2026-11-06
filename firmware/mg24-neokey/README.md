# XIAO MG24 Sense + NeoKey BLE microphone

A separate microphone-button prototype for **Seeed Studio XIAO MG24 Sense + Adafruit NeoKey BFF**, using the Silicon Labs EFR32MG24. This sketch is not for the Waveshare ESP32-S3 display.

Open a compatible BLE companion, connect, enable both notification characteristics and arm one clip. Hold the physical key to record from the board microphone; release to stop. Green means capture, blue means transfer. Microphone power is off during idle and transfer. A new arm is required for each clip. Without a companion arming it, a key press does not record.

The sketch sends raw audio; it does not transcribe or run an agent. A local native Mac prototype received and transcribed real clips during development, but that companion is not included in this firmware-only addition. There is no standalone end-user application in this repository yet. See [the BLE protocol](../../docs/MG24-BLE-PROTOCOL.md) to implement a receiver.

## Wiring

| Function | Pin |
| --- | --- |
| NeoKey switch, default jumper | A2 / D2 (PC2), internal pull-up |
| NeoKey RGB pixel, default jumper | A3 / D3 (PC3) |
| Sense onboard analog microphone | PC9 |
| Microphone power | PC8 |

An ordinary XIAO MG24 without the Sense microphone is not an equivalent recording target. Cut or rewired NeoKey jumpers require code changes. No board serial number is embedded; the generic advertised name is `OpenDotlet Mic`.

## Build

Tested with Arduino CLI **1.5.1** and Silicon Labs core **4.0.0**. Install the matching core, then build from the repository root:

```sh
arduino-cli core update-index --additional-urls https://siliconlabs.github.io/arduino/package_arduinosilabs_index.json
arduino-cli core install SiliconLabs:silabs@4.0.0 --additional-urls https://siliconlabs.github.io/arduino/package_arduinosilabs_index.json
bash tools/build-mg24.sh
```

FQBN: `SiliconLabs:silabs:xiao_mg24:protocol_stack=ble_silabs`. `SilabsMicrophoneAnalog` is bundled with that core. The unmodified official `ezWS2812gpio.h` is pinned by commit and SHA-256 in `dependencies.json`, with its upstream MIT notice retained. Its upstream bit-order fix is newer than the bundled core 4.0.0 header. Firmware explicitly enables the CPU cycle counter used by the manufacturer's GPIO timing loops.

If the installed `ctags` binary cannot run on your Mac, supply a compatible native executable directory without changing shared Arduino files:

```sh
MG24_CTAGS_PATH=/path/to/native-ctags-directory bash tools/build-mg24.sh
```

The directory must contain an executable named `ctags`. This override was used for the local Apple Silicon build. Output is ignored under `build-mg24/`; compiling does not upload or change a board.

## Upload and device identity

Back up the target board's firmware/data privately before replacing it. Use an MG24-capable programmer/debugger and verify the written image. The hardware test used a compatible native OpenOCD build with Silicon Labs xG24 target support and an explicitly selected CMSIS-DAP adapter. A portable flasher, tool binaries and a flash image are not included. Do not reuse the ESP32 display flashing command for this target.

If macOS still has the earlier MG24 keyboard pairing, a companion may need to attach to the already-connected peripheral and discover this custom service. Existing keyboard/service caches can affect discovery after firmware replacement.

## Capture and limits

Capture targets 8 kHz, 12-bit unsigned ADC samples stored as little-endian uint16 values, with at most 80,000 samples / ten seconds in RAM. Release uses 20 ms debounce. Cancellation, disconnect and a five-second host-heartbeat expiry also stop capture. Transfer starts after microphone power is removed; fragments carry clip ID and byte offset, and metadata carries a full-clip FNV-1a checksum.

Pairing uses encrypted BLE with no-input/no-output bonding; separate owner enrolment is not implemented. This is not a system Bluetooth microphone or headset profile. Firmware requests ATT MTU 247 and 30–50 ms connection intervals; the peer decides the negotiated values. Transfer deadline is 75 seconds.

The Silicon Labs core 4.0.0 analog library's `end()` path frees a DMA channel even though this single-shot mode did not allocate one. That path was observed to interrupt UART reception in the earlier USB experiment. This sketch instead removes PC8 microphone power after completed single-shot reads; installed library files are unchanged.

## Evidence

On 6 November 2026, the same capture/transfer implementation recorded a 5.21-second spoken clip, delivered 83,038 bytes over BLE, passed receiver length/offset/checksum checks and produced a coherent local transcript. A companion observed microphone-power flags off before transfer. Larger packets reduced comparable five-second transfer time from about 28 seconds to about seven seconds. These are development observations, not general performance guarantees.

The published source replaces the development board-specific advertised name with the generic name above; its build is rechecked. It has not been reflashed just to change that name. Raw recordings, transcripts, pairing data, device identifiers, backups and local logs are not published.

Remaining physical checks: ten-second cutoff, disconnect during capture, transfer-timeout recovery, battery runtime, long-term reliability, audio quality across environments, and iOS/Android reception. Sampling is software scheduled; occasional lateness and average-rate correction were observed. The current round-display firmware is not yet connected to this microphone target.
