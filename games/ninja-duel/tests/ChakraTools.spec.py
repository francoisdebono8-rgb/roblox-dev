"""Exercise the real CLI and exported reports, including failing batches."""
from pathlib import Path
import json, subprocess, sys, tempfile, unittest
ROOT=Path(__file__).resolve().parents[1]
class ChakraTools(unittest.TestCase):
 def cli(self,*args):return subprocess.run([sys.executable,str(ROOT/'tools/interactions.py'),*args],cwd=ROOT,capture_output=True,text=True)
 def test_six_examples_and_variant_comparison(self):
  p=self.cli('suite');self.assertEqual(p.returncode,0,p.stderr);data=json.loads(p.stdout)
  self.assertFalse(data['gameplayIntegration']);self.assertEqual(len(data['reports']),6);self.assertEqual(len(data['comparison']),6)
  self.assertFalse(data['configSnapshot']['Enabled']);self.assertTrue(data['reports']['kunai_seal']['objects']['a']['anchor'])
 def test_invalid_batch_preserves_existing_report(self):
  with tempfile.TemporaryDirectory() as path:
   path=Path(path);batch=path/'batch.json';out=path/'report.json';out.write_text('previous report')
   batch.write_text(json.dumps([{'op':'spawn','args':{'id':'a'}},{'op':'nature','args':{'id':'a','nature':'Unknown'}}]))
   p=self.cli('batch','--file',str(batch),'--out',str(out));self.assertNotEqual(p.returncode,0);self.assertEqual(out.read_text(),'previous report')
 def test_batch_replays_actual_module_operations(self):
  p=self.cli('batch','--file',str(ROOT/'interactions/example-batch.json'));self.assertEqual(p.returncode,0,p.stderr)
  data=json.loads(p.stdout);self.assertEqual(len(data['operations']),7);self.assertGreater(data['report']['objects']['kunai1']['stats']['speed'],42)
if __name__=='__main__':unittest.main()
