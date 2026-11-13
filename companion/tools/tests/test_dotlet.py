import http.client
import json
from pathlib import Path
import sys
import tempfile
import threading
import time
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from dotlet import Host, PROMPT, handler, parse_key
from http.server import ThreadingHTTPServer


def line(row=1, col=1, edge='DOWN'):
    led = (row - 1) * 6 + (col - 1 if row % 2 else 6 - col)
    return f'KEY row={row} col={col} led={led} {edge} tested=30/30'


class DotTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.host = Host(self.root, self.root)
        self.host.connect('a' * 32)
        self.seq = 0

    def tearDown(self):
        if self.host.worker:
            self.host.worker.join(timeout=5)
        self.temp.cleanup()

    def press(self, row=1, col=1, edge='DOWN', seq=None):
        self.seq += 1
        return self.host.key({'session': 'a' * 32, 'seq': seq if seq is not None else self.seq, 'line': line(row, col, edge)})

    def test_usb_heartbeat_keeps_only_current_session_connected(self):
        self.host.device_seen = time.monotonic() - 10
        self.assertEqual(self.host.snapshot()['device'], 'Disconnected')
        self.host.heartbeat('a' * 32)
        self.assertTrue(self.host.snapshot()['device'].startswith('Connected'))
        self.host.connect('b' * 32)
        self.host.device_seen = time.monotonic() - 10
        with self.assertRaisesRegex(ValueError, 'Reconnect'):
            self.host.heartbeat('a' * 32)
        self.assertEqual(self.host.snapshot()['device'], 'Disconnected')
        self.assertIsNone(self.host.job)

    def test_every_position_validates_its_serpentine_led(self):
        for row in range(1, 6):
            for col in range(1, 7):
                self.assertEqual(parse_key(line(row, col)), (row, col, 'DOWN'))
        for bad in ['STATUS', line().replace('led=0', 'led=1'), line().replace('row=1', 'row=6'), line() + ' junk']:
            self.assertIsNone(parse_key(bad))

    def test_one_run_per_down_release_rearms_and_29_keys_unassigned(self):
        with patch.object(self.host, 'run', return_value={'id': 'test'}) as run:
            self.assertTrue(self.press()['accepted'])
            self.assertEqual(self.press()['reason'], 'held')
            self.assertEqual(self.press(edge='UP')['reason'], 'released')
            self.assertTrue(self.press()['accepted'])
            self.assertEqual(run.call_count, 2)
            for row in range(1, 6):
                for col in range(1, 7):
                    if (row, col) != (1, 1):
                        self.assertEqual(self.press(row, col)['reason'], 'unassigned')
            self.assertEqual(run.call_count, 2)

    def test_replay_old_session_busy_and_paused_are_not_queued(self):
        with patch.object(self.host, 'run') as run:
            self.host.job = {'status': 'running'}
            self.assertEqual(self.press()['reason'], 'busy')
            self.host.job = None
            self.assertEqual(self.press()['reason'], 'held')
            self.press(edge='UP')
            self.host.enabled = False
            self.assertEqual(self.press()['reason'], 'paused')
            self.host.enabled = True
            self.assertEqual(self.press()['reason'], 'held')
            self.assertEqual(self.press(seq=1)['reason'], 'duplicate event')
            self.host.connect('b' * 32)
            with self.assertRaisesRegex(ValueError, 'Reconnect'):
                self.press()
            run.assert_not_called()

    def test_learning_binds_one_fresh_physical_press_then_runs(self):
        self.host.learn('project-summary')
        with patch.object(self.host, 'run', return_value={'id': 'learned'}) as run:
            self.press(5, 6, 'UP')
            self.assertEqual(self.host.config['dots'][0]['row'], 1)
            self.assertTrue(self.press(5, 6)['accepted'])
            self.assertEqual(len(self.host.config['dots']), 1)
            self.assertEqual((self.host.config['dots'][0]['row'], self.host.config['dots'][0]['col']), (5, 6))
            self.assertIsNone(self.host.learning)
            run.assert_called_once_with('project-summary', 'physical keypad')
            self.assertEqual(self.press(5, 6)['reason'], 'held')

    def test_config_saved_and_corrupt_existing_file_preserved(self):
        original = self.host.config
        self.assertEqual(original['dots'][0]['prompt'], PROMPT)
        copy = json.loads(json.dumps(original))
        copy['dots'][0]['name'] = 'Changed'
        self.host.save(copy)
        self.assertEqual(Host(self.root, self.root).config['dots'][0]['name'], 'Changed')
        copy['dots'].append(copy['dots'][0])
        with self.assertRaises(ValueError):
            self.host.save(copy)
        self.host.config_file.write_text('{bad')
        with self.assertRaises(ValueError):
            Host(self.root, self.root)
        self.assertEqual(self.host.config_file.read_text(), '{bad')

    def test_persisted_unfinished_job_is_interrupted_not_replayed(self):
        self.host.history.append({'id': 'old', 'status': 'running'})
        self.host.persist()
        restored = Host(self.root, self.root)
        self.assertEqual(restored.job['status'], 'interrupted')
        self.assertIsNone(restored.process)

    def fake_codex(self, body):
        path = self.root / 'codex'
        path.write_text('#!' + sys.executable + '\n' + body)
        path.chmod(0o700)
        self.host.executable = [sys.executable, str(path)]

    def wait_job(self):
        until = time.monotonic() + 5
        while self.host.job['status'] == 'running' and time.monotonic() < until:
            time.sleep(.01)
        return self.host.job

    def test_success_requires_completed_event_exit_and_final_result(self):
        self.fake_codex("import json,sys\nsys.stdin.read()\nprint(json.dumps({'type':'item.completed','item':{'type':'agent_message','text':'result'}}))\nprint(json.dumps({'type':'turn.completed'}))\n")
        self.host.run('project-summary')
        self.assertEqual(self.wait_job()['status'], 'completed')
        self.assertEqual(self.host.job['result'], 'result')
        self.fake_codex("print('not JSON')\n")
        self.host.run('project-summary')
        self.assertEqual(self.wait_job()['status'], 'failed')

    def test_failure_and_cancellation_cannot_become_success(self):
        self.fake_codex("import json\nprint(json.dumps({'type':'turn.failed','error':{'message':'Authentication required'}}))\n")
        self.host.run('project-summary')
        self.assertEqual(self.wait_job()['status'], 'failed')
        self.assertEqual(self.host.job['error'], 'Authentication required')
        self.fake_codex('import time\ntime.sleep(20)\n')
        self.host.run('project-summary')
        until = time.monotonic() + 2
        while self.host.process is None and time.monotonic() < until:
            time.sleep(.01)
        self.host.cancel()
        self.assertEqual(self.host.job['status'], 'cancelled')
        until = time.monotonic() + 2
        while self.host.process is not None and time.monotonic() < until:
            time.sleep(.01)
        self.assertIsNone(self.host.process)
        self.assertEqual(self.host.job['status'], 'cancelled')

    def test_local_auth_and_remote_route_restrictions(self):
        self.host.pair_ip = '127.0.0.1'
        self.host.pair_deadline = time.monotonic() + 5
        server = ThreadingHTTPServer(('127.0.0.1', 0), handler(self.host, 'test', remote=True))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        def call(path, token=None, origin=None):
            conn = http.client.HTTPConnection('127.0.0.1', server.server_port)
            headers = {}
            if token:
                headers['Authorization'] = 'Bearer ' + token
            if origin:
                headers['Origin'] = origin
            conn.request('POST', path, '{}', headers)
            response = conn.getresponse()
            value = response.status, json.loads(response.read())
            conn.close()
            return value
        try:
            self.assertEqual(call('/run')[0], 401)
            self.assertEqual(call('/run', 'test')[0], 404)
            self.assertEqual(call('/dots', 'test')[0], 404)
            self.assertEqual(call('/key', 'test', 'https://example.com')[0], 403)
            self.assertEqual(call('/pair')[0], 200)
            self.assertEqual(call('/pair')[0], 403)
        finally:
            server.shutdown()
            server.server_close()

    def test_paired_screen_can_only_run_fixed_summary_and_cannot_refresh_keypad(self):
        self.host.pair_ip = '127.0.0.1'
        self.host.device_seen = 0
        server = ThreadingHTTPServer(('127.0.0.1', 0), handler(self.host, 'screen-test', remote=True))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        def call(path, body=None, token='screen-test', origin=None):
            connection = http.client.HTTPConnection('127.0.0.1', server.server_port)
            headers = {'Authorization': 'Bearer ' + token}
            if origin:
                headers['Origin'] = origin
            connection.request('GET' if body is None else 'POST', path,
                               None if body is None else json.dumps(body), headers)
            response = connection.getresponse()
            result = response.status, json.loads(response.read())
            connection.close()
            return result
        try:
            with patch.object(self.host, 'run', return_value={'id': 'screen-job'}) as run:
                self.assertEqual(call('/run-summary', {}, token='wrong')[0], 401)
                self.assertEqual(call('/run-summary', {}, origin='https://example.com')[0], 403)
                self.assertEqual(call('/run-summary', {'id': 'other'})[0], 400)
                self.assertEqual(call('/run-summary', [])[0], 400)
                self.host.enabled = False
                self.assertEqual(call('/run-summary', {})[0], 400)
                run.assert_not_called()
                self.host.enabled = True
                self.assertEqual(call('/run-summary', {}), (200, {'id': 'screen-job'}))
                run.assert_called_once_with('project-summary', 'physical round-screen controller')
                self.assertEqual(call('/summary-state')[0], 200)
                self.assertEqual(self.host.device_seen, 0)
                for path in ['/run', '/cancel', '/dots', '/learn']:
                    self.assertEqual(call(path, {})[0], 404)
            self.host.pair_ip = '192.0.2.1'
            self.assertEqual(call('/summary-state')[0], 403)
        finally:
            server.shutdown()
            server.server_close()


if __name__ == '__main__':
    unittest.main()
