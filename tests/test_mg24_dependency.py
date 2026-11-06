"""Ensure the vendored Silicon Labs LED driver remains the pinned upstream source."""
import hashlib
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MG24DependencyTests(unittest.TestCase):
    def test_vendored_driver_matches_recorded_upstream_hash(self):
        target = ROOT / "firmware" / "mg24-neokey"
        lock = json.loads((target / "dependencies.json").read_text())
        source = (target / "neokey_ble" / "ezWS2812gpio.h").read_bytes()
        self.assertFalse(lock["modified"])
        self.assertEqual(hashlib.sha256(source).hexdigest(), lock["sha256"])
        self.assertIn(lock["commit"], lock["url"])


if __name__ == "__main__":
    unittest.main()
