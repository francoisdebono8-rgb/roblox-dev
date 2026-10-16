"""Real-input control matrix in Studio (keyboard/mouse through the client Input
module and the Action remote). Each scenario: stage on the server, record the
human's moves from the client snapshots, play real keys/clicks, compare.

  python nd_matrix.py [scenario ...]
"""
import json, sys, time, urllib.request

def post(obj, timeout):
    req = urllib.request.Request('http://127.0.0.1:8765/call', json.dumps(obj).encode(), {'Content-Type': 'application/json'})
    return json.loads(urllib.request.urlopen(req, timeout=timeout + 30).read())

SID = json.loads(post({'tool': 'list_roblox_studios', 'args': {}, 'timeout': 20}, 20)['text'])['studios'][0]['id']

def tool(name, args, timeout=60):
    args = dict(args); args['studio_id'] = SID
    r = post({'tool': name, 'args': args, 'timeout': timeout}, timeout)
    return r['text']

def luau(dm, code, timeout=60):
    return tool('execute_luau', {'code': code, 'datamodel_type': dm}, timeout)

def keys(actions): return tool('user_keyboard_input', {'datamodel_type': 'Client', 'actions': actions}, 30)
def mouse(actions): return tool('user_mouse_input', {'datamodel_type': 'Client', 'actions': actions}, 30)
def click(n=1, gap=260):
    acts = [{'action': 'moveTo', 'x': 960, 'y': 540}]
    for i in range(n):
        acts.append({'action': 'mouseButtonClick', 'mouse_button': 'left'})
        acts.append({'action': 'wait', 'wait_time_ms': gap})
    return mouse(acts)

SETUP = '''
local A,B,GAP,GUARD="%s","%s",%s,%s
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local s=dev:Invoke("state")
if type(s)~="table" or s.phase~="Duel" or shared.NdPair~=A..B then
	dev:Invoke("start",A,B);shared.NdPair=A..B
	local t0=os.clock()
	repeat task.wait(.2) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
end
dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",false);dev:Invoke("refill")
dev:Invoke("health","human",400);dev:Invoke("health","bot",400)
dev:Invoke("move","human",Vector3.zero)
dev:Invoke("place",Vector3.new(0,3,GAP/2),Vector3.new(0,3,-GAP/2))
task.wait(.6)
if GUARD then dev:Invoke("act","bot","Guard") else dev:Invoke("act","bot","GuardOff") end
return "ready"
'''
RECORD = '''
local DUR=%s
local remote=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel"):WaitForChild("Action")
shared.NdRec={}
if shared.NdRecConn then shared.NdRecConn:Disconnect() end
local last
local conn
conn=remote.OnClientEvent:Connect(function(data)
	if type(data)~="table" or not data.human then return end
	local h=data.human
	local name=h.attackVariant or h.attackName or (if h.castId and (h.state=="TechniqueChannel" or h.state=="TechniqueActive") then "cast:"..h.castId else nil)
		or (if h.state=="Rush" or h.state=="Pursuit" or h.state=="Dodging" then h.state else nil)
	if name and name~=last then table.insert(shared.NdRec,name) end
	last=name
end)
shared.NdRecConn=conn
task.delay(DUR,function() conn:Disconnect() end)
return "rec"
'''
def setup(a='Flashstep', b='Mirage', gap=5, guard=False):
    return luau('Server', SETUP % (a, b, gap, 'true' if guard else 'false'))
def record(dur=5): return luau('Client', RECORD % dur)
def result(): return luau('Client', 'return table.concat(shared.NdRec or {}," > ")')

def place(gap):
    return luau('Server', 'local dev=game:GetService("ServerStorage").NinjaDuelDev dev:Invoke("move","human",Vector3.zero) dev:Invoke("place",Vector3.new(0,3,%s),Vector3.new(0,3,%s)) return 1' % (gap / 2, -gap / 2))

SCEN = {}
def scenario(f): SCEN[f.__name__] = f; return f

@scenario
def whiff_then_hit():
    setup(gap=14); record(5); click(1); time.sleep(.9); place(4); time.sleep(.4); click(1); time.sleep(2)
    return result(), 'second press is Light1 again'
@scenario
def early_buffer():
    setup(gap=4); record(4); click(2, gap=70); time.sleep(2)
    return result(), 'Light1 > Light2 (no skipped step)'
@scenario
def plain_three():
    setup(gap=4); record(5); click(3); time.sleep(2)
    return result(), 'Light1 > Light2 > Light3'
@scenario
def toward_three():
    setup(gap=4); record(5); keys([{'action': 'keyDown', 'key_code': 'W'}]); click(3); keys([{'action': 'keyUp', 'key_code': 'W'}]); time.sleep(2)
    return result(), 'Light1 > Light2 > Launcher'
@scenario
def back_three():
    setup(gap=4); record(5); click(2); keys([{'action': 'keyDown', 'key_code': 'S'}]); click(1); keys([{'action': 'keyUp', 'key_code': 'S'}]); time.sleep(2)
    return result(), 'Light1 > Light2 > Sweep (away route)'
@scenario
def air_route():
    setup(gap=4); record(7); keys([{'action': 'keyDown', 'key_code': 'W'}]); click(3); keys([{'action': 'keyUp', 'key_code': 'W'}])
    keys([{'action': 'keyPress', 'key_code': 'E'}]); time.sleep(.25); click(1, gap=200)
    keys([{'action': 'keyDown', 'key_code': 'W'}]); click(1, gap=120); keys([{'action': 'keyUp', 'key_code': 'W'}]); time.sleep(2)
    return result(), '... Launcher > Pursuit > Air1 > AirDrive (air up route)'
@scenario
def dash_attack():
    setup(gap=18); record(5); keys([{'action': 'keyPress', 'key_code': 'E'}]); time.sleep(.2); click(2, gap=300); time.sleep(2)
    return result(), 'Rush > DashAttack > Light2 (fresh string from the arrival)'
@scenario
def jutsu_cancel():
    setup(gap=4); record(6); click(1, gap=200); keys([{'action': 'keyPress', 'key_code': 'Three'}]); time.sleep(1.4); click(1); time.sleep(2)
    return result(), 'Light1 > cast/Rasengan > then a fresh Light1'
@scenario
def blocked():
    setup(gap=4, guard=True); record(5); click(3); time.sleep(2)
    return result(), 'blocked string restarts: Light1 > Light1 ...'

names = sys.argv[1:] or list(SCEN)
for n in names:
    try:
        got, want = SCEN[n]()
        print(f'{n:16s} {got}    [expected: {want}]')
    except Exception as e:
        print(f'{n:16s} ERROR {e}')
