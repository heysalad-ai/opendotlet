"""Regression checks for the approved artwork and rejection of bad asset inputs."""
import json
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
BLACK_CRC = '0x75cf04b1'
LIGHT_CRC = '0x6d3b2aa5'


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
