"""Regression checks for the approved artwork and rejection of bad asset inputs."""
import json
import hashlib
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from pack_assets import pack
from validate_assets import validate

ROOT = Path(__file__).resolve().parents[1]
BLACK_CRC = '0x17e57e1a'
LIGHT_CRC = '0x213c0ab9'


class AssetTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copytree(ROOT / 'artwork', self.root / 'artwork')
        (self.root / 'main').mkdir()

    def test_black_theme_approved_crc_and_backgrounds(self):
        pack('black', self.root)
        validate(self.root)
        manifest = json.loads((self.root / 'resources/manifest.json').read_text())
        self.assertEqual(manifest['crc32'], BLACK_CRC)
        self.assertFalse(Path(manifest['source_atlas']).is_absolute())

    def test_light_theme_approved_crc_and_logo_polarities(self):
        pack('light', self.root)
        validate(self.root)
        manifest = json.loads((self.root / 'resources/manifest.json').read_text())
        self.assertEqual(manifest['crc32'], LIGHT_CRC)

    def test_reject_corruption_and_truncation(self):
        pack('black', self.root)
        path = self.root / 'resources/gallery.rgb565'
        original = path.read_bytes()
        corrupted = bytearray(original)
        corrupted[10000] ^= 1
        path.write_bytes(corrupted)
        with self.assertRaisesRegex(AssertionError, 'checksum'):
            validate(self.root)
        path.write_bytes(original[:-2])
        with self.assertRaisesRegex(AssertionError, 'Truncated'):
            validate(self.root)

    def test_u_eyes_are_open_at_top_in_both_themes(self):
        for theme in ('black', 'light'):
            with self.subTest(theme=theme):
                pack(theme, self.root)
                raw = (self.root / 'resources/gallery.rgb565').read_bytes()
                for index in (8, 17):
                    frame = raw[index * 339488:(index + 1) * 339488]
                    for left, right in ((60, 190), (230, 350)):
                        def dark(x, y):
                            offset = 2 * (y * 412 + x)
                            value = int.from_bytes(frame[offset:offset + 2], 'big')
                            # Treat antialiased near-black ink as part of the eye.
                            return (value >> 11) < 4 and ((value >> 5) & 63) < 8 and (value & 31) < 4
                        points = [(x, y) for y in range(130, 280)
                                  for x in range(left, right) if dark(x, y)]
                        self.assertTrue(points, 'Missing eye')
                        x0 = min(x for x, _ in points)
                        x1 = max(x for x, _ in points)
                        y0 = min(y for _, y in points)
                        y1 = max(y for _, y in points)
                        mid = (x0 + x1) // 2
                        self.assertFalse(dark(mid, y0 + 4), 'Eye must be open at top')
                        self.assertTrue(dark(mid, y1 - 4), 'Eye must curve across bottom')

    def test_other_frames_match_published_baseline(self):
        baseline = json.loads((ROOT / 'tests/baseline-frame-sha256.json').read_text())
        for theme in ('black', 'light'):
            pack(theme, self.root)
            raw = (self.root / 'resources/gallery.rgb565').read_bytes()
            for index in range(28):
                if index in (8, 17):
                    continue
                frame = raw[index * 339488:(index + 1) * 339488]
                self.assertEqual(hashlib.sha256(frame).hexdigest(), baseline[theme][index])

    def test_reject_wrong_atlas_dimensions(self):
        Image.new('RGB', (100, 100)).save(self.root / 'artwork/atlas-black.png')
        with self.assertRaisesRegex(ValueError, '1536x1024'):
            pack('black', self.root)

    def test_reject_missing_atlas(self):
        (self.root / 'artwork/atlas-black.png').unlink()
        with self.assertRaises(FileNotFoundError):
            pack('black', self.root)


if __name__ == '__main__':
    unittest.main()
