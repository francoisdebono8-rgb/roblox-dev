"""Client for mcp_bridge.py (start the bridge first).

  python mcp.py tools
  python mcp.py call <tool> '<json args>' [timeout] [label]
  python mcp.py luau <Server|Client|Edit> <file.luau> [timeout]
  python mcp.py shot [label]
The studio_id argument is filled from list_roblox_studios when omitted.
"""
import json, os, sys, urllib.request

PORT = int(os.environ.get('NINJA_DUEL_MCP_PORT', '8765'))


def post(obj, timeout):
    req = urllib.request.Request(f'http://127.0.0.1:{PORT}/call', json.dumps(obj).encode(),
                                 {'Content-Type': 'application/json'})
    return json.loads(urllib.request.urlopen(req, timeout=timeout + 30).read())


def studio():
    r = post({'tool': 'list_roblox_studios', 'args': {}, 'timeout': 20}, 20)
    studios = json.loads(r['text']).get('studios', []) if r['text'].startswith('{') else []
    return studios[0]['id'] if studios else None


def run(tool, args, timeout=120, label=None):
    if tool != 'list_roblox_studios' and 'studio_id' not in args:
        args['studio_id'] = studio()
    return post({'tool': tool, 'args': args, 'timeout': timeout, 'label': label}, timeout)


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    cmd = sys.argv[1]
    if cmd == 'tools':
        print(urllib.request.urlopen(f'http://127.0.0.1:{PORT}/tools', timeout=40).read().decode())
    elif cmd == 'call':
        r = run(sys.argv[2], json.loads(sys.argv[3]), float(sys.argv[4]) if len(sys.argv) > 4 else 120,
                sys.argv[5] if len(sys.argv) > 5 else None)
        print(('[ERROR] ' if r['error'] else '') + r['text'])
        for path in r['images']:
            print('[image]', path)
    elif cmd == 'luau':
        with open(sys.argv[3], encoding='utf-8') as handle:
            code = handle.read()
        r = run('execute_luau', {'code': code, 'datamodel_type': sys.argv[2]},
                float(sys.argv[4]) if len(sys.argv) > 4 else 180)
        print(('[ERROR] ' if r['error'] else '') + r['text'])
    elif cmd == 'shot':
        label = sys.argv[2] if len(sys.argv) > 2 else 'shot'
        r = run('screen_capture', {'capture_id': 'ScreenCapture_' + label}, 60, label)
        print(('[ERROR] ' if r['error'] else '') + r['text'])
        for path in r['images']:
            print('[image]', path)
