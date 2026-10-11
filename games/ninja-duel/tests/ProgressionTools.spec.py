"""Exercise real offline tooling: safe namespaces, durable round trips, rollback."""
from pathlib import Path
import json, subprocess, sys, tempfile, unittest
ROOT=Path(__file__).resolve().parents[1]
SANDBOX=ROOT/'progression/sandbox'
class ProgressionTools(unittest.TestCase):
 def setUp(self):
  SANDBOX.mkdir(parents=True,exist_ok=True)
  self.temp=tempfile.TemporaryDirectory(dir=SANDBOX)
  self.store=Path(self.temp.name)/'test.dev.json'
 def tearDown(self):self.temp.cleanup()
 def run_cli(self,op,*args,store=None):
  return subprocess.run([sys.executable,str(ROOT/'tools/progression.py'),op,'--store',str(store or self.store),*args],cwd=ROOT,capture_output=True,text=True)
 def ok(self,op,*args):
  result=self.run_cli(op,*args);self.assertEqual(result.returncode,0,result.stderr);return json.loads(result.stdout)
 def test_round_trip_and_command_replay(self):
  self.ok('give','--character','Mirage')
  self.ok('xp','--character','Mirage','--amount','500')
  first=self.ok('currency','--amount','100','--sequence','3')
  replay=self.ok('currency','--amount','999','--sequence','3')
  self.assertTrue(replay['replayed']);self.assertEqual(first['result']['balance'],100)
  dump=self.ok('dump')['profile'];saved=self.ok('verify')['record']['profile']
  self.assertEqual(dump,saved);self.assertEqual(saved['characters']['Mirage']['xp'],500)
  self.assertEqual(saved['currencies']['Coins'],100)
  self.assertTrue(json.loads(self.store.read_text())['environment']=='development')
  self.ok('reset');self.assertEqual(self.ok('verify')['record']['profile']['commandSequence'],4)
 def test_failed_mutation_preserves_exact_sandbox_and_missing_verify_creates_nothing(self):
  self.assertNotEqual(self.run_cli('verify').returncode,0);self.assertFalse(self.store.exists())
  self.ok('currency','--amount','10');before=self.store.read_bytes()
  self.assertNotEqual(self.run_cli('pack').returncode,0);self.assertEqual(before,self.store.read_bytes())
  self.assertFalse(self.store.with_suffix('.lock').exists())
 def test_forbidden_namespaces_and_foreign_data_never_written(self):
  outside=Path(self.temp.name).parent.parent/'forbidden.dev.json'
  self.assertNotEqual(self.run_cli('dump',store=outside).returncode,0);self.assertFalse(outside.exists())
  self.assertNotEqual(self.run_cli('dump','--profile','live_123').returncode,0);self.assertFalse(self.store.exists())
  self.store.write_text('{"environment":"production","formatVersion":1,"records":{}}');before=self.store.read_bytes()
  self.assertNotEqual(self.run_cli('reset').returncode,0);self.assertEqual(self.store.read_bytes(),before)
 def test_existing_lock_blocks_cli_without_removing_foreign_lock(self):
  lock=self.store.with_suffix('.lock');lock.write_text('another process')
  self.assertNotEqual(self.run_cli('dump').returncode,0);self.assertEqual(lock.read_text(),'another process');self.assertFalse(self.store.exists())
if __name__=='__main__':unittest.main()
