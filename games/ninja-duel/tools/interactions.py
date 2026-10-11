"""Optional chakra lab: reproducible demos, variant comparisons and JSON batches."""
from pathlib import Path
import argparse,json,os,shutil,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
def lune():
 for path in (os.getenv('LUNE'),str(Path(os.getenv('NINJA_DUEL_TOOLS','/private/tmp/ninja-duel-tools'))/'lune'),shutil.which('lune')):
  if path and (Path(path).is_file() or shutil.which(path)):return path
 raise SystemExit('Set LUNE/NINJA_DUEL_TOOLS or put lune on PATH')
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('operation',choices=['demo','compare','batch','suite'])
p.add_argument('--name',default='kunai_wind');p.add_argument('--seconds',type=float,default=1)
p.add_argument('--mastery',default='Basic');p.add_argument('--tool',default='Kunai')
p.add_argument('--infusions',nargs='+',default=['None','Reinforce','Wind']);p.add_argument('--masteries',nargs='+',default=['Basic','WeaponExpert'])
p.add_argument('--file',type=Path);p.add_argument('--out',type=Path)
a=p.parse_args()
options={'name':a.name,'seconds':a.seconds,'mastery':a.mastery} if a.operation=='demo' else {}
if a.operation=='compare':options={'tool':a.tool,'infusions':a.infusions,'masteries':a.masteries}
if a.operation=='batch':
 if not a.file or a.file.stat().st_size>64000:raise SystemExit('Batch requires --file, max 64 KB')
 options={'commands':json.loads(a.file.read_text())}
proc=subprocess.run([lune(),'run','tools/interactions.luau',a.operation,json.dumps(options)],cwd=ROOT,capture_output=True,text=True)
try:result=json.loads(proc.stdout)
except json.JSONDecodeError:raise SystemExit(proc.stderr or proc.stdout)
if proc.returncode or not result.get('ok'):raise SystemExit(result.get('error') or proc.stderr)
text=json.dumps(result,ensure_ascii=False,indent=2)+'\n'
if a.out:a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(text);print(a.out)
else:print(text,end='')
