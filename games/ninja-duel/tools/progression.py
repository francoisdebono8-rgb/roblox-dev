"""Offline dev profiles and pack simulations. No network / Robux / live profiles."""
from pathlib import Path
import argparse,json,os,shutil,subprocess,sys,tempfile
ROOT=Path(__file__).resolve().parents[1]
SANDBOX=ROOT/'progression/sandbox'
def lune():
 for path in (os.getenv('LUNE'),str(Path(os.getenv('NINJA_DUEL_TOOLS','/private/tmp/ninja-duel-tools'))/'lune'),shutil.which('lune')):
  if path and (Path(path).is_file() or shutil.which(path)):return path
 raise SystemExit('Set LUNE / NINJA_DUEL_TOOLS or put lune on PATH')
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('command',choices=['give','remove','xp','rank','currency','pack','mastery','select','dump','reset','save','verify','simulate','bench'])
p.add_argument('--profile',default='dev_cli');p.add_argument('--character');p.add_argument('--amount',type=int);p.add_argument('--currency',default='Coins');p.add_argument('--rank');p.add_argument('--reward');p.add_argument('--pack',default='Training');p.add_argument('--seed',type=int,default=42);p.add_argument('--profiles',type=int,default=100);p.add_argument('--packs',type=int,default=100);p.add_argument('--roster',type=int);p.add_argument('--sequence',type=int)
p.add_argument('--store',type=Path,default=SANDBOX/'profiles.dev.json');p.add_argument('--out',type=Path)
a=p.parse_args();options={}
if a.command in ('simulate','bench'):
 options={'profiles':a.profiles,'packs':a.packs,'pack':a.pack,'seed':a.seed}
 if a.roster is not None:options['roster']=a.roster
else:
 options={'profile':a.profile,'currency':a.currency,'pack':a.pack}
 for name in ('character','amount','rank','reward','sequence'):
  value=getattr(a,name)
  if value is not None:options[name]=value
store=a.store.resolve()
if not store.is_relative_to(SANDBOX.resolve()) or not store.name.endswith('.dev.json'):raise SystemExit('Store must be progression/sandbox/*.dev.json')
SANDBOX.mkdir(parents=True,exist_ok=True)
lock=store.with_suffix('.lock');descriptor=None;stage=None
try:
 if a.command not in ('simulate','bench'):
  store.parent.mkdir(parents=True,exist_ok=True)
  try:descriptor=os.open(lock,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
  except FileExistsError:raise SystemExit('Sandbox busy. If a previous CLI crashed, verify it is stopped before removing its .lock file.')
  os.write(descriptor,str(os.getpid()).encode())
  fd,name=tempfile.mkstemp(dir=store.parent,suffix='.dev.json');os.close(fd);stage=Path(name)
 command=[lune(),'run','tools/progression.luau',a.command,json.dumps(options),str(store),str(stage) if stage else '']
 proc=subprocess.run(command,cwd=ROOT,capture_output=True,text=True)
 try:result=json.loads(proc.stdout)
 except json.JSONDecodeError:raise SystemExit(proc.stderr or proc.stdout or 'Invalid simulator output')
 if proc.returncode or not result.get('ok'):raise SystemExit(result.get('error') or proc.stderr)
 if stage:stage.replace(store)
 text=json.dumps(result,ensure_ascii=False,indent=2)+'\n'
 if a.out:
  if a.out.resolve()==store:raise SystemExit('Report must not overwrite the sandbox')
  a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(text);print(a.out)
 else:print(text,end='')
finally:
 if stage:stage.unlink(missing_ok=True)
 if descriptor is not None:os.close(descriptor);lock.unlink(missing_ok=True)
