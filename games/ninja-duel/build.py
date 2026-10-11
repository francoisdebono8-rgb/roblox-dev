"""Build reviewed Ninja Duel sources plus explicitly extracted donor assets."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import xml.etree.ElementTree as ET
import shutil

ROOT = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--qa', action='store_true')
parser.add_argument('--debug', action='store_true', help='Separate Studio-only inspector place; no automatic native QA')
args = parser.parse_args()
DEBUG_SOURCES={'DevHooks.luau','CombatInspector.luau','CombatDebug.client.luau'}
def included(p):
    return (args.qa or p.stem!='NativeQA') and (args.qa or args.debug or p.name not in DEBUG_SOURCES)
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
        if not included(source): continue
        cls = 'Script' if source.name.endswith('.server.luau') else 'LocalScript' if source.name.endswith('.client.luau') else 'ModuleScript'
        name = source.name.split('.')[0]
        item(parent, cls, name, [('Source','ProtectedString',source.read_text(encoding='utf-8'))])

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
fingerprint=hashlib.sha256(b''.join(p.read_bytes() for p in sorted((ROOT/'src').rglob('*.luau')) if included(p))+b''.join(p.read_bytes() for p in asset_files)).hexdigest()
item(shared,'StringValue','BuildFingerprint',[('Value','string',fingerprint)])
licenses=item(shared,'Folder','ThirdPartyLicenses')
for vendor in ('bangla','place1','velmora'):
    item(licenses,'StringValue',vendor,[('Value','string',(ROOT/'vendor'/vendor/'LICENSE').read_text(encoding='utf-8'))])
server=item(xml,'ServerScriptService','ServerScriptService')
sources(item(server,'Folder','NinjaDuelServer'), ROOT/'src/Server')
starter=item(xml,'StarterPlayer','StarterPlayer', [('CameraMinZoomDistance','float',8),('CameraMaxZoomDistance','float',32)])
sources(item(item(starter,'StarterPlayerScripts','StarterPlayerScripts'),'Folder','NinjaDuelClient'),ROOT/'src/Client')
item(xml,'Lighting','Lighting', [('Technology','token',3),('ClockTime','float',15),('Brightness','float',2.5),('Ambient','Color3',{'R':0.42,'G':0.48,'B':0.55}),('OutdoorAmbient','Color3',{'R':0.55,'G':0.58,'B':0.6})])
item(xml,'SoundService','SoundService')
if args.qa or args.debug:
    prefix='workspace:SetAttribute("NinjaDuelDebug",true)\n'
    if args.qa: prefix+='workspace:SetAttribute("NinjaDuelQA",true)\n'
    for props in server.iter('Properties'):
        if props.findtext("string[@name='Name']") == 'Main':
            source = props.find("ProtectedString[@name='Source']")
            source.text = prefix+source.text
name='NinjaDuel-QA.rbxlx' if args.qa else 'NinjaDuel-Debug.rbxlx' if args.debug else 'NinjaDuel.rbxlx'
output=ROOT/'dist'/name
ET.indent(xml)
# Binary handle: identical LF bytes on macOS and Windows (text mode would emit CRLF).
with open(output,'wb') as handle: ET.ElementTree(xml).write(handle,encoding='utf-8',xml_declaration=True)
expected = [p.read_text(encoding='utf-8') for p in (ROOT/'src').rglob('*.luau') if included(p)]
if args.qa or args.debug:
    main_source=(ROOT/'src/Server/Main.server.luau').read_text(encoding='utf-8')
    expected[expected.index(main_source)]=prefix+main_source
embedded=[p.findtext("ProtectedString[@name='Source']") for p in xml.iter('Properties') if p.find("ProtectedString[@name='Source']") is not None]
assert sorted(embedded)==sorted(expected), 'Embedded sources differ from reviewed files'
external_ids={18342131933,18342045122,18341956985,18341905406,5835032207,8595980577,9117969717,656117400,656118852,656121766,656117878,656115606,656114359}
for asset_file in asset_files:
    external_ids.update(map(int,re.findall(r'rbxassetid://(\d+)',asset_file.read_text(encoding='utf-8'))))
import subprocess,sys
# Automated gate: every headless spec must pass on the exact sources built here.
TEST_RUNNERS=[('lune','tests/Input.spec.luau'),('luau','tests/Rules.spec.luau'),('lune','tests/Combat.spec.luau'),('lune','tests/Sequences.spec.luau'),('lune','tests/Regression.spec.luau'),('lune','tests/Feedback.spec.luau'),('lune','tests/Animation.spec.luau'),('lune','tests/Branches.spec.luau'),('lune','tests/Phase4.spec.luau'),('lune','tests/Neji.spec.luau'),('lune','tests/Systems.spec.luau'),('lune','tests/Tools.spec.luau'),('lune','tests/Sasuke.spec.luau'),('lune','tests/Gaara.spec.luau'),('lune','tests/Preparation.spec.luau')]
def run_automated():
    tool={}
    import os
    # Tool locations: explicit env (LUAU / LUNE), a shared tools folder
    # (NINJA_DUEL_TOOLS, macOS /private/tmp default, Windows %LOCALAPPDATA%), then PATH.
    folders=[os.environ.get('NINJA_DUEL_TOOLS',''),'/private/tmp/ninja-duel-tools',os.path.join(os.environ.get('LOCALAPPDATA',''),'ninja-duel-tools')]
    for probe in ('luau','lune'):
        candidates=[os.environ.get(probe.upper(),'')]
        for folder in folders:
            if folder: candidates+=[os.path.join(folder,probe),os.path.join(folder,probe+'.exe')]
        candidates.append(probe)
        for candidate in candidates:
            if candidate and (shutil.which(candidate) or Path(candidate).is_file()):
                tool[probe]=candidate
                break
    results={}
    if len(tool)<2:
        return {'status':'SKIPPED','reason':'luau/lune not available in this environment','suites':{}}
    for engine,spec in TEST_RUNNERS:
        command=[tool[engine],'run',spec] if engine=='lune' else [tool[engine],spec]
        proc=subprocess.run(command,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
        tail=(proc.stdout or '').strip().splitlines()
        results[spec]={'exit':proc.returncode,'summary':tail[-1] if tail else ''}
    failed=[spec for spec,data in results.items() if data['exit']!=0]
    return {'status':'PASS' if not failed else 'FAIL','failed':failed,'suites':results}
automated=run_automated()
print('Automated suites:',automated['status'])
for spec,data in automated['suites'].items():
    print('  ',spec,data['exit'],data['summary'])
if automated['status']=='FAIL':
    sys.exit('Automated suites failed: '+', '.join(automated['failed']))

manifest={'version':'0.13.0-arena-combo','artifact':name,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'src').rglob('*.luau')) if included(p)},'sourceEquality':'PASS','debugOnly':args.debug or args.qa,'buildFingerprint':fingerprint,'donorAssets':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in asset_files},'externalAssets':sorted(external_ids),
 'automatedQA':automated,
 # Native (Roblox Studio) and human-feel gates are recorded separately and are
 # only moved off PENDING by an actual Studio run on this exact artifact.
 'nativeQA':'PENDING', 'visualAcceptance':'PENDING', 'controllerFeel':'PENDING', 'animationPermission':'PENDING'}
output.with_suffix('.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
print(output)
print(manifest['sha256'])
