#!/usr/bin/env python3
"""Windows/macOS serial test client. Requires pyserial; optional Tk window.

Remote mode validates the host's pinned TLS certificate BEFORE sending any data.
Pairing capability lives only in memory; it can send key events, never arbitrary
prompts, commands, saved-dot changes, or cancellation requests.
"""
import argparse
import hashlib
import http.client
import json
from pathlib import Path
import queue
import re
import ssl
import threading
import time
import uuid


class Link:
    def __init__(self, host=None, port=None, fingerprint=None, data=None):
        self.remote = host is not None
        if self.remote:
            if not fingerprint or not re.fullmatch('[a-f0-9]{64}', fingerprint):
                raise ValueError('Remote keypad requires a SHA-256 certificate fingerprint')
            self.host, self.port, self.fingerprint = host, port, fingerprint
            self.token = None
        else:
            from dotlet import data_dir
            manifest = json.loads(((data or data_dir()) / 'service.json').read_text())
            self.host, self.port, self.token = '127.0.0.1', manifest['port'], manifest['token']

    def call(self, path, body=None):
        if self.remote:
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            context.minimum_version = ssl.TLSVersion.TLSv1_2
            conn = http.client.HTTPSConnection(self.host, self.port, context=context, timeout=3)
            conn.connect()
            if hashlib.sha256(conn.sock.getpeercert(binary_form=True)).hexdigest() != self.fingerprint:
                conn.close()
                raise ValueError('Host certificate changed. Re-pair with the Mac.')
        else:
            conn = http.client.HTTPConnection(self.host, self.port, timeout=3)
        try:
            headers = {'Content-Type': 'application/json'}
            if self.token:
                headers['Authorization'] = 'Bearer ' + self.token
            conn.request('GET' if body is None else 'POST', path,
                         None if body is None else json.dumps(body), headers)
            reply = conn.getresponse()
            result = json.loads(reply.read())
            if reply.status != 200:
                raise ValueError(result.get('error', 'Connection failed'))
            return result
        finally:
            conn.close()

    def pair(self):
        if self.remote and self.token is None:
            self.token = self.call('/pair', {})['token']


def monitor(args, messages, stopped):
    import serial
    link = Link(args.host, args.port, args.fingerprint, args.data)
    try:
        link.pair()
        with serial.Serial(args.serial, 115200, timeout=0.25, write_timeout=1) as device:
            device.reset_input_buffer()
            device.write(b'STATUS\n')
            # No buffered DOWN can trigger work. Wait for an observed released state.
            messages.put(('status', 'Release all keys to arm the keypad…'))
            ready = False
            deadline = time.monotonic() + 30
            while not stopped.is_set() and time.monotonic() < deadline:
                line = device.readline().decode('utf-8', 'replace').strip()
                if line.startswith('C6_KEY_PRESS_TEST v1 ') and 'running=1 initialized=1 down=0x00000000 ' in line:
                    ready = True
                    break
                if not line:
                    device.write(b'STATUS\n')
            if not ready:
                raise ValueError('No released keypad status. Check COM port and release all keys, then reconnect.')
            device.reset_input_buffer()
            session, seq = uuid.uuid4().hex, 0
            link.call('/connect', {'session': session})
            messages.put(('status', f'{args.serial} connected. Press the assigned OpenAI key to run your saved dot.'))
            last_poll = 0
            while not stopped.is_set():
                line = device.readline().decode('utf-8', 'replace').strip()
                if re.fullmatch(r'KEY row=[1-5] col=[1-6] led=\d+ (DOWN|UP) tested=\d+/30', line):
                    seq += 1
                    # Send once only. If delivery fails, stop; never replay a press.
                    result = link.call('/key', {'session': session, 'seq': seq, 'line': line})
                    messages.put(('event', line + ' → ' + ('running saved dot' if result.get('accepted') else result.get('reason', 'ignored'))))
                if time.monotonic() - last_poll > 1:
                    if not link.remote:
                        link.call('/heartbeat', {'session': session})
                    state = link.call('/state')
                    messages.put(('state', state))
                    last_poll = time.monotonic()
    except Exception as error:
        messages.put(('error', str(error)))
    finally:
        messages.put(('stopped', 'Disconnected. Reconnect to accept fresh presses.'))


