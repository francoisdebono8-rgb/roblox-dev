"""Dependency-free deterministic Roblox XML place builder. Run with --qa for unsaved local tests."""
from pathlib import Path
import argparse, hashlib, json, re
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parent
parser=argparse.ArgumentParser(); parser.add_argument('--qa',action='store_true'); args=parser.parse_args()
xml=ET.Element('roblox',version='4'); serial=0

def item(parent,cls,name,props=()):
 global serial
 serial+=1
 node=ET.SubElement(parent,'Item',{'class':cls,'referent':f'WFT{serial}'})
 p=ET.SubElement(node,'Properties'); ET.SubElement(p,'string',name='Name').text=name
 for key,kind,value in props:
  child=ET.SubElement(p,kind,name=key)
  if isinstance(value,dict):
   for k,v in value.items(): ET.SubElement(child,k).text=str(v)
  else: child.text=str(value)
 return node

def sources(parent,folder):
 for path in sorted((ROOT/'src'/folder).glob('*.luau')):
  if path.stem.startswith('NativeQA') and not args.qa: continue
  cls='Script' if path.name.endswith('.server.luau') else 'LocalScript' if path.name.endswith('.client.luau') else 'ModuleScript'
  source=path.read_text()
  if args.qa and path.name=='Main.server.luau': source="workspace:SetAttribute('WFT_LocalQA',true)\n"+source
  source=re.sub(r"require\(['\"]\./(\w+)['\"]\)",r'require(script.Parent.\1)',source)
  item(parent,cls,path.name.split('.')[0],[('Source','ProtectedString',source)])
workspace=item(xml,'Workspace','Workspace',[('Gravity','float',196.2),('FallenPartsDestroyHeight','float',-100)])
if args.qa:
 # Attribute via a separate server bootstrap, before Data.load is called.
 s=item(xml,'ServerScriptService','ServerScriptService')
 item(s,'Script','LocalQAMode',[('Source','ProtectedString',"workspace:SetAttribute('WFT_LocalQA',true)")])
else: s=item(xml,'ServerScriptService','ServerScriptService')
rep=item(xml,'ReplicatedStorage','ReplicatedStorage'); shared=item(rep,'Folder','WFT'); sources(shared,'Shared')
sources(item(s,'Folder','WFTServer'),'Server')
starter=item(xml,'StarterPlayer','StarterPlayer',[('CameraMinZoomDistance','float',7),('CameraMaxZoomDistance','float',30)])
sources(item(item(starter,'StarterPlayerScripts','StarterPlayerScripts'),'Folder','WFTClient'),'Client')
item(xml,'Lighting','Lighting',[('Technology','token',3),('ClockTime','float',16),('Brightness','float',2.5)])
item(xml,'SoundService','SoundService'); item(xml,'StarterGui','StarterGui',[('ScreenOrientation','token',2)])
suffix='-QA' if args.qa else ''
output=ROOT/'dist'/f'ForgeAndFlex{suffix}.rbxlx'; output.parent.mkdir(exist_ok=True)
ET.indent(xml); ET.ElementTree(xml).write(output,encoding='utf-8',xml_declaration=True)
fingerprint=hashlib.sha256(output.read_bytes()).hexdigest()
(ROOT/'dist'/f'build{suffix}.json').write_text(json.dumps({'artifact':output.name,'sha256':fingerprint,'source_sha256':hashlib.sha256(b''.join(p.relative_to(ROOT).as_posix().encode()+p.read_bytes() for p in sorted((ROOT/'src').rglob('*.luau')) if not p.stem.startswith('NativeQA'))).hexdigest(),'local_qa':args.qa},indent=2)+'\n')
print(f'{output}: {fingerprint}')
