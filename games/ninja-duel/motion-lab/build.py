"""Compile, test and package a local plugin. Does not open Studio or publish assets."""
from pathlib import Path
import os,shutil,subprocess,json,hashlib,xml.etree.ElementTree as ET,tempfile
ROOT=Path(__file__).resolve().parent
GAME=ROOT.parent
TOOLS=Path(os.getenv('NINJA_DUEL_TOOLS','/private/tmp/ninja-duel-tools'))
def tool(name):
 p=os.getenv(name.upper().replace('-','_')) or str(TOOLS/name)
 if not Path(p).exists():p=shutil.which(name)
 if not p:raise SystemExit('Missing '+name)
 return p
sources=sorted((ROOT/'ForgeMotionLab').rglob('*.luau'))
for p in sources:subprocess.run([tool('luau-compile'),str(p)],stdout=subprocess.DEVNULL,check=True)
subprocess.run([tool('lune'),'run','motion-lab/tests/run.luau'],cwd=GAME,check=True)
xml=ET.Element('roblox',version='4');index=0
def item(parent,cls,name,source=None):
 global index
 index+=1;node=ET.SubElement(parent,'Item',{'class':cls,'referent':f'FML{index}'})
 props=ET.SubElement(node,'Properties');ET.SubElement(props,'string',name='Name').text=name
 if source is not None:ET.SubElement(props,'ProtectedString',name='Source').text=source
 return node
root=item(xml,'Model','ForgeMotionLab');mods=item(root,'Folder','Modules')
for p in sources:item(root if p.name=='Main.plugin.luau' else mods,'Script' if p.name=='Main.plugin.luau' else 'ModuleScript','Main' if p.name=='Main.plugin.luau' else p.stem,p.read_text())
ET.indent(xml);raw=ET.tostring(xml,encoding='utf-8',xml_declaration=True)
(ROOT/'dist').mkdir(exist_ok=True)
with tempfile.TemporaryDirectory() as tmp:
 tmp=Path(tmp);source=tmp/'plugin.rbxmx';source.write_bytes(raw);binary=tmp/'plugin.rbxm'
 subprocess.run([tool('lune'),'run',str(ROOT/'tools/package.luau'),str(source),str(binary)],cwd=GAME,check=True)
 (ROOT/'dist/ForgeMotionLab.rbxmx').write_bytes(raw);(ROOT/'dist/ForgeMotionLab.rbxm').write_bytes(binary.read_bytes())
manifest={'plugin':'Forge Motion Lab','version':'0.1.0','artifact':'ForgeMotionLab.rbxm','sha256':hashlib.sha256(binary.read_bytes()).hexdigest() if binary.exists() else hashlib.sha256((ROOT/'dist/ForgeMotionLab.rbxm').read_bytes()).hexdigest(),'sources':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},'automatedTests':'PASS','native':'PENDING','visualReview':'USER_PENDING','published':False}
(ROOT/'dist/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(ROOT/'dist/ForgeMotionLab.rbxm')
