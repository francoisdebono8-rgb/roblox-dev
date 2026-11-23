#!/usr/bin/env python3
"""Tests of the test reading page (OUTILLEUR, 23/11).

    python3 tools/testread/test_testread.py
"""
import json
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import testread as T  # noqa: E402


class TestRead(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dump = os.path.join(self.tmp.name, "dump.json")
        with open(self.dump, "w", encoding="utf-8") as f:
            json.dump(T.example(), f)

    def tearDown(self):
        self.tmp.cleanup()

    def test_the_funnel_counts_players_and_orders_by_time(self):
        r = T.read(self.dump)
        self.assertTrue(r["example"])
        rows = {f["step"]: f for f in r["funnel"]}
        self.assertEqual(rows["joined"]["players"], 3)
        self.assertEqual(rows["node"]["players"], 1)
        medians = [f["median"] for f in r["funnel"] if f["median"] is not None]
        self.assertEqual(medians, sorted(medians))

    def test_a_player_keeps_his_last_record(self):
        data = T.example()
        early = dict(data[1]);early["seconds"] = 100;early["screens"] = {"Konoha": 100}
        data.append(early)
        with open(self.dump, "w", encoding="utf-8") as f:
            json.dump(data, f)
        r = T.read(self.dump)
        a = [s for s in r["sessions"] if s["name"] == "Testeur A"]
        self.assertEqual(len(a), 1)
        self.assertEqual(a[0]["seconds"], 1800)

    def test_the_page_says_example_and_what_comes_back(self):
        r = T.read(self.dump, {"1": {"pensait": "me battre partout"}})
        page = T.page(r, example=r["example"])
        self.assertIn("EXEMPLE", page)
        self.assertIn("me battre partout", page)
        self.assertIn("Konoha", page)
        self.assertEqual(r["repeated"][0], ("Konoha", 2))
        self.assertIn("Lecture du test", T.markdown(r))

    def test_a_real_dump_is_not_an_example(self):
        data = [d for d in T.example() if d.get("kind") != "meta"]
        with open(self.dump, "w", encoding="utf-8") as f:
            json.dump(data, f)
        r = T.read(self.dump)
        self.assertFalse(r["example"])
        self.assertNotIn("EXEMPLE", T.page(r, example=r["example"]))

    def test_the_studio_code_reads_the_test_store(self):
        self.assertIn('GetDataStore("NinjaDuelTest")', T.DUMP)
        self.assertIn("ListKeysAsync", T.DUMP)


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"TestRead: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
