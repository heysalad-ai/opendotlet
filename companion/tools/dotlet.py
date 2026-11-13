#!/usr/bin/env python3
"""Open.Dotlet shared saved-action host and CLI. Python 3.10+, stdlib only.

The native app, CLI and extensions all call this loopback service. A separate,
explicitly enabled TLS listener accepts paired keypad events and a fixed Project
summary action, never arbitrary prompts or shell commands.
"""
import argparse
import collections
import hashlib
import http.client
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import signal
import ssl
import subprocess
import sys
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PROMPT = 'Summarise the current project and suggest three next steps; do not change files or run external actions'
KEY = re.compile(r'^KEY row=([1-5]) col=([1-6]) led=(\d+) (DOWN|UP) tested=\d+/30$')


def codex_command():
    """Find the CLI from Finder/Explorer as well as a terminal's PATH."""
    candidates = [shutil.which('codex'), str(Path.home() / '.local/bin/codex'),
                  '/opt/homebrew/bin/codex', '/usr/local/bin/codex',
                  str(Path.home() / '.local/bin/codex.exe')]
    for candidate in candidates:
        if not candidate or not Path(candidate).is_file():
            continue
        if Path(candidate).suffix.lower() in ('.cmd', '.bat'):
            script = Path(candidate).parent / 'node_modules/@openai/codex/bin/codex.js'
            node = shutil.which('node')
            if node and script.is_file():
                return [node, str(script)]
            continue
        return [candidate]
    return []


def data_dir():
    if sys.platform == 'darwin':
        return Path.home() / 'Library/Application Support/OpenDotlet/Keyboard'
    return Path(os.environ.get('LOCALAPPDATA', str(Path.home() / '.local/share'))) / 'OpenDotlet/Keyboard'


