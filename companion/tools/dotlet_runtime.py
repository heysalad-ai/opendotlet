#!/usr/bin/env python3
"""Portable Open.Dotlet runtime. Bundled Python; user-owned Codex sign-in."""
import argparse
import json
import os
from pathlib import Path
import queue
import secrets
import signal
import threading
from types import SimpleNamespace
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import dotlet
import dotlet_device


def resources():
    import sys
    return Path(getattr(sys, '_MEIPASS', Path(__file__).resolve().parent))


class Devices:
    def __init__(self, host, root):
        self.host, self.root = host, root
        self.stopped, self.worker = threading.Event(), None
        self.port, self.message = '', 'Choose a USB port to connect your keypad.'
        self.messages = queue.Queue()
        self.lock = threading.Lock()
        threading.Thread(target=self.drain, daemon=True).start()

    def ports(self):
        from serial.tools import list_ports
        return {'ports': [{'port': p.device, 'name': p.description} for p in list_ports.comports()],
                'selected': self.port, 'message': self.message}

    def select(self, port):
        if not isinstance(port, str):
            raise ValueError('Choose a USB port')
        with self.lock:
            if port and port not in [p['port'] for p in self.ports()['ports']]:
                raise ValueError('USB port is no longer available. Refresh and reconnect.')
            self.stopped.set()
            if self.worker:
                self.worker.join(timeout=6)
                if self.worker.is_alive():
                    raise ValueError('The previous USB connection is still stopping. Retry shortly.')
            self.host.session = None
            self.host.device_seen = 0
            self.port = port
            if not port:
                self.message = 'Disconnected'
                return self.ports()
            self.stopped = threading.Event()
            args = SimpleNamespace(serial=port, host=None, port=None, fingerprint=None, data=self.root)
            self.worker = threading.Thread(target=dotlet_device.monitor,
                                           args=(args, self.messages, self.stopped), daemon=True)
            self.worker.start()
            return self.ports()

    def drain(self):
        while True:
            kind, value = self.messages.get()
            if kind in ('status', 'error', 'stopped'):
                self.message = value

    def close(self):
        self.stopped.set()
        if self.worker:
            self.worker.join(timeout=6)


def ui_handler(root, assets, capability):
    class UI(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def output(self, code, content, kind='application/json'):
            if not isinstance(content, bytes):
                content = json.dumps(content).encode()
            self.send_response(code)
            self.send_header('Content-Type', kind)
            self.send_header('Content-Length', str(len(content)))
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Referrer-Policy', 'no-referrer')
            self.send_header('Content-Security-Policy', "default-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self'; script-src 'self'; font-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'")
            self.end_headers()
            self.wfile.write(content)

        def do_GET(self):
            self.dispatch()

        def do_POST(self):
            self.dispatch()

        def dispatch(self):
            expected = f'127.0.0.1:{self.server.server_port}'
            if self.headers.get('Host') != expected or self.headers.get('Origin') not in (None, 'http://' + expected):
                return self.output(403, {'error': 'This companion only accepts its own local window.'})
            static = {'/': ('index.html', 'text/html; charset=utf-8'),
                      '/app.js': ('app.js', 'text/javascript'), '/style.css': ('style.css', 'text/css'),
                      '/layout.json': ('layout.json', 'application/json'),
                      '/openai-logo.png': ('openai-logo.png', 'image/png'),
                      '/Nunito-Black.ttf': ('Nunito-Black.ttf', 'font/ttf')}
            if self.path in static and self.command == 'GET':
                name, kind = static[self.path]
                return self.output(200, (assets / name).read_bytes(), kind)
            if not secrets.compare_digest(self.headers.get('Authorization', ''), 'Bearer ' + capability):
                return self.output(401, {'error': 'Open this companion using Start OpenDotlet again.'})
            paths = {'/api/state': '/state', '/api/ports': '/ports', '/api/run': '/run',
                     '/api/dots': '/dots', '/api/cancel': '/cancel', '/api/serial': '/serial',
                     '/api/enabled': '/enabled', '/api/learn': '/learn'}
            route = paths.get(self.path)
            if not route or (self.command == 'GET' and self.path not in ('/api/state', '/api/ports')):
                return self.output(404, {'error': 'Unknown action'})
            try:
                body = None
                if self.command == 'POST':
                    if self.path in ('/api/state', '/api/ports'):
                        raise ValueError('This action is read-only')
                    length = int(self.headers.get('Content-Length', '0'))
                    if not 0 <= length <= 16384:
                        raise ValueError('Request too large')
                    body = json.loads(self.rfile.read(length) or b'{}')
                self.output(200, dotlet.request(route, body, root))
            except (OSError, ValueError, TypeError) as error:
                self.output(400, {'error': str(error)})
    return UI


def default_workspace():
    folder = Path.home() / 'Documents/OpenDotlet'
    folder.mkdir(parents=True, exist_ok=True)
    example = folder / 'README.md'
    if not example.exists():
        example.write_text('# My Open.Dotlet project\n\nAssign a saved prompt to a dotlet, then run it in the app or press its USB key.\nChoose your own project folder when you are ready.\n', encoding='utf-8')
    return folder


def start_host(root, workspace, executable=None):
    root.mkdir(parents=True, exist_ok=True, mode=0o700)
    lock = (root / 'host.lock').open('a+')
    try:
        if os.name == 'nt':
            import msvcrt
            lock.write('0'); lock.flush(); lock.seek(0)
            msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        else:
            import fcntl
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        lock.close()
        raise ValueError('Open.Dotlet is already running. Use its existing window.') from None
    fresh = not (root / 'dots.json').exists()
    host = dotlet.Host(root, workspace, executable)
    # A new download starts on the photographed white-logo key, not on a private mapping.
    if fresh:
        host.config['dots'][0].update(row=5, col=6)
        host.save(host.config)
    host.device_manager = Devices(host, root)
    token = secrets.token_urlsafe(32)
    api = ThreadingHTTPServer(('127.0.0.1', 0), dotlet.handler(host, token))
    dotlet.write_private(root / 'service.json', {'version': 1, 'pid': os.getpid(), 'port': api.server_port, 'token': token})
    threading.Thread(target=api.serve_forever, daemon=True).start()
    return host, api, lock


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', nargs='?', choices=['desktop', 'serve'], default='desktop')
    parser.add_argument('--data', type=Path, default=dotlet.data_dir())
    parser.add_argument('--workspace', type=Path)
    parser.add_argument('--no-browser', action='store_true', help='Start without opening the browser (verification only)')
    args = parser.parse_args()
    workspace = args.workspace or default_workspace()
    host, api, lock = start_host(args.data, workspace)
    stopped = threading.Event()
    ui = None
    def stop(*_):
        stopped.set()
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        if args.mode == 'desktop':
            token = secrets.token_urlsafe(32)
            assets = resources() / 'desktop-ui'
            ui = ThreadingHTTPServer(('127.0.0.1', 0), ui_handler(args.data, assets, token))
            threading.Thread(target=ui.serve_forever, daemon=True).start()
            url = f'http://127.0.0.1:{ui.server_port}/#{token}'
            if not args.no_browser:
                webbrowser.open(url)
            print('Open.Dotlet is running locally. Keep this window open; close it to stop.', flush=True)
        while not stopped.wait(0.5):
            pass
    finally:
        host.device_manager.close()
        host.cancel()
        for server in (ui, api):
            if server:
                server.shutdown(); server.server_close()
        (args.data / 'service.json').unlink(missing_ok=True)
        lock.close()


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError) as error:
        print('Open.Dotlet: ' + str(error))
        raise SystemExit(1) from None
