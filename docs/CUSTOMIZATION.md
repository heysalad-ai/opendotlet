# Make your own Dotlet face

The gallery uses two source atlases: `artwork/atlas-black.png` and `artwork/atlas-light.png`. Each is **1536 × 1024 pixels**, arranged as six columns and four rows of 256-pixel square tiles.

Keep faces centered and leave a two-pixel inset at tile edges. The exporter trims that inset, scales each tile to 412 × 412 and encodes big-endian RGB565 for LVGL with `CONFIG_LV_COLOR_16_SWAP=y`.

1. Replace the desired source atlas with artwork you can use.
2. Preserve tile ordering; the 28 display labels are in `artwork/names.json`.
3. Run the exporter and inspect `resources/preview.png`.
4. Validate, build and flash using the [quickstart](QUICKSTART.md).

```sh
python tools/pack_assets.py --theme black
python tools/validate_assets.py
idf.py build
```

The final four views come from the reference sheets in `artwork/`. Edit `tools/pack_assets.py` to replace those views. The generated frame count, dimensions and descriptors must agree and fit in flash.

The bundled regression baselines intentionally describe the approved sample artwork. If you replace it, review/update the artwork-specific golden values and frame-preservation checks deliberately; keep size, corruption and decoder/format checks meaningful. The U-eye test describes the bundled cyan/blue sample, not a universal rule for custom faces.

The firmware currently embeds assets at build time. It does not download images, decode arbitrary PNG/GIF/SVG files or activate generated faces over the network. Those capabilities belong to the [roadmap](ROADMAP.md).

Artwork/trademarks are separate from the MIT application license. See [artwork terms and provenance](../artwork/README.md) and [third-party notices](../THIRD_PARTY_NOTICES.md).
