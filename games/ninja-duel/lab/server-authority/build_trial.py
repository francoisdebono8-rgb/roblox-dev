"""Server Authority trial place (lab only, never a shared place).

    python3 lab/server-authority/build_trial.py [out.rbxlx]

Writes a minimal place: a floor, a spawn, the shared simulation module
(ReplicatedStorage.SATrial), its server and client scripts. The Server
Authority switches are set afterwards in Studio by setup_studio.luau (their
serialized names and enum values are not documented). Default output:
lab/server-authority/out/ND-SA-essai.rbxlx (git-ignored).
"""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
out = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / 'out' / 'ND-SA-essai.rbxlx'
root = ET.Element('roblox', version='4')
serial = 0


def item(parent, cls, name, properties=()):
    global serial
    serial += 1
    node = ET.SubElement(parent, 'Item', {'class': cls, 'referent': f'SA{serial}'})
    props = ET.SubElement(node, 'Properties')
    ET.SubElement(props, 'string', name='Name').text = name
    for key, kind, value in properties:
        prop = ET.SubElement(props, kind, name=key)
        if isinstance(value, dict):
            for k, v in value.items():
                ET.SubElement(prop, k).text = str(v)
        else:
            prop.text = str(value)
    return node


def script(parent, cls, name, file):
    return item(parent, cls, name, [('Source', 'ProtectedString', (HERE / file).read_text(encoding='utf-8'))])


def cframe(x, y, z):
    return {'X': x, 'Y': y, 'Z': z, 'R00': 1, 'R01': 0, 'R02': 0, 'R10': 0, 'R11': 1, 'R12': 0, 'R20': 0, 'R21': 0, 'R22': 1}


workspace = item(root, 'Workspace', 'Workspace', [('Gravity', 'float', 140)])
item(workspace, 'Part', 'Floor', [('Anchored', 'bool', 'true'), ('size', 'Vector3', {'X': 400, 'Y': 2, 'Z': 400}),
                                   ('CFrame', 'CoordinateFrame', cframe(0, -1, 0)),
                                   ('Color3uint8', 'Color3uint8', 0xFF6E8B5A)])
item(workspace, 'SpawnLocation', 'Spawn', [('Anchored', 'bool', 'true'), ('size', 'Vector3', {'X': 6, 'Y': 1, 'Z': 6}),
                                           ('CFrame', 'CoordinateFrame', cframe(0, 0.5, 0))])
# Markers every 10 studs along X and Z: distances read on screen.
for i in range(-5, 6):
    if i == 0:
        continue
    item(workspace, 'Part', f'Mark{i}', [('Anchored', 'bool', 'true'), ('CanCollide', 'bool', 'false'),
                                         ('size', 'Vector3', {'X': 0.4, 'Y': 0.2, 'Z': 0.4}),
                                         ('CFrame', 'CoordinateFrame', cframe(i * 10, 0.1, 0))])
replicated = item(root, 'ReplicatedStorage', 'ReplicatedStorage')
script(replicated, 'ModuleScript', 'SATrial', 'SATrial.luau')
server = item(root, 'ServerScriptService', 'ServerScriptService')
script(server, 'Script', 'SATrialServer', 'SATrialServer.server.luau')
starter = item(root, 'StarterPlayer', 'StarterPlayer')
scripts = item(starter, 'StarterPlayerScripts', 'StarterPlayerScripts')
script(scripts, 'LocalScript', 'SATrialClient', 'SATrialClient.client.luau')
item(root, 'Lighting', 'Lighting', [('ClockTime', 'float', 14)])
out.parent.mkdir(parents=True, exist_ok=True)
ET.ElementTree(root).write(out, encoding='utf-8', xml_declaration=False)
print(out)
