"""Fetch pinned board support and LVGL without redistributing vendor sources."""
import concurrent.futures
import hashlib
import io
import json
from pathlib import Path
import tarfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def download(url, expected):
    with urllib.request.urlopen(url, timeout=90) as response:
        data = response.read()
    if hashlib.sha256(data).hexdigest() != expected:
        raise ValueError(f"Dependency checksum mismatch: {url}")
    return data


def main():
    lock = json.loads((ROOT / "dependencies.json").read_text())
    board = lock["waveshare"]

    def fetch_file(item):
        relative, checksum = item
        dest = ROOT / "main" / relative
        if dest.exists() and hashlib.sha256(dest.read_bytes()).hexdigest() == checksum:
            return
        url = (f"https://raw.githubusercontent.com/{board['repository']}/"
               f"{board['commit']}/{board['root']}/{relative}")
        data = download(url, checksum)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
        list(executor.map(fetch_file, board["files"].items()))

    lvgl = lock["lvgl"]
    dest = ROOT / "components" / "lvgl"
    url = f"https://codeload.github.com/lvgl/lvgl/tar.gz/{lvgl['commit']}"
    data = download(url, lvgl["sha256"])
    # Write regular files only, strip the archive's root, reject path traversal.
    with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
        for member in archive.getmembers():
            if not member.isfile():
                continue
            relative = Path(*Path(member.name).parts[1:])
            if relative.is_absolute() or ".." in relative.parts:
                raise ValueError("Unsafe dependency archive path")
            target = dest / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.extractfile(member) as source:
                target.write_bytes(source.read())
    print("Dependencies ready: pinned Waveshare support and LVGL 8.3.11")


if __name__ == "__main__":
    main()
