# Third-party notices

The root MIT license covers HeySalad's original application, tooling and documentation. It does not relicense third-party code, artwork or trademarks.

## Waveshare board support (downloaded, not redistributed here)

`tools/bootstrap.py` fetches the board files from:

https://github.com/waveshareteam/ESP32-S3-Touch-LCD-1.46/tree/fda89ff2ff32eb1bce561901225c6a36fa684237/example/ESP-IDF-5.3.2/ESP32-S3-Touch-LCD-1.46-Test/main

The exact paths and SHA256 hashes are in `dependencies.json`. These files match the board support used in the tested prototype. At this revision the upstream repository has no repository-wide license. Fetching it does not grant additional redistribution rights. Consult upstream terms before distributing builds containing that support code.

The nested `esp_lcd_spd2010` files carry Espressif copyright notices and SPDX `Apache-2.0` identifiers. The bootstrap preserves those headers. Other Waveshare board files retain their upstream contents without modification. No claim is made that these files are covered by HeySalad's MIT license.

## LVGL 8.3.11 (downloaded, not redistributed here)

https://github.com/lvgl/lvgl/tree/74d0a816a440eea53e030c4f1af842a94f7ce3d3

MIT licensed, copyright LVGL Kft. The downloaded tree retains `LICENCE.txt` and its upstream notices.

## ESP-IDF 5.3.2 (installed separately)

https://github.com/espressif/esp-idf/tree/v5.3.2

ESP-IDF and its included components retain their upstream licenses. It is not vendored into this repository.

## Artwork

See `artwork/README.md`. Event-inspired reconstructions and OpenAI marks are not included in the MIT code license. No official sponsorship or endorsement is implied.

## Silicon Labs MG24 microphone target

`firmware/mg24-neokey/neokey_ble/ezWS2812gpio.h` is unmodified from Silicon Labs' Arduino repository at commit `7e9c53cac8b2c1d33da6a1c109653130801621f1`. The source retains the MIT licence and copyright (c) 2024 Silicon Laboratories Inc. Exact source URL and SHA-256 are recorded in `firmware/mg24-neokey/dependencies.json`.

The separately installed Silicon Labs Arduino core 4.0.0 supplies `SilabsMicrophoneAnalog`, the BLE stack and other SDK components. Their upstream licences remain applicable. Core packages, compiler/debugger binaries and the development Mac companion are not redistributed here.
