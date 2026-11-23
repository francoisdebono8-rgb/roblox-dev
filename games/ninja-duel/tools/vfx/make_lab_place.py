"""Place d'atelier VFX minimale (la scène est construite ensuite par MCP)."""
import sys
import xml.etree.ElementTree as ET
serial = 0
def item(parent, cls, name, props=()):
    global serial; serial += 1
    node = ET.SubElement(parent, 'Item', {'class': cls, 'referent': f'LAB{serial}'})
    p = ET.SubElement(node, 'Properties')
    ET.SubElement(p, 'string', name='Name').text = name
    for key, kind, value in props:
        e = ET.SubElement(p, kind, name=key)
        if isinstance(value, dict):
            for k, v in value.items(): ET.SubElement(e, k).text = str(v)
        else: e.text = str(value)
    return node
root = ET.Element('roblox', version='4')
item(root, 'Workspace', 'Workspace', [('Gravity', 'float', 140)])
item(root, 'Lighting', 'Lighting', [('Technology', 'token', 4), ('ClockTime', 'float', 15), ('Brightness', 'float', 2.5),
     ('Ambient', 'Color3', {'R': 0.42, 'G': 0.48, 'B': 0.55}), ('OutdoorAmbient', 'Color3', {'R': 0.55, 'G': 0.58, 'B': 0.6})])
item(root, 'ReplicatedStorage', 'ReplicatedStorage')
item(root, 'ServerScriptService', 'ServerScriptService')
item(root, 'StarterPlayer', 'StarterPlayer')
item(root, 'SoundService', 'SoundService')
ET.ElementTree(root).write(sys.argv[1], encoding='utf-8', xml_declaration=False)
print(sys.argv[1])
