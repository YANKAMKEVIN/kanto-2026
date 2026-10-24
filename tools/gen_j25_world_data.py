#!/usr/bin/env python3
"""Données de monde du jalon 25 tirées des grilles (la grille fait foi) : PNJ, objets, scènes et
dialogues de mise en scène du Manoir Pokémon, de l'Arène de Cramois'Île, de la réserve du Musée
d'Argenta et des échanges du Labo (`docs/tech/jalon-25.md` §2.1 à §2.7).

Écrit (en entier, à relancer après toute modification d'une grille) :
  data/npcs/pokemon_mansion_<niveau>.json, data/npcs/cinnabar_gym.json,
  data/npcs/pewter_museum_reserve.json ;
  data/cutscenes/pokemon_mansion.json, cinnabar_gym.json, pewter_museum_reserve.json,
  cinnabar_trades.json ;
  data/dialogues/pokemon_mansion_world.json, cinnabar_gym_world.json,
  pewter_museum_reserve_world.json, cinnabar_trades_world.json.
Les répliques validées (dossier 28 §16) restent dans data/dialogues/pokemon_mansion.json,
cinnabar_gym.json, pewter_museum_reserve.json, cinnabar_trades.json.

  python3 tools/gen_j25_world_data.py
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")

MANSION = {"pokemon_mansion_1f": "manoir_1f", "pokemon_mansion_2f": "manoir_2f",
	"pokemon_mansion_3f": "manoir_3f", "pokemon_mansion_b1f": "manoir_b1f"}
# Apparence des PNJ par classe (sprites existants ; [D] tant que la série 28 n'est pas intégrée).
# Pillard : aucune planche (série 28 non intégrée) → « gambler » [D] ; Auguste → « gentleman » [D].
SPRITES = {"Scientifique": "researcher", "Pillard": "gambler", "Intello": "nerd",
	"blaine": "gentleman", "guide": "gym_guide"}
# Objets visibles : apparence de la Poké Ball au sol.
BALL = "object/poke_ball_ground"
QUIZ_YES = "cinnabar_gym_quiz_yes"
QUIZ_NO = "cinnabar_gym_quiz_no"
BLAINE = "cinnabar_gym_blaine"
SWITCH_FLAG = "mansion_switch_on"
TRADE_ACCEPTED = "cinnabar_trade_offer_accepted"
TRADE_DECLINED = "cinnabar_trade_offer_declined"


def read_plan(name):
	"""(lignes de la grille, positions {id: (kind, cellules, attrs)})."""
	rows, positions, section = [], {}, ""
	for raw in open(os.path.join(PLANS, name + ".txt"), encoding="utf-8"):
		line = raw.rstrip("\n")
		if section != "GRILLE":
			line = line.split("#", 1)[0].rstrip()
		if not line.strip():
			continue
		words = line.split()
		if words[0] == "GRILLE":
			section = "GRILLE"
			continue
		if words[0] == "POSITIONS":
			section = "POSITIONS"
			continue
		if words[0] == "FIN":
			if section == "POSITIONS":
				break
			section = ""
			continue
		if section == "GRILLE":
			rows.append(words[1])
		elif section == "POSITIONS":
			ident, kind, spec = words[0], words[1], words[2]
			attrs = dict(w.split("=", 1) for w in words[4:] if "=" in w)
			positions[ident] = (kind, cells(spec), attrs)
	return rows, positions


def cells(spec):
	xs, ys = spec.split(",")
	def rng(s):
		if ".." in s:
			a, b = s.split("..")
			return list(range(int(a), int(b) + 1))
		return [int(s)]
	return [[x, y] for y in rng(ys) for x in rng(xs)]


def by_kind(positions, kind):
	return [(i, p) for i, p in positions.items() if p[0] == kind]


def trainer_class(trainers, trainer_id):
	"""Classe = premier mot du nom (« Pillard Gégé »)."""
	return trainers[trainer_id].get("name", "").split(" ")[0]


def write(path, data):
	full = os.path.join(DATA, path)
	with open(full, "w", encoding="utf-8") as f:
		f.write(json.dumps(data, ensure_ascii=False, indent="\t") + "\n")
	print("écrit :", path)


def load(path):
	with open(os.path.join(DATA, path), encoding="utf-8") as f:
		return json.load(f)


def item_entries(positions, npcs, cutscenes, dialogues):
	"""Objets visibles (PNJ Poké Ball) et cachés (point d'examen posé par l'outil de carte)."""
	for ident, (_, cs, attrs) in by_kind(positions, "objet_visible"):
		got = "got_" + ident
		npcs[ident] = {"cell": cs[0], "facing": "down", "sprite": BALL, "dialogue": ident,
			"verb": "take", "turn_to_player": False, "unless": [got]}
		dialogues[ident] = {"cutscene": ident}
		cutscenes[ident] = {"variants": [{"unless": [got], "steps": [
			{"despawn": ident},
			{"give": attrs["item"], "count": 1, "found": True},
			{"set": [got]}]}]}
	for ident, (_, cs, attrs) in by_kind(positions, "objet_cache"):
		got = "got_" + ident
		dialogues[ident] = {"cutscene": ident}
		cutscenes[ident] = {"variants": [{"unless": [got], "steps": [
			{"give": attrs["item"], "count": 1, "found": True},
			{"set": [got]}]}]}


def trainer_npc(trainers, ident, cs, attrs):
	cls = trainer_class(trainers, ident)
	return {"cell": cs[0], "facing": attrs.get("facing", "down"),
		"sprite": SPRITES.get(cls, "researcher"), "dialogue": ident + "_after",
		"trainer": {"id": ident, "sight": int(attrs.get("sight", "0")),
			"before": ident + "_before", "defeated": ident + "_defeated"}}


def mansion(trainers):
	cutscenes, dialogues = {}, {}
	for map_id, plan in MANSION.items():
		_, positions = read_plan(plan)
		npcs = {}
		for ident, (_, cs, attrs) in by_kind(positions, "dresseur"):
			npcs[ident] = trainer_npc(trainers, ident, cs, attrs)
		item_entries(positions, npcs, cutscenes, dialogues)
		write("npcs/%s.json" % map_id, npcs)
	# Statues : OUI → l'interrupteur bascule (étape « toggle »), texte 10 ; NON → texte 11.
	cutscenes["mansion_switch"] = {"variants": [{"steps": [
		{"toggle": [SWITCH_FLAG]},
		{"dialogue": "mansion_statue_yes"}]}]}
	write("cutscenes/pokemon_mansion.json", cutscenes)
	write("dialogues/pokemon_mansion_world.json", dialogues)


def quiz_cutscene(n, question, trainers):
	gate = question["gate"]
	trainer = question["trainer"]
	beaten = "beaten_" + trainer
	right = QUIZ_YES if question["answer"] == "yes" else QUIZ_NO
	wrong = QUIZ_NO if right == QUIZ_YES else QUIZ_YES
	fight = {"if": [wrong], "unless": [beaten]}
	steps = [
		{"unset": [QUIZ_YES, QUIZ_NO]},
		{"dialogue": "cinnabar_gym_quiz_intro"},
		{"dialogue": "cinnabar_gym_quiz_%d_question" % n},
		{"set": [gate], "if": [right]},
		{"dialogue": "cinnabar_gym_quiz_right", "if": [right]},
		{"dialogue": "cinnabar_gym_quiz_wrong", "if": [wrong]},
		dict({"move": trainer, "to": {"near": "player",
			"offsets": [[0, -1], [1, 0], [-1, 0], [0, 1]]}, "optional": True}, **fight),
		dict({"face": "player", "to": trainer}, **fight),
		dict({"face": trainer, "to": "player"}, **fight),
		dict({"dialogue": trainer + "_before"}, **fight),
		dict({"battle": trainer, "win": [beaten, gate]}, **fight),
		{"dialogue": trainer + "_defeated", "if": [wrong, beaten]},
		{"wake_up": True, "if": [wrong], "unless": [beaten]},
		{"unset": [QUIZ_YES, QUIZ_NO]},
	]
	return {"variants": [{"steps": steps}]}


def gym(trainers):
	_, positions = read_plan("cramois_arene")
	quiz = load("gym/cinnabar_quiz.json")
	npcs, cutscenes, dialogues = {}, {}, {}
	for ident, (_, cs, attrs) in by_kind(positions, "dresseur"):
		npcs[ident] = trainer_npc(trainers, ident, cs, attrs)
	_, cs, attrs = positions["auguste"]
	npcs["auguste"] = {"cell": cs[0], "facing": attrs.get("facing", "down"),
		"sprite": SPRITES["blaine"], "dialogue": "cinnabar_blaine"}
	_, cs, attrs = positions["guide"]
	npcs["guide"] = {"cell": cs[0], "facing": attrs.get("facing", "down"),
		"sprite": SPRITES["guide"], "dialogue": "cinnabar_gym_guide"}
	for question in quiz["questions"]:
		n = question["id"]
		beaten = "beaten_" + question["trainer"]
		dialogues["cinnabar_gym_quiz_%d" % n] = {"narration": True, "variants": [
			{"if": [question["gate"]], "pages": ["Porte ouverte."]},
			{"if": [beaten], "pages": ["Porte ouverte."]},
			{"cutscene": "cinnabar_gym_quiz_%d" % n}]}
		dialogues["cinnabar_gym_quiz_%d_question" % n] = {"narration": True, "variants": [{
			"pages": [question["text"]],
			"choice": {"confirm": "OUI", "cancel": "NON", "confirm_set": [QUIZ_YES],
				"cancel_set": [QUIZ_NO], "confirm_pages": [], "cancel_pages": []}}]}
		cutscenes["cinnabar_gym_quiz_%d" % n] = quiz_cutscene(n, question, trainers)
	# Auguste (dossier 28 §8.4, §8.5) : carte de Champion la première fois, combat, Badge Volcan,
	# CT38 une seule fois, les sept Dresseurs marqués battus ; défaite : réveil au Centre.
	won = ["badge_volcano"]
	gym_trainers = sorted(i for i, _ in by_kind(positions, "dresseur"))
	dialogues["cinnabar_blaine"] = {"cutscene": "cinnabar_gym_blaine"}
	cutscenes["cinnabar_gym_blaine"] = {"variants": [
		{"if": won, "steps": [
			{"face": "auguste", "to": "player"},
			{"dialogue": "cinnabar_blaine_after"}]},
		{"steps": [
			{"face": "auguste", "to": "player"},
			{"dialogue": "cinnabar_blaine_before"},
			{"champion_card": BLAINE, "unless": ["blaine_met"]},
			{"set": ["blaine_met"]},
			{"battle": BLAINE, "win": won},
			{"wait": 0.6, "if": won},
			{"dialogue": "cinnabar_blaine_defeated", "if": won},
			{"badge": "volcano", "if": won},
			{"dialogue": "cinnabar_blaine_badge", "if": won},
			{"dialogue": "cinnabar_blaine_tm38", "if": won, "unless": ["tm38_received"]},
			{"give": "tm38", "count": 1, "if": won, "unless": ["tm38_received"]},
			{"set": ["tm38_received"] + ["beaten_" + t for t in gym_trainers], "if": won},
			{"wake_up": True, "unless": won}]}]}
	write("npcs/cinnabar_gym.json", npcs)
	write("cutscenes/cinnabar_gym.json", cutscenes)
	write("dialogues/cinnabar_gym_world.json", dialogues)


def reserve():
	_, positions = read_plan("argenta_musee_reserve")
	npcs, cutscenes, dialogues = {}, {}, {}
	_, cs, attrs = positions["scientifique_comptoir"]
	npcs["scientifique_comptoir"] = {"cell": cs[0], "facing": attrs.get("facing", "down"),
		"sprite": "researcher", "dialogue": "pewter_museum_reserve_counter"}
	_, cs, attrs = positions["scientifique_ambre"]
	npcs["scientifique_ambre"] = {"cell": cs[0], "facing": attrs.get("facing", "down"),
		"sprite": "fossil_researcher", "dialogue": "pewter_museum_reserve_amber"}
	got = "pewter_museum_got_old_amber"
	cutscenes["pewter_museum_old_amber"] = {"variants": [{"unless": [got], "steps": [
		{"dialogue": "pewter_museum_reserve_amber_give"},
		{"give": "old_amber", "count": 1},
		{"set": [got]}]}]}
	# Arbre à Couper devant la porte arrière (contrat des arbustes du J16 / J17).
	cutscenes["cut_tree_pewter_museum"] = {"variants": [{"unless": ["cut_pewter_museum_tree"],
		"steps": [
			{"field_move": "cut", "on": "Entities/MuseumTree"},
			{"set": ["cut_pewter_museum_tree"]},
			{"dialogue": "cut_tree_used"}]}]}
	dialogues["pewter_museum_tree"] = {"narration": True, "variants": [
		{"field": "cut:no_hm", "pages": ["Un petit arbre pousse devant une porte."]},
		{"field": "cut:no_badge", "pages": ["Sans le Badge Cascade, {pokemon}\nn'ose pas couper cet arbuste."]},
		{"field": "cut:no_pokemon", "pages": ["Aucun Pokémon de l'équipe\nne peut couper cet arbuste."]},
		{"field": "cut:ready", "pages": ["{pokemon} peut couper cet arbuste.", "Utiliser Coupe ?"],
			"choice": {"confirm": "COUPER", "cancel": "LAISSER",
				"confirm_cutscene": "cut_tree_pewter_museum", "cancel_pages": []}}]}
	write("npcs/pewter_museum_reserve.json", npcs)
	write("cutscenes/pewter_museum_reserve.json", cutscenes)
	write("dialogues/pewter_museum_reserve_world.json", dialogues)


def trades():
	"""Échanges fixes sur les PNJ du Labo du J24 (X-26) : leurs dialogues sont remplacés."""
	data = load("trades/cinnabar.json")["trades"]
	cutscenes, dialogues = {}, {}
	where = {"papy": "npcs/cinnabar_lab_meeting.json", "canon": "npcs/cinnabar_lab_meeting.json",
		"scientifique_otaria": "npcs/cinnabar_lab_fossil.json"}
	npc_keys = {"papy": "papy", "canon": "canon", "scientifique_otaria": "seel_scientist"}
	for trade_id, t in sorted(data.items()):
		lines = t["lines"]
		base = "cinnabar_trade_" + lines
		done = trade_id + "_done"
		cutscenes[base] = {"variants": [
			{"if": [done], "steps": [{"dialogue": base + "_after"}]},
			{"steps": [
				{"unset": [TRADE_ACCEPTED, TRADE_DECLINED]},
				{"dialogue": base + "_offer"},
				{"dialogue": base + "_refuse", "if": [TRADE_DECLINED]},
				{"trade": trade_id, "wrong": base + "_wrong", "refuse": base + "_refuse",
					"say": ["cinnabar_trade_cable", base + "_done", base + "_thanks"],
					"if": [TRADE_ACCEPTED]},
				{"unset": [TRADE_ACCEPTED, TRADE_DECLINED]}]}]}
		dialogues[base] = {"cutscene": base}
		path = where[t["npc"]]
		npcs = load(path)
		npcs[npc_keys[t["npc"]]]["dialogue"] = base
		write(path, npcs)
	write("cutscenes/cinnabar_trades.json", cutscenes)
	write("dialogues/cinnabar_trades_world.json", dialogues)


def main():
	trainers = {}
	for name in ("pokemon_mansion", "cinnabar_gym"):
		path = os.path.join(DATA, "trainers", name + ".json")
		if not os.path.exists(path):
			sys.exit("Dresseurs absents : " + path)
		raw = load("trainers/%s.json" % name)
		trainers.update(raw.get("trainers", raw))
	mansion(trainers)
	gym(trainers)
	reserve()
	trades()


if __name__ == "__main__":
	main()
