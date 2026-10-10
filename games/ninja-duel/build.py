"""Build reviewed Ninja Duel sources plus explicitly extracted donor assets."""
from pathlib import Path
import argparse
import hashlib
import json
import re
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
shared=item(replicated,'Folder','NinjaDuel')
sources(shared,ROOT/'src/Shared')
# Extracted data-only dependencies, never a merged donor place or unknown script.
asset_files=sorted((ROOT/'assets').glob('*.rbxmx'))
for asset_file in asset_files:
    donor_xml=ET.parse(asset_file).getroot()
    assert not any(n.get('class') in ('Script','LocalScript','ModuleScript') for n in donor_xml.iter('Item'))
    references={n.get('referent'):f'DONOR_{asset_file.stem}_{i}' for i,n in enumerate(donor_xml.iter('Item'))}
    for n in donor_xml.iter('Item'):
        n.set('referent',references[n.get('referent')])
    for ref in donor_xml.iter('Ref'):
        if ref.text in references: ref.text=references[ref.text]
    for node in donor_xml.findall('Item'): shared.append(node)
fingerprint=hashlib.sha256(b''.join(p.read_bytes() for p in sorted((ROOT/'src').rglob('*.luau')) if args.qa or p.stem!='NativeQA')+b''.join(p.read_bytes() for p in asset_files)).hexdigest()
item(shared,'StringValue','BuildFingerprint',[('Value','string',fingerprint)])
licenses=item(shared,'Folder','ThirdPartyLicenses')
for vendor in ('bangla','place1'):
    item(licenses,'StringValue',vendor,[('Value','string',(ROOT/'vendor'/vendor/'LICENSE').read_text())])
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
external_ids={18342131933,18342045122,18341956985,18341905406,5835032207,8595980577,9117969717,656117400,656118852,656121766,656117878,656115606,656114359}
for asset_file in asset_files:
    external_ids.update(map(int,re.findall(r'rbxassetid://(\d+)',asset_file.read_text())))
manifest={'version':'0.4.1-phase6b','artifact':name,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'sources':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'src').rglob('*.luau')) if args.qa or p.stem!='NativeQA'},'sourceEquality':'PASS','buildFingerprint':fingerprint,'donorAssets':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in asset_files},'externalAssets':sorted(external_ids), 'nativeQA':'PENDING', 'visualAcceptance':'PENDING', 'animationPermission':'PENDING'}
output.with_suffix('.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(output)
print(manifest['sha256'])
