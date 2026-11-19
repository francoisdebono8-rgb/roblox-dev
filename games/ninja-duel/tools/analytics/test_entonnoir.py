#!/usr/bin/env python3
"""Tests du lecteur de l'entonnoir (OUTILLEUR, 19/11).

    python3 tools/analytics/test_entonnoir.py

Les exports de `exemples/` sont inventés : ils servent à vérifier les formes que
le lecteur accepte, pas à décrire des joueurs.
"""
import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import entonnoir as E  # noqa: E402

EX = HERE / "exemples"
NOW = [(1, "joined"), (2, "input"), (3, "jutsu"), (4, "duel")]
# Les étapes prévues par la vague 2 (DEV 4) ; les noms exacts seront ceux du DEV.
PLAN = [(1, "joined"), (2, "outfit"), (3, "starter"), (4, "firstDuel"), (5, "firstHit"), (6, "firstWin"),
        (7, "firstPurchase")]


def counts(funnel):
    return [(s.order, s.id, s.users) for s in funnel.steps]


class GameSteps(unittest.TestCase):
    def test_the_game_sends_numbered_steps_from_1(self):
        steps = E.game_steps()
        self.assertTrue(steps, "aucune étape trouvée dans src/")
        orders = [o for o, _ in steps]
        self.assertEqual(orders, list(range(1, len(orders) + 1)), f"des trous dans la numérotation : {steps}")
        self.assertEqual(E.label(steps[0][1]), "arrivée", "la première étape doit être l'arrivée")

    def test_a_funnel_table_a_list_and_literal_calls_are_read(self):
        with tempfile.TemporaryDirectory() as d:
            Path(d, "A.luau").write_text('M.FUNNEL={joined=1,outfit=2,["firstHit"]=3}\n', encoding="utf-8")
            self.assertEqual(E.game_steps(Path(d)), [(1, "joined"), (2, "outfit"), (3, "firstHit")])
            Path(d, "A.luau").write_text('local FUNNEL = {"joined", "outfit"}\n'
                                         'S:LogOnboardingFunnelStepEvent(player, 3, "starter")\n', encoding="utf-8")
            self.assertEqual(E.game_steps(Path(d)), [(1, "joined"), (2, "outfit"), (3, "starter")])


class Numbers(unittest.TestCase):
    def test_french_and_english_numbers(self):
        cases = {"1 240": 1240, "1,240": 1240, "1 240": 1240, "45,2 %": 45.2, "95.2%": 95.2, "0,452": 0.452,
                 "1.234.567": 1234567, "1,234.5": 1234.5, "1.234,5": 1234.5, "12": 12}
        for cell, value in cases.items():
            self.assertAlmostEqual(E.number(cell)[0], value, msg=cell)
        self.assertTrue(E.number("45 %")[1])
        for cell in ("", "—", "N/A", "joined", "2026-11-13"):
            self.assertIsNone(E.number(cell)[0], cell)

    def test_step_names_and_numbers(self):
        self.assertEqual(E.match_step("Step 3: jutsu", NOW), (3, "jutsu"))
        self.assertEqual(E.match_step("3. Premier jutsu", NOW), (3, "jutsu"))
        self.assertEqual(E.match_step("jutsu (3)", NOW), (3, "jutsu"))
        self.assertEqual(E.match_step("3", NOW), (3, "jutsu"))
        self.assertEqual(E.match_step("Première victoire", PLAN), (6, "firstWin"))
        self.assertEqual(E.match_step("premier achat", PLAN), (7, "firstPurchase"))


