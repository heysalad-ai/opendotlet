"""Validate packed gallery data before compiling or flashing."""
import json
from pathlib import Path
import zlib

ROOT = Path(__file__).resolve().parents[1]


def validate(root=ROOT):
    manifest = json.loads((root / "resources/manifest.json").read_text())
    raw = (root / "resources/gallery.rgb565").read_bytes()
    assert (manifest["count"], manifest["width"], manifest["height"]) == (28, 412, 412)
    assert manifest["bytes_per_frame"] == 339488
    assert len(manifest["names"]) == 28
    assert len(raw) == 28 * 339488, "Truncated frame data"
    assert hex(zlib.crc32(raw)) == manifest["crc32"], "Frame checksum mismatch"
    black = range(28) if manifest["theme"] == "black" else (10, 23)
    white = () if manifest["theme"] == "black" else (11, 22)
    for indices, color in [(black, b"\0\0"), (white, b"\xff\xff")]:
        for index in indices:
            for x, y in [(0, 0), (411, 0), (0, 411), (411, 411)]:
                offset = index * 339488 + 2 * (y * 412 + x)
                assert raw[offset:offset + 2] == color, (index, x, y)
    print(f"PASS: {manifest['theme']} gallery size, CRC32 and background corners")


if __name__ == "__main__":
    validate()
