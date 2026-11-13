import http.client
import json
from pathlib import Path
import secrets
import sys
import threading
import time
from http.server import ThreadingHTTPServer

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import dotlet
import dotlet_runtime as runtime


@pytest.fixture
def running(tmp_path):
    project = tmp_path / 'project'; project.mkdir()
    (project / 'README.md').write_text('A clean example project.')
    fake = tmp_path / 'fake_codex.py'
    fake.write_text('''import sys,json
assert '--sandbox' in sys.argv and sys.argv[sys.argv.index('--sandbox')+1]=='read-only'
assert '--ignore-user-config' in sys.argv and '--ignore-rules' in sys.argv
assert sys.stdin.read().strip()
print(json.dumps({'type':'thread.started','thread_id':'fixture'}))
print(json.dumps({'type':'item.completed','item':{'type':'agent_message','text':'Verified portable result'}}))
print(json.dumps({'type':'turn.completed'}))
''')
    root = tmp_path / 'data'
    host, api, lock = runtime.start_host(root, project, [sys.executable, str(fake)])
    yield host, api, root
    host.device_manager.close(); host.cancel(); api.shutdown(); api.server_close(); lock.close()


def call_ui(server, path, token=None, body=None, origin=None, host_header=None):
    c = http.client.HTTPConnection('127.0.0.1', server.server_port, timeout=5)
    headers = {'Host': host_header or f'127.0.0.1:{server.server_port}'}
    if token: headers['Authorization'] = 'Bearer ' + token
    if origin: headers['Origin'] = origin
    if body is not None: headers['Content-Type'] = 'application/json'
    c.request('GET' if body is None else 'POST', path, json.dumps(body) if body is not None else None, headers)
    r=c.getresponse(); status=r.status; payload=r.read(); c.close()
    return status,payload


def test_portable_saved_task_without_checkout(running):
    host, api, root = running
    state=dotlet.request('/state',root=root)
    assert state['runtime']['portable']
    assert (state['dots'][0]['row'],state['dots'][0]['col'])==(5,6)
    job=dotlet.request('/run',{'id':'project-summary'},root)
    deadline=time.monotonic()+8
    while time.monotonic()<deadline:
        latest=dotlet.request('/state',root=root)['job']
        if latest['status']!='running':break
        time.sleep(.05)
    assert latest['id']==job['id'] and latest['status']=='completed'
    assert latest['result']=='Verified portable result'
    assert (Path(state['dots'][0]['workspace'])/'README.md').read_text()=='A clean example project.'


def test_browser_capability_origin_and_rebinding(running):
    host, api, root=running
    token=secrets.token_urlsafe(32)
    assets=Path(__file__).resolve().parents[1]/'desktop-ui'
    ui=ThreadingHTTPServer(('127.0.0.1',0),runtime.ui_handler(root,assets,token))
    threading.Thread(target=ui.serve_forever,daemon=True).start()
    try:
        assert call_ui(ui,'/')[0]==200
        assert call_ui(ui,'/api/state')[0]==401
        assert call_ui(ui,'/api/state','wrong')[0]==401
        assert call_ui(ui,'/api/state',token,origin='https://evil.example')[0]==403
        assert call_ui(ui,'/api/state',token,host_header='evil.example')[0]==403
        assert call_ui(ui,'/api/state',token)[0]==200
        assert call_ui(ui,'/api/dots',token,{'bad':'config'})[0]==400
        assert call_ui(ui,'/api/serial',token,{'port':'not-a-device'})[0]==400
    finally:
        ui.shutdown();ui.server_close()


def test_existing_mapping_preserved(tmp_path):
    project=tmp_path/'project';project.mkdir();root=tmp_path/'data'
    first=dotlet.Host(root,project)
    assert first.config['dots'][0]['row']==1
    host,api,lock=runtime.start_host(root,project)
    try: assert host.config['dots'][0]['row']==1
    finally:host.device_manager.close();api.shutdown();api.server_close();lock.close()


def test_missing_codex_is_actionable(tmp_path,monkeypatch):
    project=tmp_path/'project';project.mkdir()
    monkeypatch.setattr(dotlet,'codex_command',lambda:[])
    host=dotlet.Host(tmp_path/'data',project)
    host.run('project-summary');host.worker.join(timeout=5)
    assert host.job['status']=='failed'
    assert 'Install Codex CLI' in host.job['error']
