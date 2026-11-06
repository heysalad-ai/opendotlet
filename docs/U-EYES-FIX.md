# Blue U-eye correction

6 November 2026.

The two individual cyan/blue arch-eye faces now have upright U U eyes, open at the top. Whole-display orientation and other expressions were not changed.

Built-in ImageGen supplied the corrected artwork. Atlas assembly retained only its two requested tiles, preserving every other original tile. Both black and light themes were exported and visually inspected. Packed frames outside indices 8 and 17 are byte-identical to public commit `564dd28a08ecbe37d21b98a16544f093c6a6b2bd`; the regression suite checks that against saved SHA256 baselines.

- Seven asset tests passed, including a U-versus-arch geometry check and unaffected-frame preservation.
- Both themes passed dimensions, byte-length, CRC32 and corner-color checks.
- ESP-IDF 5.3.2 build passed, with 36 percent app-partition space free.
- Black-theme CRC32: `0x17e57e1a`; light-theme CRC32: `0x213c0ab9`.
- Corrected black build flashed successfully with device flash hash verification. Serial smoke captured the v4 boot, READY, all 28 views, pause/wraparound and resumed automatic playback, with no captured panic.
- The owner's physical confirmation of the new eye appearance is pending.

The U-eye check was first run against the previous gallery and failed for both themes; it passes with the corrected assets. Antialiased near-black pixels are treated as eye ink, while cyan background pixels remain outside that classification.
