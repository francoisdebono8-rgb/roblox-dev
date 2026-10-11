"""Install this exact local plugin without opening Studio or publishing an asset."""
from pathlib import Path
import argparse,hashlib,json,os,shutil,sys
root=Path(__file__).resolve().parent
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--plugins-dir',type=Path,help='Studio local Plugins directory')
args=parser.parse_args()
plugins=args.plugins_dir
if plugins is None:
 if sys.platform!='darwin':parser.error('Use --plugins-dir with your Studio local Plugins directory')
 plugins=Path.home()/'Documents/Roblox/Plugins'
artifact=root/'dist/ForgeMotionLab.rbxm'
manifest=json.loads((root/'dist/manifest.json').read_text())
raw=artifact.read_bytes();digest=hashlib.sha256(raw).hexdigest()
if digest!=manifest['sha256']:raise SystemExit('Artifact checksum mismatch; rebuild before installing.')
plugins=plugins.expanduser().resolve();plugins.mkdir(parents=True,exist_ok=True)
target=plugins/artifact.name
if target.exists() and target.read_bytes()==raw:print('Already installed:',target)
else:
 if target.exists():shutil.copy2(target,target.with_suffix('.rbxm.previous'))
 temp=target.with_suffix('.rbxm.tmp');temp.write_bytes(raw);os.replace(temp,target)
 print('Installed:',target)
print('Version:',manifest['version'])
print('Restart Studio when convenient, then Plugins > Forge Motion Lab > Motion Lab.')
