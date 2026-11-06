# Verification

Initial publication checks, 6 November 2026.

## Locally observed

- Pinned Waveshare files downloaded with SHA256 verification and compared with the working prototype's board support.
- LVGL 8.3.11 fetched from its pinned commit and verified against its archive SHA256.
- Python syntax compilation passed for tools and tests.
- Five asset regression tests passed: black-theme baseline, light-theme baseline, corruption/truncation rejection, wrong dimensions and missing atlas rejection.
- Both themes regenerated with the same CRC32 as the earlier hardware-tested exports. Black: `0x75cf04b1`; light: `0x6d3b2aa5`.
- Full ESP-IDF 5.3.2 build from an empty build directory passed: application size `0x986e10`, factory partition `0xf00000`, 36 percent free.
- The application source and packed black-theme frames are byte-identical to the version already installed and tested on the prototype board. The separately named repository build has not been reflashed merely to rename the project.
- The prototype's owner confirmed that the larger faces, tap navigation and final black-background appearance looked correct. No automated camera inspection is claimed.
- Staged publication files were checked for home paths, device identifiers, credential patterns, full-flash backups and build artifacts. None were included.

- Connected-board serial smoke: the first capture missed the automatic-playback assertion; two subsequent runs passed READY, all 28 views, pause, wraparound and two automatic advances. Treat this timing-sensitive capture as a diagnostic, not a substitute for physical inspection.

## Limits

Only the Waveshare ESP32-S3-Touch-LCD-1.46 has been physically exercised. CI compiles firmware and validates assets; it cannot validate touch, display appearance, power behavior or other board variants. The vendor support emits a legacy I²C deprecation warning. Battery runtime, audio, Wi-Fi, Bluetooth and long-term reliability have not been tested by this gallery project.

## Repeat checks

```sh
python -m compileall -q tools tests
python -m unittest discover -s tests -v
python tools/pack_assets.py --theme black
python tools/validate_assets.py
idf.py build
# Optional, on the exact supported board:
python tools/verify_serial.py --port YOUR_PORT
```
