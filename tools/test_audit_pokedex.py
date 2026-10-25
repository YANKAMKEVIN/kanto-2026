#!/usr/bin/env python3
"""Tests de `tools/audit_pokedex.py` (jalon 32, T1) : `python3 -m unittest tools/test_audit_pokedex.py`."""
from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import audit_pokedex as audit  # noqa: E402


def write(root: str, path: str, content) -> None:
    full = os.path.join(root, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as handle:
        if isinstance(content, str):
            handle.write(content)
        else:
            json.dump(content, handle)


def species(dex: int, name: str, evolutions=None) -> dict:
    return {"dex": dex, "name": name, "types": ["normal"], "evolutions": evolutions or []}


class AuditPokedexTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        root = self.root = self.tmp.name
        write(root, "data/pokemon/species/kanto.json", {
            "bulbasaur": species(1, "Bulbizarre", [{"into": "ivysaur", "method": "level", "level": 16}]),
            "ivysaur": species(2, "Herbizarre"),
            "charmander": species(4, "Salamèche"),
            "pikachu": species(25, "Pikachu", [{"into": "raichu", "method": "item", "item": "thunder_stone"}]),
            "raichu": species(26, "Raichu"),
            "geodude": species(74, "Racaillou", [{"into": "graveler", "method": "level", "level": 25}]),
            "graveler": species(75, "Gravalanch", [{"into": "golem", "method": "trade"}]),
            "golem": species(76, "Grolem"),
            "electrode": species(101, "Électrode"),
            "eevee": species(133, "Évoli", [
                {"into": "vaporeon", "method": "item", "item": "water_stone"},
                {"into": "jolteon", "method": "item", "item": "thunder_stone"},
                {"into": "flareon", "method": "item", "item": "fire_stone"}]),
            "vaporeon": species(134, "Aquali"),
            "kabuto": species(140, "Kabuto"),
            "omanyte": species(138, "Amonita"),
            "rattata": species(19, "Rattata"),
        })
        write(root, "game/world/maps/route_1.tscn", "")
        write(root, "data/encounters/route_1.json", {
            "route_1_grass": {"maps": ["route_1"], "terrain": "grass", "slots": [
                {"species": "pikachu", "levels": [3, 3], "weight": 1},
                {"species": "geodude", "levels": [3, 3], "weight": 1}]},
            "nowhere_grass": {"maps": ["route_99"], "terrain": "grass", "slots": [
                {"species": "rattata", "levels": [3, 3], "weight": 1}]},
        })
        write(root, "data/pokemon/starters.json", {"choices": [
            {"species": "bulbasaur"}, {"species": "charmander"}]})
        write(root, "data/world/fossils.json", {"fossils": {
            "dome_fossil": {"species": "kabuto", "level": 30},
            "helix_fossil": {"species": "omanyte", "level": 30}}})
        write(root, "data/cutscenes/scenes.json", {
            "eevee": {"steps": [{"gift_pokemon": "eevee", "level": 25, "flag": "eevee_received"}]},
            "fossils": {"steps": [{"give": "dome_fossil"}, {"give": "helix_fossil"},
                                  {"gift_pokemon": "kabuto", "level": 30}]},
            "ghost": {"steps": [{"wild_battle": "golem", "level": 30, "uncatchable": True}]},
        })
        write(root, "data/shops/mart.json", {"m": {"stock": [{"item": "thunder_stone"}]}})
        write(root, "data/trades/t.json", {"trades": {
            "trade_electrode": {"wants": "raichu", "gives": "electrode"}}})
        self.rows = {r.sid: r for r in audit.run([audit.DirSource(root)], None, None, quiet=True)}

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_one_row_per_kanto_number(self) -> None:
        self.assertEqual(len(self.rows), 151)
        self.assertEqual(sorted(r.dex for r in self.rows.values()), list(range(1, 152)))

    def test_wild_and_evolution_are_obtainable(self) -> None:
        self.assertEqual(self.rows["pikachu"].status, audit.STATUS_OK)
        self.assertEqual(self.rows["raichu"].status, audit.STATUS_OK)  # pierre en boutique
        self.assertEqual(self.rows["graveler"].status, audit.STATUS_OK)

    def test_trade_evolution_needs_local_trade(self) -> None:
        self.assertEqual(self.rows["golem"].status, audit.STATUS_TRADE)
        self.assertIn("T4", self.rows["golem"].gap)

    def test_uncatchable_battle_is_not_a_way(self) -> None:
        self.assertFalse(any("fixe" in w for w in self.rows["golem"].ways))

    def test_npc_trade_depends_on_wanted_species(self) -> None:
        self.assertEqual(self.rows["electrode"].status, audit.STATUS_OK)

    def test_starters_are_a_single_choice(self) -> None:
        for sid in ("bulbasaur", "ivysaur", "charmander"):
            self.assertEqual(self.rows[sid].status, audit.STATUS_CHOICE, sid)
            self.assertEqual(self.rows[sid].choice, "starters")
        self.assertIn("N-6", self.rows["ivysaur"].gap)

    def test_mt_moon_fossils_are_a_single_choice(self) -> None:
        self.assertEqual(self.rows["kabuto"].choice, "fossile_mt_moon")
        self.assertEqual(self.rows["omanyte"].choice, "fossile_mt_moon")
        # Le don du labo n'est pas compté comme un « don » libre en plus du fossile.
        self.assertFalse(any(w.startswith("don") for w in self.rows["kabuto"].ways))

    def test_single_eevee_makes_its_evolutions_a_choice(self) -> None:
        self.assertEqual(self.rows["eevee"].status, audit.STATUS_OK)
        self.assertEqual(self.rows["vaporeon"].status, audit.STATUS_CHOICE)
        self.assertIn("N-9", self.rows["vaporeon"].gap)

    def test_table_on_missing_map_does_not_count(self) -> None:
        self.assertEqual(self.rows["rattata"].status, audit.STATUS_MISSING)
        self.assertTrue(any("carte absente" in w for w in self.rows["rattata"].ways))

    def test_missing_species_get_their_rule(self) -> None:
        self.assertFalse(self.rows["mew"].has_data)
        self.assertIn("N-1", self.rows["mew"].gap)
        self.assertIn("N-12", self.rows["dragonite"].gap)  # hérité de Minidraco

    def test_outputs_are_written(self) -> None:
        md = os.path.join(self.root, "out", "matrice.md")
        csv_path = os.path.join(self.root, "out", "audit.csv")
        audit.run([audit.DirSource(self.root)], md, csv_path, quiet=True)
        with open(csv_path, encoding="utf-8") as handle:
            self.assertEqual(len(handle.read().strip().splitlines()), 152)
        with open(md, encoding="utf-8") as handle:
            text = handle.read()
        self.assertIn("| 151 | Mew", text)


if __name__ == "__main__":
    unittest.main()