def write_private(path, value):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    temp = path.with_name(path.name + '.' + uuid.uuid4().hex + '.tmp')
    fd = os.open(temp, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    with os.fdopen(fd, 'w', encoding='utf-8') as f:
        json.dump(value, f, ensure_ascii=False, indent=2)
    os.replace(temp, path)


def parse_key(line):
    m = KEY.fullmatch(line.strip())
    if not m:
        return None
    row, col, led = map(int, m.group(1, 2, 3))
    expected = (row - 1) * 6 + (col - 1 if row % 2 else 6 - col)
    if led != expected:
        return None
    return row, col, m.group(4)


class Host:
    def __init__(self, root, workspace, executable=None):
        self.root = root
        self.lock = threading.RLock()
        self.config_file = root / 'dots.json'
        if self.config_file.exists():
            self.config = json.loads(self.config_file.read_text())
            self.validate(self.config)
        else:
            self.config = {'version': 1, 'dots': [{'id': 'project-summary', 'row': 1, 'col': 1,
                           'name': 'Project summary', 'prompt': PROMPT, 'workspace': str(Path(workspace).resolve())}]}
            write_private(self.config_file, self.config)
        self.executable = executable
        self.device_manager = None
        self.job = None
        self.process = None
        self.worker = None
        self.held = set()
        self.session = None
        self.sequence = -1
        self.device = 'Disconnected'
        self.device_seen = 0
        self.last_event = ''
        self.enabled = True
        self.learning = None
        saved = json.loads((root / 'runs.json').read_text()) if (root / 'runs.json').exists() else []
        for item in saved:
            if item.get('status') == 'running':
                item['status'] = 'interrupted'
                item['error'] = 'Host stopped before a completed response. Press again to start a new run.'
        self.history = collections.deque(saved[:20], maxlen=20)
        self.job = self.history[0] if self.history else None
        self.pair_ip = None
        self.pair_deadline = 0
        self.remote_token = secrets.token_urlsafe(32)
        self.remote_address = None

    @staticmethod
    def validate(config):
        if config.get('version') != 1 or not isinstance(config.get('dots'), list):
            raise ValueError('Unsupported dots configuration')
        ids, positions = set(), set()
        for dot in config['dots']:
            if not re.fullmatch(r'[a-z0-9-]{1,60}', dot['id']) or dot['id'] in ids:
                raise ValueError('Invalid or repeated dot ID')
            position = (dot['row'], dot['col'])
            if position in positions or not (1 <= position[0] <= 5 and 1 <= position[1] <= 6):
                raise ValueError('Invalid or repeated key position')
            if not dot['name'].strip() or not (1 <= len(dot['prompt'].strip()) <= 4000):
                raise ValueError('A dot needs a name and prompt (up to 4000 characters)')
            if not Path(dot['workspace']).is_dir():
                raise ValueError('Workspace folder does not exist')
            ids.add(dot['id'])
            positions.add(position)

    def snapshot(self):
        with self.lock:
            return {'version': 1, 'dots': self.config['dots'], 'job': self.job,
                    'runtime': {'codex_available': bool(self.executable or codex_command()),
                                'portable': self.device_manager is not None},
                    'device': self.device if time.monotonic() - self.device_seen < 6 else 'Disconnected', 'last_event': self.last_event, 'enabled': self.enabled,
                    'history': list(self.history), 'learning': self.learning, 'remote_address': self.remote_address}

    def save(self, config):
        self.validate(config)
        with self.lock:
            if self.job and self.job['status'] == 'running':
                raise ValueError('Wait for the current run before changing dots')
            write_private(self.config_file, config)
            self.config = config
        return self.snapshot()

    def connect(self, session):
        if not isinstance(session, str) or not re.fullmatch(r'[a-f0-9]{32}', session):
            raise ValueError('Invalid device session')
        with self.lock:
            self.session, self.sequence = session, -1
            self.held.clear()
            self.device = 'Connected · waiting for a fresh press'
            self.device_seen = time.monotonic()
        return {'connected': True}

    def heartbeat(self, session):
        with self.lock:
            if session != self.session or self.session is None:
                raise ValueError('Reconnect the keypad client')
            self.device_seen = time.monotonic()
        return {'connected': True}

    def key(self, body):
        with self.lock:
            if body.get('session') != self.session or self.session is None:
                raise ValueError('Reconnect the keypad client')
            seq = body.get('seq')
            if not isinstance(seq, int) or seq <= self.sequence:
                return {'accepted': False, 'reason': 'duplicate event'}
            # Set the sequence before dispatch. Events are never queued or retried.
            self.sequence = seq
            event = parse_key(body.get('line', ''))
            if event is None:
                raise ValueError('Invalid keypad event')
            row, col, edge = event
            self.device = 'Connected'
            self.device_seen = time.monotonic()
            self.last_event = f'Row {row} · Column {col} · {edge}'
            position = row, col
            if edge == 'UP':
                self.held.discard(position)
                return {'accepted': False, 'reason': 'released'}
            if position in self.held:
                return {'accepted': False, 'reason': 'held'}
            self.held.add(position)
            if not self.enabled:
                return {'accepted': False, 'reason': 'paused'}
            if self.job and self.job['status'] == 'running':
                return {'accepted': False, 'reason': 'busy'}
            if self.learning:
                learned = json.loads(json.dumps(self.config))
                dot = next(d for d in learned['dots'] if d['id'] == self.learning)
                if any((d['row'], d['col']) == position and d['id'] != self.learning for d in learned['dots']):
                    return {'accepted': False, 'reason': 'key already assigned'}
                dot['row'], dot['col'] = position
                self.save(learned)
                self.learning = None
            dot = next((d for d in self.config['dots'] if (d['row'], d['col']) == position), None)
            if dot is None:
                return {'accepted': False, 'reason': 'unassigned'}
            if self.job and self.job['status'] == 'running':
                return {'accepted': False, 'reason': 'busy'}
            return {'accepted': True, 'job': self.run(dot['id'], 'physical keypad')}

    def learn(self, dot_id):
        with self.lock:
            if self.job and self.job['status'] == 'running':
                raise ValueError('Wait for the current run before learning a key')
            if not any(d['id'] == dot_id for d in self.config['dots']):
                raise ValueError('Unknown dot')
            self.learning = dot_id
        return {'learning': dot_id}

    def run(self, dot_id, source='manual'):
        with self.lock:
            if self.process is not None or (self.job and self.job['status'] == 'running'):
                raise ValueError('A dot is already running or stopping')
            dot = next((d.copy() for d in self.config['dots'] if d['id'] == dot_id), None)
            if dot is None:
                raise ValueError('Unknown dot')
            if not Path(dot['workspace']).is_dir():
                raise ValueError('Workspace folder no longer exists')
            job = {'id': uuid.uuid4().hex, 'dot_id': dot_id, 'name': dot['name'], 'status': 'running',
                   'source': source, 'row': dot['row'], 'col': dot['col'], 'started': time.time(), 'result': '', 'error': '', 'thread_id': ''}
            self.job = job
            self.history.appendleft(job)
            self.persist()
            self.worker = threading.Thread(target=self.execute, args=(dot, job), daemon=True)
            self.worker.start()
            return job.copy()

    def persist(self):
        write_private(self.root / 'runs.json', list(self.history))

    def execute(self, dot, job):
        proc = None
        try:
            env = os.environ.copy()
            for key in ('OPENAI_API_KEY', 'CODEX_API_KEY', 'CODEX_THREAD_ID'):
                env.pop(key, None)
            # Ignore user config/rules for this bounded read-only action: no MCPs,
            # hooks, inherited writable permissions or shell/network overrides.
            command = (self.executable if isinstance(self.executable, list) else [self.executable]) if self.executable else codex_command()
            if not command:
                raise ValueError('Install Codex CLI, run codex login in a terminal, then retry. Setup: https://learn.chatgpt.com/docs/codex/cli')
            args = command + ['exec', '--ignore-user-config', '--ignore-rules',
                    '--sandbox', 'read-only', '--json', '--color', 'never',
                    '--cd', dot['workspace'], '--skip-git-repo-check', '-']
            kwargs = {'start_new_session': True} if os.name != 'nt' else {'creationflags': subprocess.CREATE_NEW_PROCESS_GROUP}
            with self.lock:
                if job['status'] != 'running':
                    return
                proc = subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                        stderr=subprocess.DEVNULL, text=True, encoding='utf-8', env=env, **kwargs)
                self.process = proc
            proc.stdin.write(dot['prompt'] + '\n')
            proc.stdin.close()
            completed = False
            for line in proc.stdout:
                try:
                    event = json.loads(line)
                except ValueError:
                    continue
                with self.lock:
                    kind = event.get('type')
                    if kind == 'thread.started':
                        job['thread_id'] = event.get('thread_id', '')
                    elif kind == 'item.completed' and event.get('item', {}).get('type') == 'agent_message':
                        job['result'] = event['item'].get('text', '')[-100000:]
                    elif kind == 'turn.completed':
                        completed = True
                    elif kind in ('turn.failed', 'error'):
                        error = event.get('error', event)
                        job['error'] = str(error.get('message', 'Codex run failed'))[:2000]
            code = proc.wait()
            with self.lock:
                if job['status'] == 'running':
                    job['status'] = 'completed' if code == 0 and completed and job['result'] and not job['error'] else 'failed'
                    if job['status'] == 'failed' and not job['error']:
                        job['error'] = f'Codex exited without a completed response (exit {code}). Check codex login status.'
        except Exception as error:
            with self.lock:
                if job['status'] == 'running':
                    job['status'], job['error'] = 'failed', str(error)[:2000]
        finally:
            with self.lock:
                if proc is not None:
                    if proc.stdout is not None:
                        proc.stdout.close()
                    if proc.stdin is not None:
                        proc.stdin.close()
                if self.process is proc:
                    self.process = None
                job['finished'] = time.time()
                self.persist()

    def cancel(self):
        with self.lock:
            if self.job and self.job['status'] == 'running':
                self.job['status'] = 'cancelled'
                if self.process and self.process.poll() is None:
                    if os.name == 'nt':
                        subprocess.run(['taskkill', '/PID', str(self.process.pid), '/T', '/F'], capture_output=True)
                    else:
                        os.killpg(self.process.pid, signal.SIGTERM)
                self.persist()
        return self.snapshot()


