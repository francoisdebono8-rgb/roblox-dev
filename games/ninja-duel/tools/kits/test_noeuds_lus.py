#!/usr/bin/env python3
"""Tests de noeuds_lus.py (OUTILLEUR, 21/11) : chaque champ qu'un nœud de l'arbre
du ninja écrit dans def.Ninja est lu par le jeu, ou attend son lecteur dans
EN_ATTENTE (le combat de l'étape DEV 3/4, les effets de l'ANIMATEUR) ; chaque
effet d'un nœud Major des arbres des kits est lu par le jeu.

    python3 tools/kits/test_noeuds_lus.py
"""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import noeuds_lus as L  # noqa: E402

# Ce que personne ne lit encore, et qui le lira (DEC-045, 21/11). Un champ
# nouveau sans lecteur fait échouer le test ; un champ de cette liste qui
# trouve son lecteur est signalé (NOTE) : on le retire alors de la liste.
# (21/11, 15 h) DEV 3/4 et 4/4 poussés : Server/NinjaArts et Motor lisent les
# dix champs de def.Ninja ; il reste l'attribut, au client.
EN_ATTENTE = {
    "attribut NinjaNature": "ANIMATEUR, Infusion.<Nature> au client",
}

NINJA = '''
N.Nodes={
	{Id="NatureFire",Branch="Nature",Tier=1,Cost=4,Exclusive="Nature",Set={Nature="Fire"},
		Name="FIRE"},
	{Id="WallRunner",Branch="Mobility",Tier=1,Cost=5,Set={WallRun=1.4},
		Name="WALL"},
	{Id="SmokeBomb",Branch="Tools",Tier=3,Cost=8,Set={SmokeBomb=true},
		Name="SMOKE"},
}
'''


class NoeudsLus(unittest.TestCase):
    def test_the_fields_come_from_the_nodes_sets(self):
        f = L.fields(NINJA)
        self.assertEqual(f["Nature"], ["NatureFire"])
        self.assertEqual(f["WallRun"], ["WallRunner"])
        self.assertIn("Infusion", f, "NinjaTree.def adds the infusion with the nature")

    def test_a_reader_is_found_directly_or_through_an_alias(self):
        files = {
            "Server/Combat.luau": 'if def.Ninja and def.Ninja.WallRun then end',
            "Server/Tools.luau": 'local ninja = fighter.def.Ninja\nif ninja and ninja.SmokeBomb then smoke() end',
            "Server/Arts.luau": 'function A.of(a) return a and a.def and a.def.Ninja end\nlocal n = A.of(a)\nif n.QuickRise then end',
            "Server/Other.luau": 'local x = def.Ninja.Nature0',
            "Server/Matches.luau": 'kit.def.Ninja.Nature = "Fire"',
            "Client/Fx.luau": 'local n = player:GetAttribute("NinjaNature")',
        }
        self.assertEqual(L.readers("WallRun", files), ["Server/Combat.luau"])
        self.assertEqual(L.readers("SmokeBomb", files), ["Server/Tools.luau"])
        self.assertEqual(L.readers("QuickRise", files), ["Server/Arts.luau"], "through an accessor that returns def.Ninja")
        self.assertEqual(L.readers("Nature", files), [], "Nature0 is not Nature, and Matches only carries it")
        self.assertEqual(L.attribute_readers("NinjaNature", files), ["Client/Fx.luau"])

    def test_every_field_of_the_real_tree_is_read_or_waits_for_its_reader(self):
        rows, attrs = L.report()
        self.assertGreaterEqual(len(rows), 10, "the ninja's tree writes its fields")
        unread, now_read = [], []
        for key, nodes, who in rows:
            if not who and key not in EN_ATTENTE:
                unread.append(f"{key} (écrit par {', '.join(nodes)})")
            if who and key in EN_ATTENTE:
                now_read.append(f"{key} lu par {', '.join(who)}")
        for name, who in attrs.items():
            label = "attribut " + name
            if not who and label not in EN_ATTENTE:
                unread.append(label)
            if who and label in EN_ATTENTE:
                now_read.append(f"{label} lu par {', '.join(who)}")
        print(f"\nNoeudsLus : {len(rows)} champs ; en attente de lecteur : {len(EN_ATTENTE) - len(now_read)}")
        for line in now_read:
            print("NOTE " + line + " : il peut sortir de EN_ATTENTE (tools/kits/test_noeuds_lus.py)")
        self.assertFalse(unread, "personne ne lit : " + " | ".join(unread))

    def test_the_effects_of_a_kit_node_are_its_field_and_the_keys_it_sets(self):
        trees = '''
return {
	Flashstep = { Fighter = "Flashstep", Nodes = {
		{ Id = "SealInk", Tier = 1, Kind = "property", Cost = 4,
			Effects = { { "def.Seals.PlantedLife", "set", 15 } } },
		{ Id = "ReturnSeal", Tier = 2, Kind = "substitution", Major = true, Cost = 10,
			Effects = { { "def.Substitution", "set", { PlantDeparture = true } }, { "graph.stringCancels.Flashstep", "set", true } } },
	} },
	Sand = { Fighter = "Sand", Nodes = {
		{ Id = "Gourd", Tier = 1, Kind = "tool", Major = true, Cost = 10, Item = "Gourd",
			Effects = { { "def.Items.Gourd", "set", true } },
			Without = { { "def.SandShield", "clear" } } },
	} },
}'''
        majors = L.kit_majors(trees)
        self.assertEqual([(k, n) for k, n, _ in majors], [("Flashstep", "ReturnSeal"), ("Sand", "Gourd")], "SealInk is not Major")
        self.assertEqual(majors[0][2], [("def.Substitution", ["Substitution", "PlantDeparture"]),
                                        ("graph.stringCancels.Flashstep", ["stringCancels"])])
        files = {"Server/Combat.luau": "if sub.PlantDeparture then end\nlocal c = graph.stringCancels[move]",
                 "Server/Gale.luau": "if def.SandShield then end",
                 "Server/SkillBuilds.luau": "def.Substitution = x"}
        rows = L.kit_report(files, trees)
        unread = [(n, key) for _, n, reads in rows for _, key, who in reads if not who]
        self.assertEqual(unread, [("ReturnSeal", "Substitution")], "SkillBuilds carries the field, it does not read it")
        gourd = dict((key, who) for _, key, who in rows[1][2])
        self.assertEqual(gourd["Gourd"], ["Server/SkillBuilds.luau (gate)"])
        self.assertEqual(gourd["SandShield"], ["Server/Gale.luau"])

    def test_every_major_node_of_the_kit_trees_is_read_by_the_game(self):
        rows = L.kit_report()
        self.assertGreaterEqual(len(rows), 50, "the eight kit trees have their major nodes")
        unread = [f"{kit}.{node} : {path} ({key})" for kit, node, reads in rows for path, key, who in reads if not who]
        empty = [f"{kit}.{node}" for kit, node, reads in rows if not reads]
        print(f"\nNoeudsLus : {len(rows)} nœuds Major des kits, {sum(len(r) for _, _, r in rows)} effets")
        self.assertFalse(empty, "un nœud Major sans effet : " + " | ".join(empty))
        self.assertFalse(unread, "un nœud Major change un champ que personne ne lit : " + " | ".join(unread))


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"NoeudsLus: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