class Exports(unittest.TestCase):
    def test_one_row_per_step_with_title_lines(self):
        fs = E.read(EX / "export_etapes_en.csv", NOW)
        self.assertEqual(len(fs), 1)
        self.assertEqual(counts(fs[0]), [(1, "joined", 1240), (2, "input", 1180), (3, "jutsu", 610), (4, "duel", 520)])
        self.assertIn("Nov 13 2026", fs[0].period)
        r = E.analyse(fs[0], NOW)
        self.assertEqual((r["worst"]["from"], r["worst"]["to"], r["worst"]["lost"]),
                         ("première entrée", "premier jutsu", 570))
        self.assertFalse(r["missing"])

    def test_one_row_per_day_and_platform_in_french(self):
        fs = E.read(EX / "export_jours_fr.csv", PLAN)
        self.assertEqual([f.group for f in fs], ["tous", "Ordinateur", "Téléphone"])
        everyone, desktop, phone = fs
        self.assertEqual([s.users for s in everyone.steps], [400, 355, 242, 217, 208, 125, 20])
        self.assertEqual([s.id for s in phone.steps], [n for _, n in PLAN])
        r = E.analyse(phone, PLAN)
        self.assertEqual((r["worst"]["from"], r["worst"]["to"]), ("tenue", "inspiration"))
        self.assertEqual((r["worst_rate"]["from"], r["worst_rate"]["to"]), ("première victoire", "premier achat"))
        # avec les étapes d'aujourd'hui, celles de la vague 2 sont dites inconnues, sans rien casser
        r = E.analyse(E.read(EX / "export_jours_fr.csv", NOW)[0], NOW)
        self.assertIn("première entrée", r["missing"])
        self.assertIn("premier achat", r["unknown"])

    def test_one_column_per_step(self):
        f = E.read(EX / "export_colonnes.csv", NOW)[0]
        self.assertEqual(counts(f), [(1, "joined", 420), (2, "input", 390), (3, "jutsu", 230), (4, "duel", 195)])

    def test_percentages_only(self):
        f = E.read(EX / "export_pourcentages.csv", NOW)[0]
        self.assertEqual([s.pct for s in f.steps], [100, 92, 45, 38])
        r = E.analyse(f, NOW)
        self.assertEqual(r["worst"]["to"], "premier jutsu")
        self.assertAlmostEqual(r["worst"]["lost_points"], 47)

    def test_hand_typed(self):
        f = E.read(EX / "saisie.txt", NOW)[0]
        self.assertEqual(counts(f), [(1, "joined", 120), (2, "input", 115), (3, "jutsu", 60), (4, "duel", 41)])

    def test_semicolons_tabs_and_utf16(self):
        body = "Étape\tJoueurs\n1. arrivée\t50\n2. première entrée\t40\n"
        with tempfile.TemporaryDirectory() as d:
            p = Path(d, "x.csv")
            p.write_bytes(body.encode("utf-16"))
            self.assertEqual(counts(E.read(p, NOW)[0]), [(1, "joined", 50), (2, "input", 40)])
            p.write_text(body.replace("\t", ";"), encoding="cp1252")
            self.assertEqual(counts(E.read(p, NOW)[0]), [(1, "joined", 50), (2, "input", 40)])

    def test_a_rising_count_is_flagged(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d, "x.csv")
            p.write_text("Step,Users\njoined,100\ninput,140\n", encoding="utf-8")
            r = E.analyse(E.read(p, NOW)[0], NOW)
            self.assertTrue(any("plus de joueurs" in w for w in r["warnings"]))


class ServerOutput(unittest.TestCase):
    def test_who_went_how_far_and_where_they_left(self):
        f = E.read(EX / "sortie_studio.log", NOW)[0]
        self.assertEqual([s.users for s in f.steps], [4, 3, 2, 2])
        self.assertEqual(f.left, {"dodge": 1, "move": 1})
        r = E.analyse(f, NOW)
        self.assertEqual(r["steps"][1]["median_s"], 8.2)
        self.assertTrue(any("piste" in w for w in r["warnings"]))

    def test_steps_this_build_does_not_send_are_absent_not_lost(self):
        log = "[NinjaDuelFirst] 7 joined 0.0s\n[NinjaDuelFirst] 7 outfit 4.0s\n"
        with tempfile.TemporaryDirectory() as d:
            p = Path(d, "o.log")
            p.write_text(log, encoding="utf-8")
            f = E.read(p, PLAN)[0]
            self.assertEqual([s.id for s in f.steps], ["joined", "outfit"])
            self.assertIn("premier achat", E.analyse(f, PLAN)["missing"])


class StudioOutput(unittest.TestCase):
    def test_a_real_studio_run_where_nobody_leaves(self):
        # the server's own lines, Studio, two test players (19/11)
        f = E.read(EX / "studio_duo_20261119.log", NOW)[0]
        self.assertEqual([s.users for s in f.steps], [2, 2])
        r = E.analyse(f, NOW)
        self.assertIn("Personne ne part", E.text(r))


class Command(unittest.TestCase):
    def test_the_report_names_the_step(self):
        out = io.StringIO()
        with redirect_stdout(out):
            code = E.main([str(EX / "export_etapes_en.csv")])
        self.assertEqual(code, 0)
        self.assertIn("Où ils partent le plus : entre « première entrée » et « premier jutsu »", out.getvalue())

    def test_unreadable_file_says_so(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d, "vide.csv")
            p.write_text("rien à lire ici\n", encoding="utf-8")
            with redirect_stdout(io.StringIO()):
                import contextlib
                with contextlib.redirect_stderr(io.StringIO()) as err:
                    self.assertEqual(E.main([str(p)]), 1)
            self.assertIn("format n'est pas reconnu", err.getvalue())


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"Entonnoir: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
