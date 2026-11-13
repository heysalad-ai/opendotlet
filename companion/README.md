# Open.Dotlet companion alpha

Standalone saved-task companion for Mac and Windows. See [setup and release limits](docs/releases/ALPHA-README.md). The existing gallery and firmware history at the repository root is preserved.

Build on the target platform: `python -m pip install -r requirements-build.txt`, then `python scripts/package-alpha.py --output /path/to/fresh/output`. macOS also needs Xcode Command Line Tools; pass `--identity` for a Developer ID build.

Run `python -m pytest tools/tests -q`; on Mac also run `swift test --package-path macOS`.
