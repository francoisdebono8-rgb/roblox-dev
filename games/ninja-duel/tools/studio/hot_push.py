"""Hot-push repo sources into the open Studio place and restart Play (~6 s per iteration).

  python tools/studio/hot_push.py games/ninja-duel/src Client/VelmoraMotionEngine.luau [...]
  rel paths are relative to src/: Client/X.luau, Server/X.luau, Shared/X.luau
"""
import json, os, sys, time, urllib.request

def post(obj, timeout):
    req = urllib.request.Request('http://127.0.0.1:8765/call', json.dumps(obj).encode(),
                                 {'Content-Type': 'application/json'})
    return json.loads(urllib.request.urlopen(req, timeout=timeout + 30).read())

def studio():
    r = post({'tool': 'list_roblox_studios', 'args': {}, 'timeout': 20}, 20)
    return json.loads(r['text'])['studios'][0]['id']

SID = studio()

def run(tool, args, timeout=120):
    args['studio_id'] = SID
    return post({'tool': tool, 'args': args, 'timeout': timeout}, timeout)

ROOTS = {'Client': 'game:GetService("StarterPlayer").StarterPlayerScripts.NinjaDuelClient',
         'Server': 'game:GetService("ServerScriptService").NinjaDuelServer',
         'Shared': 'game:GetService("ReplicatedStorage").NinjaDuel'}

src = sys.argv[1]
chunks = []
for rel in sys.argv[2:]:
    folder, name = rel.replace('\\', '/').split('/', 1)
    name = name.split('.')[0]
    text = open(os.path.join(src, rel), encoding='utf-8').read()
    level = 1
    while (']' + '=' * level + ']') in text:
        level += 1
    eq = '=' * level
    chunks.append('do local inst=%s:FindFirstChild("%s") assert(inst,"missing %s") inst.Source=[%s[%s]%s] table.insert(out,"%s "..#inst.Source) end'
                  % (ROOTS[folder], name, rel, eq, text, eq, rel))

state = run('get_studio_state', {}, 20)['text']
if 'Edit' not in state.split('\n')[0] and ('Play' in state or 'Server' in state or 'Client' in state):
    print(run('start_stop_play', {'is_start': False}, 60)['text'][:120])
for _ in range(30):
    r = run('execute_luau', {'code': 'return "ok"', 'datamodel_type': 'Edit'}, 20)
    if not r['error']:
        break
    time.sleep(1)
code = 'local out={}\n' + '\n'.join(chunks) + '\nreturn table.concat(out,"; ")'
r = run('execute_luau', {'code': code, 'datamodel_type': 'Edit'}, 120)
print(('[ERROR] ' if r['error'] else '') + r['text'][:400])
print(run('start_stop_play', {'is_start': True}, 60)['text'][:120])
for _ in range(40):
    r = run('execute_luau', {'code': 'return game:GetService("ServerStorage"):FindFirstChild("NinjaDuelDev")~=nil', 'datamodel_type': 'Server'}, 20)
    if not r['error'] and 'true' in r['text']:
        break
    time.sleep(1)
print('play ready')