def handler(host, token, remote=False):
    class API(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def reply(self, status, value):
            payload = json.dumps(value).encode()
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(payload)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(payload)

        def setup(self):
            super().setup()
            self.connection.settimeout(5)

        def do_GET(self):
            self.dispatch()

        def do_POST(self):
            self.dispatch()

        def dispatch(self):
            try:
                if self.headers.get('Origin') or (remote and self.client_address[0] != host.pair_ip):
                    return self.reply(403, {'error': 'Origin or peer not allowed'})
                if remote and self.path == '/pair' and self.command == 'POST':
                    with host.lock:
                        if time.monotonic() > host.pair_deadline:
                            return self.reply(403, {'error': 'Pairing window closed'})
                        host.pair_deadline = 0
                        return self.reply(200, {'token': host.remote_token})
                supplied = self.headers.get('Authorization', '')
                if not secrets.compare_digest(supplied, 'Bearer ' + token):
                    return self.reply(401, {'error': 'Pair or connect to OpenDotlet first'})
                if self.command == 'GET' and self.path == '/state':
                    if remote and host.session:
                        host.device_seen = time.monotonic()
                    return self.reply(200, host.snapshot())
                if not remote and self.command == 'GET' and self.path == '/ports' and host.device_manager:
                    return self.reply(200, host.device_manager.ports())
                if remote and self.command == 'GET' and self.path == '/summary-state':
                    # Round-screen polling must not keep an unrelated keypad alive.
                    return self.reply(200, host.snapshot())
                length = int(self.headers.get('Content-Length', '0'))
                if not 0 <= length <= 16384:
                    raise ValueError('Request too large')
                body = json.loads(self.rfile.read(length) or b'{}')
                if self.command != 'POST':
                    return self.reply(404, {'error': 'Unknown route'})
                if self.path == '/connect':
                    result = host.connect(body.get('session'))
                elif not remote and self.path == '/heartbeat':
                    result = host.heartbeat(body.get('session'))
                elif self.path == '/key':
                    result = host.key(body)
                elif not remote and self.path == '/run':
                    result = host.run(body.get('id'))
                elif remote and self.path == '/run-summary':
                    # Paired screen clients can invoke only this saved binding.
                    # Busy, enabled and dispatch checks are atomic with Host.run.
                    with host.lock:
                        if not host.enabled:
                            raise ValueError('Saved actions are paused')
                        if body != {}:
                            raise ValueError('This route accepts no prompt or action parameters')
                        result = host.run('project-summary', 'physical round-screen controller')
                elif not remote and self.path == '/learn':
                    result = host.learn(body.get('id'))
                elif not remote and self.path == '/cancel':
                    result = host.cancel()
                elif not remote and self.path == '/dots':
                    result = host.save(body)
                elif not remote and self.path == '/serial' and host.device_manager:
                    result = host.device_manager.select(body.get('port'))
                elif not remote and self.path == '/pair-window':
                    if not host.pair_ip:
                        raise ValueError('Start host with --lan and --peer to enable a remote keypad')
                    host.pair_deadline = time.monotonic() + 300
                    result = {'pairing': True, 'seconds': 300}
                elif not remote and self.path == '/enabled':
                    with host.lock:
                        host.enabled = body.get('enabled') is True
                    result = host.snapshot()
                else:
                    return self.reply(404, {'error': 'Unknown route'})
                self.reply(200, result)
            except (ValueError, TypeError, KeyError) as error:
                self.reply(400, {'error': str(error)})
            except (BrokenPipeError, ConnectionResetError):
                pass
    return API


def request(path, body=None, root=None):
    manifest = json.loads(((root or data_dir()) / 'service.json').read_text())
    conn = http.client.HTTPConnection('127.0.0.1', manifest['port'], timeout=5)
    try:
        conn.request('GET' if body is None else 'POST', path,
                     None if body is None else json.dumps(body),
                     {'Authorization': 'Bearer ' + manifest['token'], 'Content-Type': 'application/json'})
        response = conn.getresponse()
        result = json.loads(response.read())
        if response.status != 200:
            raise ValueError(result.get('error', 'Request failed'))
        return result
    finally:
        conn.close()


def serve(args):
    root = args.data
    root.mkdir(parents=True, exist_ok=True, mode=0o700)
    # A process lock makes app/CLI startup races harmless. Never replace a live host.
    lock = (root / 'host.lock').open('a+')
    if os.name == 'nt':
        import msvcrt
        lock.seek(0)
        lock.write('0')
        lock.flush()
        lock.seek(0)
        msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
    else:
        import fcntl
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    settings = root / 'host-settings.json'
    if args.lan:
        write_private(settings, {'lan': args.lan, 'peer': args.peer, 'port': args.port})
    elif settings.exists():
        saved = json.loads(settings.read_text())
        args.lan, args.peer, args.port = saved['lan'], saved['peer'], saved['port']
    host = Host(root, args.workspace)
    token = secrets.token_urlsafe(32)
    server = ThreadingHTTPServer(('127.0.0.1', 0), handler(host, token))
    write_private(root / 'service.json', {'version': 1, 'pid': os.getpid(), 'port': server.server_port, 'token': token})
    def stop(*_):
        host.cancel()
        raise SystemExit(0)
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    remote = None
    if args.lan:
        try:
            # Enable only when explicitly requested. Pinned TLS, one peer, one pairing.
            cert, key = root / 'device-cert.pem', root / 'device-key.pem'
            if not cert.exists() or not key.exists():
                subprocess.run(['openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
                                '-keyout', str(key), '-out', str(cert), '-days', '30',
                                '-subj', '/CN=OpenDotlet keypad'], check=True, capture_output=True)
                os.chmod(key, 0o600)
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.minimum_version = ssl.TLSVersion.TLSv1_2
            context.load_cert_chain(cert, key)
            host.pair_ip = args.peer
            host.pair_deadline = time.monotonic() + 300
            remote = ThreadingHTTPServer((args.lan, args.port), handler(host, host.remote_token, remote=True))
            remote.socket = context.wrap_socket(remote.socket, server_side=True)
            host.remote_address = f'{args.lan}:{remote.server_port}'
            fingerprint = hashlib.sha256(ssl.PEM_cert_to_DER_cert(cert.read_text())).hexdigest()
            write_private(root / 'device-public.json', {'host': args.lan, 'port': remote.server_port, 'fingerprint': fingerprint})
            threading.Thread(target=remote.serve_forever, daemon=True).start()
        except (OSError, subprocess.SubprocessError) as error:
            print("Windows link unavailable; local dots remain available: " + str(error), file=sys.stderr)
    try:
        server.serve_forever()
    finally:
        host.cancel()
        server.server_close()
        if remote is not None:
            remote.shutdown()
            remote.server_close()
        (root / 'service.json').unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data', type=Path, default=data_dir())
    sub = parser.add_subparsers(dest='command', required=True)
    start = sub.add_parser('serve', help='Start the shared saved-dot host')
    start.add_argument('--workspace', default=str(Path(__file__).resolve().parents[1]))
    start.add_argument('--lan', help='Optional local interface for paired TLS keypad events')
    start.add_argument('--peer', help='Only this Windows IP can pair and send key events')
    start.add_argument('--port', type=int, default=18766)
    learn = sub.add_parser('learn')
    learn.add_argument('id', nargs='?', default='project-summary')
    sub.add_parser('list')
    sub.add_parser('status')
    run = sub.add_parser('run')
    run.add_argument('id', nargs='?', default='project-summary')
    run.add_argument('--wait', action='store_true')
    sub.add_parser('cancel')
    sub.add_parser('pair')
    sub.add_parser('pause')
    sub.add_parser('resume')
    args = parser.parse_args()
    try:
        if args.command == 'serve':
            if args.lan and not args.peer:
                parser.error('--lan requires --peer')
            serve(args)
            return
        route, body = '/state', None
        if args.command == 'learn':
            route, body = '/learn', {'id': args.id}
        elif args.command == 'run':
            route, body = '/run', {'id': args.id}
        elif args.command == 'pair':
            route, body = '/pair-window', {}
        elif args.command == 'cancel':
            route, body = '/cancel', {}
        elif args.command in ('pause', 'resume'):
            route, body = '/enabled', {'enabled': args.command == 'resume'}
        result = request(route, body, args.data)
        if args.command == 'list':
            result = result['dots']
        if args.command == 'run' and args.wait:
            job_id = result['id']
            while result['status'] == 'running':
                time.sleep(0.5)
                result = next(j for j in request('/state', root=args.data)['history'] if j['id'] == job_id)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        if args.command == 'run' and args.wait and result['status'] != 'completed':
            sys.exit(1)
    except (OSError, ValueError) as error:
        print('Open.Dotlet: ' + str(error), file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
