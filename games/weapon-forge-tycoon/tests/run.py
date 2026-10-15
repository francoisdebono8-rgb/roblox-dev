"""Usage: LUAU=/path/to/luau python3 games/weapon-forge-tycoon/tests/run.py."""
from pathlib import Path
import os, shutil, subprocess, sys, xml.etree.ElementTree as ET
root=Path(__file__).resolve().parent.parent
luau=os.environ.get('LUAU') or shutil.which('luau')
if not luau: raise SystemExit('Install the official Luau CLI or set LUAU to its executable path.')
compiler=Path(luau).with_name('luau-compile')
if not compiler.exists(): raise SystemExit('luau-compile must be beside the Luau executable.')
for path in sorted((root/'src').rglob('*.luau')):
 result=subprocess.run([str(compiler),str(path)],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
 if result.returncode: raise SystemExit(result.stderr.decode(errors='replace'))
for name in ('core.luau','simulate.luau'):
 subprocess.run([luau,str(root/'tests'/name)],check=True)
env={**os.environ,'LUAU':str(luau)}
for name in ('persistence.py','receipts.py'):
 subprocess.run([sys.executable,str(root/'tests'/name)],env=env,check=True)
for qa in (False,True): subprocess.run([sys.executable,str(root/'build.py')]+(['--qa'] if qa else []),check=True)
def scripts(path):
 return {i.findtext('Properties/string[@name="Name"]'):i.findtext('Properties/ProtectedString[@name="Source"]') for i in ET.parse(path).iter('Item') if i.get('class') in ('Script','ModuleScript','LocalScript')}
a=scripts(root/'dist/ForgeAndFlex.rbxlx'); b=scripts(root/'dist/ForgeAndFlex-QA.rbxlx')
assert 'NativeQA' not in a
for key,source in a.items(): assert source==b[key].removeprefix("workspace:SetAttribute('WFT_LocalQA',true)\n"),key
print('PASS compile, core, simulations, persistence, receipts, builds, release/QA source parity')
