"""Persistent Roblox Studio MCP bridge (see README.md).

One StudioMCP.exe session is kept alive (spawning a proxy per call made Studio drop and
re-negotiate its connection), exposed on 127.0.0.1:8765:

  POST /call  {"tool": name, "args": {...}, "timeout": s, "label": str}
              -> {"text": ..., "images": [saved paths], "error": bool}
  GET  /tools -> list of tool names

Images returned by tools (screen_capture) are saved under NINJA_DUEL_SHOTS
(default: %TEMP%/ninja-duel-shots).
"""
import base64, glob, json, os, queue, subprocess, threading, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

VERSIONS = os.path.expandvars(r'%LOCALAPPDATA%\Roblox\Versions')
EXE = sorted(glob.glob(os.path.join(VERSIONS, '*', 'StudioMCP.exe')), key=os.path.getmtime)[-1]
SHOTS = os.environ.get('NINJA_DUEL_SHOTS', os.path.join(os.environ.get('TEMP', '.'), 'ninja-duel-shots'))
PORT = int(os.environ.get('NINJA_DUEL_MCP_PORT', '8765'))
os.makedirs(SHOTS, exist_ok=True)

proc = subprocess.Popen([EXE, '--stdio'], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                        stderr=subprocess.DEVNULL, bufsize=0)
pending, lock, rid = {}, threading.Lock(), [0]


def reader():
    for line in proc.stdout:
        try:
            msg = json.loads(line)
        except ValueError:
            continue
        q = pending.pop(msg.get('id'), None)
        if q:
            q.put(msg)


threading.Thread(target=reader, daemon=True).start()


def rpc(method, params=None, timeout=60, notify=False):
    msg = {'jsonrpc': '2.0', 'method': method}
    if params is not None:
        msg['params'] = params
    q = None
    with lock:
        if not notify:
            rid[0] += 1
            msg['id'] = rid[0]
            q = queue.Queue()
            pending[rid[0]] = q
        proc.stdin.write((json.dumps(msg) + '\n').encode())
        proc.stdin.flush()
    if notify:
        return None
    try:
        return q.get(timeout=timeout)
    except queue.Empty:
        return {'error': 'timeout'}


rpc('initialize', {'protocolVersion': '2024-11-05', 'capabilities': {},
                   'clientInfo': {'name': 'ninja-duel-qa', 'version': '1.0'}}, 30)
rpc('notifications/initialized', notify=True)


def call(tool, args, timeout, label):
    res = rpc('tools/call', {'name': tool, 'arguments': args}, timeout)
    r = res.get('result', res)
    texts, images = [], []
    for c in (r.get('content', []) if isinstance(r, dict) else []):
        if c.get('type') == 'image':
            ext = 'png' if 'png' in c.get('mimeType', 'png') else 'jpg'
            path = os.path.join(SHOTS, f"{label or tool}_{int(time.time() * 1000)}.{ext}")
            with open(path, 'wb') as handle:
                handle.write(base64.b64decode(c['data']))
            images.append(path)
        else:
            texts.append(c.get('text', json.dumps(c)))
    if not texts and not images:
        texts.append(json.dumps(r)[:4000])
    return {'text': '\n'.join(texts), 'images': images, 'error': bool(isinstance(r, dict) and r.get('isError'))}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def reply(self, obj):
        body = json.dumps(obj).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        res = rpc('tools/list', {}, 20)
        self.reply([t['name'] for t in res.get('result', {}).get('tools', [])])

    def do_POST(self):
        req = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        self.reply(call(req['tool'], req.get('args', {}), req.get('timeout', 120), req.get('label')))


print(f'bridge ready on 127.0.0.1:{PORT} via {EXE}', flush=True)
ThreadingHTTPServer(('127.0.0.1', PORT), Handler).serve_forever()