def gui(args):
    import tkinter as tk
    from tkinter import ttk
    root = tk.Tk()
    root.title('Open.Dotlet · Windows test')
    root.geometry('840x690')
    root.configure(bg='#FBF7F0')
    style = ttk.Style()
    style.configure('TFrame', background='#FBF7F0')
    style.configure('TLabel', background='#FBF7F0', foreground='#14110F', font=('Segoe UI', 11))
    frame = ttk.Frame(root, padding=24)
    frame.pack(fill='both', expand=True)
    ttk.Label(frame, text='Open.Dotlet', font=('Segoe UI', 24, 'bold')).pack(anchor='w')
    ttk.Label(frame, text='One dot. One saved prompt.').pack(anchor='w', pady=(0, 16))
    status = tk.StringVar(value='Disconnected')
    ttk.Label(frame, textvariable=status, wraplength=760).pack(anchor='w', pady=8)
    body = ttk.Frame(frame)
    body.pack(fill='both', expand=True)
    grid = ttk.Frame(body)
    grid.pack(side='left', anchor='nw', pady=12)
    art_root = Path(__file__).resolve().parent / 'dotlet-art'
    layout_file = art_root / 'layout.json'
    if not layout_file.exists():
        art_root = Path(__file__).resolve().parents[1] / 'assets/Peel/keypad'
        layout_file = art_root / 'layout.json'
    illustrations = {}
    if layout_file.exists():
        illustrations = {item['matrixKey']: item for item in json.loads(layout_file.read_text())['keys']}
    grid.configure(style='Keypad.TFrame')
    style.configure('Keypad.TFrame', background='#111519')
    logo_images = {}
    logo_file = art_root / 'openai-logo.png'
    if logo_file.exists():
        source = tk.PhotoImage(file=str(logo_file)).subsample(8, 8)
        width, height = source.width(), source.height()
        for kind in ('white-logo', 'black-logo', 'embossed-logo'):
            logo = tk.PhotoImage(width=width, height=height)
            for y in range(height):
                for x in range(width):
                    if (x-width/2)**2 + (y-height/2)**2 > (min(width,height)/2-1)**2:
                        continue
                    pixel = source.get(x, y)
                    if isinstance(pixel, str):
                        pixel = tuple(map(int, pixel.split()))
                    r, g, b = pixel[:3]
                    if kind == 'white-logo':
                        r, g, b = 255-r, 255-g, 255-b
                    elif kind == 'embossed-logo':
                        r, g, b = (55 + r//10, 60 + g//10, 66 + b//10)
                    logo.put('#%02x%02x%02x' % (r,g,b), (x,y))
            logo_images[kind] = logo
    cells = {}
    for row in range(5):
        for col in range(6):
            cell = tk.Canvas(grid, width=76, height=64, bg='#111519', highlightthickness=0)
            cell.grid(row=4-row, column=5-col, padx=3, pady=3)
            cells[(row + 1, col + 1)] = cell
    def draw_key(position, cell, dot):
        cell.delete('all')
        number = (position[0]-1)*6 + position[1]
        art = illustrations.get(number, {'kind':'blank','color':'252A30','name':'Key','leftEye':'','rightEye':''})
        if dot:
            cell.create_rectangle(8, 2, 104, 92, outline='#FF5C39', width=2)
        kind, color = art['kind'], '#'+art['color']
        if kind in ('blank','embossed-logo'):
            cell.create_rectangle(23, 10, 89, 76, fill=color, outline='#46505A', width=1)
        else:
            cell.create_oval(21, 10, 91, 80, fill='#050709', outline='')
            cell.create_oval(21, 7, 91, 77, fill=color, outline='#73777A', width=1)
        if kind in logo_images:
            cell.create_image(56, 42, image=logo_images[kind])
        elif kind == 'face':
            for x, eye in ((42,art['leftEye']),(70,art['rightEye'])):
                cell.create_text(x, 43, text=eye, fill='#15191C', font=('Segoe UI', 13, 'bold'))
        if dot:
            cell.create_text(56, 86, text=dot['name'], fill='#FBF7F0', font=('Segoe UI', 7))
        cell.scale('all', 0, 0, 0.67, 0.67)
    hint = tk.StringVar(value='Codex · Read-only · Waiting for saved dots…')
    ttk.Label(frame, textvariable=hint).pack(before=body, anchor='w', pady=8)
    text = tk.Text(body, wrap='word', width=42, height=12, font=('Segoe UI', 11), bg='white', fg='#14110F')
    messages, stopped = queue.Queue(), threading.Event()
    worker = None
    def connect():
        nonlocal worker
        if worker and worker.is_alive():
            return
        stopped.clear()
        worker = threading.Thread(target=monitor, args=(args, messages, stopped), daemon=True)
        worker.start()
    controls = ttk.Frame(frame)
    controls.pack(before=body, fill='x', side='bottom', pady=(12, 0))
    ttk.Button(controls, text='Connect keypad', command=connect).pack(side='left')
    ttk.Button(controls, text='Disconnect', command=stopped.set).pack(side='left', padx=8)
    rotated = True
    def rotate():
        nonlocal rotated
        rotated = not rotated
        for (row, col), cell in cells.items():
            cell.grid_configure(row=5-row if rotated else row-1, column=6-col if rotated else col-1)
    ttk.Button(controls, text='Rotate view', command=rotate).pack(side='left', padx=8)
    text.pack(side='left', fill='both', expand=True, padx=(16,0), pady=12)
    if __import__('os').name == 'nt':
        root.state('zoomed')
    last = ''
    last_mapping = None
    def poll():
        nonlocal last, last_mapping
        while not messages.empty():
            kind, value = messages.get_nowait()
            if kind == 'state':
                assigned = {(d['row'], d['col']): d for d in value['dots']}
                mapping = json.dumps(value['dots'], sort_keys=True)
                if mapping != last_mapping:
                    for position, cell in cells.items():
                        draw_key(position, cell, assigned.get(position))
                    last_mapping = mapping
                hint.set('Codex · Read-only · ' + ', '.join(f"Row {d['row']} / Column {d['col']}: {d['name']}" for d in value['dots']))
                job = value.get('job')
                if job:
                    rendered = f"{job['name']} · {job['status']}\n\n{job.get('result') or job.get('error') or 'Codex is reading the project…'}"
                    if rendered != last:
                        text.delete('1.0', 'end')
                        text.insert('end', rendered)
                        last = rendered
            else:
                status.set(value)
        root.after(150, poll)
    root.protocol('WM_DELETE_WINDOW', lambda: (stopped.set(), root.destroy()))
    connect()
    poll()
    root.mainloop()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', required=True, help='COM5 or /dev/cu.usbmodem…')
    parser.add_argument('--host')
    parser.add_argument('--port', type=int, default=18766)
    parser.add_argument('--fingerprint')
    parser.add_argument('--data', type=Path)
    parser.add_argument('--gui', action='store_true')
    args = parser.parse_args()
    if args.gui:
        gui(args)
        return
    messages, stopped = queue.Queue(), threading.Event()
    threading.Thread(target=monitor, args=(args, messages, stopped), daemon=True).start()
    try:
        while True:
            kind, value = messages.get()
            if kind == 'state':
                job = value.get('job')
                if job:
                    print(json.dumps(job, ensure_ascii=False), flush=True)
            else:
                print(value, flush=True)
            if kind == 'stopped':
                break
    except KeyboardInterrupt:
        stopped.set()


if __name__ == '__main__':
    main()
