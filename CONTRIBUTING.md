# Contributing

Keep changes focused and describe what was tested. The default branch contains the original round-gallery firmware and current project documentation. The downloadable saved-task companion source is under the `v0.6.0-alpha.2` tag in `companion/`; name that source/ref explicitly when proposing companion changes.

For documentation-only work, check relative links and image paths and inspect the rendered page. For companion work, use the pinned build requirements and run its Python tests (`python -m pytest tools/tests -q`); Mac changes also require the Swift tests/build. Report physical USB/provider acceptance separately from software checks.

For round-gallery firmware changes, run the asset checks and build:

```sh
python tools/pack_assets.py --theme black
python tools/validate_assets.py
python -m unittest discover -s tests -v
idf.py build
```

If you change light-theme rendering, regenerate and validate that theme too. For firmware or driver changes, report the exact board and physically test display, tap and long-press behavior. CI cannot prove touchscreen behavior.

Never commit full-flash backups, credentials, Wi-Fi settings, device identifiers, local logs or generated build files. Keep upstream notices intact and use original or appropriately licensed artwork in contributions.

Please open an issue before adding a new board, changing the serial protocol or introducing cloud/network dependencies. The standalone round gallery needs no account or API key. The saved-task companion requires the user's Codex CLI sign-in; API-key keypad execution is still planned.

See the [maintenance lifecycle](docs/MAINTENANCE.md) for Thursday reviews, dependency updates, physical acceptance and release requirements.
