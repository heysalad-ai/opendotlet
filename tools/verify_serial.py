"""Exercise gallery navigation over USB serial; leaves automatic playback running."""
import argparse
import re
import time
from pathlib import Path

import serial


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', required=True)
    parser.add_argument('--log', help='Optional local serial log path; do not commit device logs')
    args = parser.parse_args()
    port = serial.Serial()
    port.port = args.port
    port.baudrate = 115200
    port.timeout = 0.05
    port.dtr = False
    port.rts = False
    chunks = []

    def capture(seconds):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            data = port.read(8192)
            if data:
                chunks.append(data)

    port.open()
    try:
        capture(5)
        port.write(b'PAUSE\n')
        capture(0.3)
        for _ in range(28):
            port.write(b'NEXT\n')
            capture(0.2)
        port.write(b'STATUS\n')
        capture(0.3)
        port.write(b'AUTO\n')
        capture(15)
    finally:
        port.close()
    output = b''.join(chunks).decode('utf-8', errors='replace')
    if args.log:
        Path(args.log).write_text(output)
    indices = {int(value) for value in re.findall(r'SHOW (\d+)/28', output)}
    assert indices == set(range(1, 29)), f'Missing views: {set(range(1, 29)) - indices}'
    assert 'READY resolution=412x412 images=28' in output, 'Boot READY not captured'
    assert not re.search(r'Guru Meditation|assert failed|abort\(\)|panic', output, re.I)
    assert 'auto=0' in output, 'Pause not confirmed'
    # Two automatic advances must follow the final explicit AUTO command.
    status = output.rfind('STATUS index=')
    assert len(re.findall(r'SHOW \d+/28', output[status:])) >= 3, 'Auto playback not observed'
    print('PASS: READY, all 28 views, pause, wraparound, automatic playback, no captured panic')


if __name__ == '__main__':
    main()
