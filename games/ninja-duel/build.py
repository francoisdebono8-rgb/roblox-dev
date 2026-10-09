"""Build standalone Roblox XML places from reviewed source; no dependencies/assets."""
from pathlib import Path
import argparse
import hashlib
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--qa', action='store_true')
args = parser.parse_args()
xml = ET.Element('roblox', version='4')
serial = 0

def item(parent, cls, name, properties=None):
    global serial
    serial += 1
    node = ET.SubElement(parent, 'Item', {'class': cls, 'referent': f'ND{serial}'})
    props = ET.SubElement(node, 'Properties')
    ET.SubElement(props, 'string', name='Name').text = name
    for key, kind, value in properties or []:
        prop = ET.SubElement(props, kind, name=key)
        if isinstance(value, dict):
            for k, v in value.items(): ET.SubElement(prop, k).text = str(v)
        else: prop.text = str(value)
    return node

def sources(parent, directory):
    for source in sorted(directory.glob('*.luau')):
        if source.stem == 'NativeQA' and not args.qa: continue
        cls = 'Script' if source.name.endswith('.server.luau') else 'LocalScript' if source.name.endswith('.client.luau') else 'ModuleScript'
        name = source.name.split('.')[0]
        item(parent, cls, name, [('Source','ProtectedString',source.read_text())])

workspace = item(xml,'Workspace','Workspace', [('Gravity','float',140),('FallenPartsDestroyHeight','float',-100)])
# Only the QA build sets the explicit Studio-only test attribute.
replicated = item(xml, 'ReplicatedStorage','ReplicatedStorage')
sources(item(replicated,'Folder','NinjaDuel'),ROOT/'src/Shared')
server=item(xml,'ServerScriptService','ServerScriptService')
sources(item(server,'Folder','NinjaDuelServer'), ROOT/'src/Server')
starter=item(xml,'StarterPlayer','StarterPlayer', [('CameraMinZoomDistance','float',8),('CameraMaxZoomDistance','float',32)])
sources(item(item(starter,'StarterPlayerScripts','StarterPlayerScripts'),'Folder','NinjaDuelClient'),ROOT/'src/Client')
item(xml,'Lighting','Lighting', [('Technology','token',3),('ClockTime','float',15),('Brightness','float',2.5),('Ambient','Color3',{'R':0.42,'G':0.48,'B':0.55}),('OutdoorAmbient','Color3',{'R':0.55,'G':0.58,'B':0.6})])
item(xml,'SoundService','SoundService')
if args.qa:
    for props in server.iter('Properties'):
        if props.findtext("string[@name='Name']") == 'Main':
            source = props.find("ProtectedString[@name='Source']")
            source.text = 'workspace:SetAttribute("NinjaDuelQA",true)\n'+source.text
name='NinjaDuel-QA.rbxlx' if args.qa else 'NinjaDuel.rbxlx'
output=ROOT/'dist'/name
ET.indent(xml)
ET.ElementTree(xml).write(output,encoding='utf-8',xml_declaration=True)
expected = [p.read_text() for p in (ROOT/'src').rglob('*.luau') if args.qa or p.stem!='NativeQA']
if args.qa:
    main_source=(ROOT/'src/Server/Main.server.luau').read_text()
    expected[expected.index(main_source)]='workspace:SetAttribute("NinjaDuelQA",true)\n'+main_source
embedded=[p.findtext("ProtectedString[@name='Source']") for p in xml.iter('Properties') if p.find("ProtectedString[@name='Source']") is not None]
assert sorted(embedded)==sorted(expected), 'Embedded sources differ from reviewed files'
manifest={'version':'0.2.0','artifact':name,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'sources':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'src').rglob('*.luau')) if args.qa or p.stem!='NativeQA'},'sourceEquality':'PASS','externalAssets':[]}
output.with_suffix('.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(output)
print(manifest['sha256'])
