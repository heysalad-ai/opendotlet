"""Pack repository artwork into LVGL RGB565 frames for the round display."""
import argparse
import json
from pathlib import Path
import struct
import zlib

from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SIZE = 412
FRAME_BYTES = SIZE * SIZE * 2


def pack(theme="black", root=ROOT):
    artwork = root / "artwork"
    atlas_path = artwork / f"atlas-{theme}.png"
    atlas = Image.open(atlas_path).convert("RGB")
    if atlas.size != (1536, 1024):
        raise ValueError(f"Expected 1536x1024 atlas, got {atlas.size}")
    names = json.loads((artwork / "names.json").read_text())
    if len(names) != 28 or not all(isinstance(name, str) for name in names):
        raise ValueError("Expected 28 string frame names")
    frames = []
    for row in range(4):
        for col in range(6):
            box = (col * 256 + 2, row * 256 + 2,
                   (col + 1) * 256 - 2, (row + 1) * 256 - 2)
            frames.append(atlas.crop(box).resize((SIZE, SIZE), Image.Resampling.LANCZOS))
    exchange = Image.open(artwork / "devday-exchange-sheet-digital-v1.png")
    community = Image.open(artwork / "devday-sheet-digital-v1.png")
    for source in [exchange, community, exchange.crop((70, 535, 625, 775)),
                   exchange.crop((70, 790, 625, 1036))]:
        bound = (246, 328) if source.height > source.width else (370, 180)
        view = ImageOps.contain(source.convert("RGB"), bound, Image.Resampling.LANCZOS)
        frame = Image.new("RGB", (SIZE, SIZE), (0, 0, 0) if theme == "black" else (250, 250, 246))
        frame.paste(view, ((SIZE - view.width) // 2, (SIZE - view.height) // 2))
        frames.append(frame)
    for index in (10, 11, 22, 23):
        frames[index] = frames[index].point(lambda c: 0 if c < 64 else 255 if c > 192 else c)
    if theme == "black":
        frames = [frame.point(lambda c: 0 if c < 16 else c) for frame in frames]
    raw = bytearray()
    for frame in frames:
        for r, g, b in frame.getdata():
            raw.extend(struct.pack(">H", ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)))
    if len(raw) != len(names) * FRAME_BYTES:
        raise ValueError("Incorrect RGB565 output length")
    resources = root / "resources"
    resources.mkdir(exist_ok=True)
    (resources / "gallery.rgb565").write_bytes(raw)
    manifest = {"theme": theme, "count": len(names), "width": SIZE, "height": SIZE,
                "bytes_per_frame": FRAME_BYTES, "crc32": hex(zlib.crc32(raw)),
                "names": names, "source_atlas": atlas_path.relative_to(root).as_posix()}
    (resources / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (root / "main" / "assets.h").write_text(
        '#pragma once\n#include "lvgl.h"\n#define GALLERY_COUNT 28\n'
        'extern lv_img_dsc_t gallery_images[GALLERY_COUNT];\n'
        'extern const char *gallery_names[GALLERY_COUNT];\nvoid gallery_assets_init(void);\n')
    (root / "main" / "assets.c").write_text(
        '#include "assets.h"\n'
        'extern const unsigned char gallery_blob[] asm("_binary_gallery_rgb565_start");\n'
        'lv_img_dsc_t gallery_images[GALLERY_COUNT];\n'
        'const char *gallery_names[GALLERY_COUNT] = {' + ','.join(json.dumps(n) for n in names) + '};\n'
        'void gallery_assets_init(void) {\n'
        ' for (int i = 0; i < GALLERY_COUNT; i++) {\n'
        '  gallery_images[i] = (lv_img_dsc_t){.header={.always_zero=0,.w=412,.h=412,'
        '.cf=LV_IMG_CF_TRUE_COLOR},.data_size=339488,.data=gallery_blob+i*339488};\n'
        ' }\n}\n')
    preview = Image.new("RGB", (1260, 840), "#252525")
    draw = ImageDraw.Draw(preview)
    mask = Image.new("L", (170, 170))
    ImageDraw.Draw(mask).ellipse((0, 0, 169, 169), fill=255)
    for index, frame in enumerate(frames):
        x, y = (index % 7) * 180 + 5, (index // 7) * 210 + 5
        preview.paste(frame.resize((170, 170)), (x, y), mask)
        draw.text((x, y + 175), names[index], fill="white")
    preview.save(resources / "preview.png")
    print(f"Packed {len(frames)} {theme} frames: {len(raw)} bytes")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--theme", choices=("black", "light"), default="black")
    pack(parser.parse_args().theme)
