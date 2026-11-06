# Supported hardware

The current target is Waveshare ESP32-S3-Touch-LCD-1.46, not a generic ESP32 display.

| Part | Configuration |
| --- | --- |
| MCU | ESP32-S3, 240 MHz |
| Flash / PSRAM | 16 MB / 8 MB octal, PSRAM at 80 MHz |
| Display | SPD2010 QSPI, 412 × 412 round LCD |
| Display clock | GPIO40 |
| Display data 0–3 | GPIO46, GPIO45, GPIO42, GPIO41 |
| Display chip select | GPIO21 |
| Touch | SPD2010 through the board's I²C support |
| USB | Native USB Serial/JTAG console, 115200 baud |
| Brightness | 65 percent requested by the gallery |
| App partition | Factory app at 0x10000, 15 MB |

Board wiring, power control, touch initialization and LVGL buffers use the matching pinned Waveshare example. The onboard speaker, microphone, motion sensor and battery functionality are not exercised by the gallery.

Do not assume that a board with a similar product name has the same pins, controller or power sequence. Consult the [vendor schematic and documentation](https://docs.waveshare.com/ESP32-S3-Touch-LCD-1.46).
