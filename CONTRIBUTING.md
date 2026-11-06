# Contributing

Keep changes focused and describe what was tested. Run the asset checks and build before opening a pull request:

```sh
python tools/pack_assets.py --theme black
python tools/validate_assets.py
python -m unittest discover -s tests -v
idf.py build
```

If you change light-theme rendering, regenerate and validate that theme too. For firmware or driver changes, report the exact board and physically test display, tap and long-press behavior. CI cannot prove touchscreen behavior.

Never commit full-flash backups, credentials, Wi-Fi settings, device identifiers, local logs or generated build files. Keep upstream notices intact and use original or appropriately licensed artwork in contributions.

Please open an issue before adding a new board, changing the serial protocol or introducing cloud/network dependencies. This prototype currently needs no account or API key.
