# Build your first OpenDotlet

This guide installs the working offline gallery on **Waveshare ESP32-S3-Touch-LCD-1.46**. You need the board and a USB data cable. The gallery needs no API key, Wi-Fi setup or cloud service.

## 1. Prepare the toolchain

Install [ESP-IDF v5.3.2](https://docs.espressif.com/projects/esp-idf/en/v5.3.2/esp32s3/get-started/index.html), then activate its environment using `export.sh` from your installation. Use Python 3.9 or newer.

```sh
git clone https://github.com/heysalad-ai/opendotlet.git
cd opendotlet
python -m pip install -r requirements.txt
python tools/bootstrap.py
```

The bootstrap fetches checksum-pinned Waveshare support and LVGL 8.3.11. See [dependencies](../dependencies.json) and [third-party notices](../THIRD_PARTY_NOTICES.md). A network connection is needed for setup; the gallery runs offline.

## 2. Generate, check and build

```sh
python tools/pack_assets.py --theme black
python tools/validate_assets.py
python -m unittest discover -s tests -v
idf.py set-target esp32s3
idf.py build
```

The exporter generates `resources/preview.png`, packed RGB565 frames and matching LVGL descriptors. Inspect the preview before flashing.

## 3. Flash your board

Identify the correct serial port, such as `/dev/cu.usbmodem…` on macOS, `/dev/ttyACM0` on Linux or `COM3` on Windows. Back up any firmware/data you want to keep before replacing it. Flashing writes the bootloader, partition table and gallery app.

```sh
idf.py -p YOUR_PORT flash monitor
```

Exit the monitor with **Ctrl+]**. The first face is green and playback advances every seven seconds.

## 4. Use the gallery

| Interaction | Result |
| --- | --- |
| Tap | Show the next image and pause on it |
| Hold | Toggle automatic playback |
| Serial `NEXT` / `PREV` | Move without changing playback mode |
| Serial `PAUSE` / `AUTO` | Stop / resume automatic playback |
| Serial `STATUS` | Print current view and playback status |

Serial commands use 115200 baud and end with a newline. The optional smoke check opens/resets the board, exercises all 28 views and leaves playback running:

```sh
python tools/verify_serial.py --port YOUR_PORT
```

## Light theme

```sh
python tools/pack_assets.py --theme light
python tools/validate_assets.py
idf.py build
idf.py -p YOUR_PORT flash
```

Themes are selected when building; there is no runtime theme switch. The sheet-reference images retain white paper inside the surrounding theme.

## Customize the artwork

See [the artwork guide](CUSTOMIZATION.md). [Hardware notes](HARDWARE.md) identify the supported display and board; similar-looking round boards require separate ports.

## Troubleshooting

- **`idf.py` or `python` unavailable:** activate the ESP-IDF environment first.
- **Missing LVGL or board support:** run `python tools/bootstrap.py` from the repository root.
- **Missing `gallery.rgb565` / descriptors:** run the asset exporter before configuring the build.
- **Port cannot open:** close other serial monitors and re-identify the port after reconnecting.
- **Image orientation:** cyan/blue smile faces use U U eyes, open at the top. Mounting rotation is not configurable in this release.
- **Voice or dashboard absent:** those are planned features; this release is the gallery.

See [verification evidence](VERIFICATION.md) and the [U-eye correction checks](U-EYES-FIX.md). Hardware audio, battery runtime and other board variants have not been validated by this gallery.
