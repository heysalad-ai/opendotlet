# Third-party notices

The native Mac app is adapted from [HeySalad NiceDeck](https://github.com/heysalad-ai/nicedeck) at commit `2bb5203218e88f2993ec0d96dcd997d3ba86e96e`. The original project was named OpenStreamDeck. Its MIT copyright notice is retained in `macOS/NICEDECK-LICENSE` and copied into the application bundle. The SwiftUI window shell, visual tokens, button style and app-store organization were adapted for OpenDotlet. Its ESP32 touchscreen firmware and host action executor are not part of the Dotlet application.

Silicon Labs' MIT notice is retained in the official `ezWS2812gpio.h` source copied into each sketch. `SilabsMicrophoneAnalog`, the BLE stack and other core components are supplied by the installed Silicon Labs Arduino core 4.0.0 and retain their respective upstream licences.

Local transcription uses the installed faster-whisper, CTranslate2 and associated packages; exact installed versions are recorded in `requirements-ptt.lock`. The locally downloaded base.en model and Python environment are development dependencies, not bundled or redistributed with this application.

## Peel Mac app assets

Approved original HeySalad Peel icon, characters and device faces originate from design commit `6a18d6394818a84fc573b1777cd9a03c0bcadf8e` in heysalad-ai/opendotlet. Copyright 2026 HeySalad. The source design branch has not selected an artwork licence; these assets are not relicensed under the MIT application licence. Original SVGs and provenance are retained in `assets/Peel`. The OpenAI-library preview PNGs are decoded from the existing OpenDotlet event-art gallery (black CRC32 `0x17e57e1a`); event artwork and marks retain their separate terms. OpenDotlet is independent of OpenAI. NiceDeck shell attribution is retained in `macOS/NICEDECK-LICENSE`.

## Nunito font

`assets/Peel/fonts/Nunito-Black.ttf` and `Nunito-ExtraBold.ttf` are the Latin subset of Nunito (Fontsource 5.3.0 package), with family and PostScript names normalised. Copyright 2014 The Nunito Project Authors (https://github.com/googlefonts/nunito). Licensed under the SIL Open Font License 1.1; see `assets/Peel/fonts/OFL-Nunito.txt`.


## Local Ambi engine (0.4 runtime integration)

OpenDotlet’s agent host imports the existing local `jenniferumoke/ambi-openai-hackathon` Python engine. The inspected working copy was revision `d355574`. Ambi’s original code is MIT licensed, copyright © 2026 Ambi contributors; retain its LICENSE and third-party notices if packaging that source in a future standalone distribution. This development app references the existing checkout and environment; it does not bundle or relicense Ambi’s code/models/assets. No provider key or private configuration file is included in the app bundle.

## Neutral identity colourway (13 November 2026)

At the owner's request, `source/dotlet-neutral.svg` derives from the existing Paper Peel SVG with only colour substitutions. `brand-neutral.png`, the installed app icon, and the website's neutral/green/ink colourways retain the original Peel contours and the same artwork licensing boundaries. The original coloured files remain preserved.
