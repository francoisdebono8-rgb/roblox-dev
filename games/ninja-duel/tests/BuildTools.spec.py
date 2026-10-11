"""Meaningful tooling regressions: failed builds must preserve last artifact."""
from pathlib import Path
import json, os, shutil, subprocess, sys, tempfile, unittest
ROOT=Path(__file__).resolve().parents[1]
class BuildTools(unittest.TestCase):
 def test_failed_test_does_not_publish(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d)
   shutil.copy2(ROOT/'build.py',root/'build.py')
   for directory in ('src','assets'):shutil.copytree(ROOT/directory,root/directory)
   for vendor in ('bangla','place1','velmora'):
    target=root/'vendor'/vendor;target.mkdir(parents=True);shutil.copy2(ROOT/'vendor'/vendor/'LICENSE',target/'LICENSE')
   (root/'dist').mkdir();artifact=root/'dist/NinjaDuel.rbxlx';manifest=root/'dist/NinjaDuel.json'
   artifact.write_bytes(b'last usable artifact');manifest.write_bytes(b'last usable manifest')
   failing=root/'fail';failing.write_text('#!/bin/sh\nexit 1\n');failing.chmod(0o700)
   env=dict(os.environ,LUAU=str(failing),LUNE=str(failing))
   proc=subprocess.run([sys.executable,'build.py'],cwd=root,env=env,capture_output=True,text=True)
   self.assertNotEqual(proc.returncode,0);self.assertIn('Automated suites failed',proc.stderr)
   self.assertEqual(artifact.read_bytes(),b'last usable artifact');self.assertEqual(manifest.read_bytes(),b'last usable manifest')
 def test_catalogue_is_outside_build(self):
  data=json.loads((ROOT/'lab/combat-library.json').read_text())
  self.assertEqual(len(data['archetypes']),10);self.assertGreaterEqual(len(data['entries']),30)
  source='\n'.join(p.read_text() for p in (ROOT/'src').rglob('*.luau'))
  self.assertNotIn('combat-library',source)
 def test_report_export_requires_complete_exact_build(self):
  import hashlib
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);artifact=root/'place.rbxlx';artifact.write_bytes(b'fixture');manifest=root/'place.json'
   manifest.write_text(json.dumps({'buildFingerprint':'exact','sha256':hashlib.sha256(b'fixture').hexdigest()}))
   log=root/'log';out=root/'out.json'
   def command():return subprocess.run([sys.executable,str(ROOT/'tools/dev.py'),'report','--log',str(log),'--manifest',str(manifest),'--out',str(out)],capture_output=True,text=True)
   rows=[{'kind':'begin','clientPresent':True},{'kind':'meta','side':'server','enabled':False,'seconds':3},{'kind':'metric','side':'server','name':'cost','value':{'mean':1}},{'kind':'meta','side':'client','enabled':False,'seconds':3},{'kind':'end','rows':3}]
   def write(fingerprint,end=True): log.write_text('\n'.join('[NinjaDuelPerf] '+json.dumps(dict(r,id='fixture',build=fingerprint)) for r in (rows if end else rows[:-1])))
   write('other');self.assertNotEqual(command().returncode,0)
   write('exact',False);self.assertNotEqual(command().returncode,0)
   write('exact');self.assertEqual(command().returncode,0);self.assertTrue(json.loads(out.read_text())['report']['complete'])
if __name__=='__main__':unittest.main()
