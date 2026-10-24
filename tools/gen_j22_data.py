#!/usr/bin/env python3
"""Données de jeu du jalon 22 (Routes 12 sud à 18, postes, Parmanie), générées depuis les grilles.

Lit `tools/plans/<grille>.txt` (positions) et les brouillons validés `docs/tech/j22-donnees/`
(Dresseurs, répliques, rencontres) ; écrit :
  - `data/trainers/<route>.json`, `data/encounters/<route>.json` (copie des brouillons, + Route 16
    ouest) ;
  - `data/npcs/<carte>.json` (Dresseurs, PNJ, objets visibles, d'après les cases de la grille) ;
  - `data/dialogues/j22_<carte>.json` (répliques des Dresseurs, panneaux, PNJ, objets) ;
  - `data/cutscenes/j22_<carte>.json` (objets visibles et cachés).
Les textes viennent du dossier 25 §16 (validé le 2026-10-16) ; ceux qui manquaient sont marqués
« [R] » dans TEXTS (recommandés, validés d'avance par Kevin le 2026-10-21).

Usage : python3 -I tools/gen_j22_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DRAFTS = os.path.join(ROOT, "docs", "tech", "j22-donnees")
DATA = os.path.join(ROOT, "data")

# Grille → (carte, brouillon des Dresseurs / répliques / rencontres, colonne de départ, largeur).
# Le poste 15 a ses deux étages côte à côte (1F x 0..11, 2F x 13..24).
MAPS = [
	("route_12_sud", "route_12_south", "route_12_sud", 0, None),
	("route_13", "route_13", "route_13", 0, None),
	("route_14", "route_14", "route_14", 0, None),
	("route_15", "route_15", "route_15", 0, None),
	("route_15_gate", "route_15_gate", None, 0, 12),
	("route_15_gate", "route_15_gate_2f", None, 13, 12),
	("route_16_west", "route_16_west", "route_16_ouest", 0, None),
	("route_16_gate", "route_16_gate", None, 0, None),
	("route_17", "route_17", "route_17", 0, None),
	("route_18", "route_18", "route_18", 0, None),
	("route_18_gate", "route_18_gate", None, 0, None),
	("parmanie", "fuchsia_city", None, 0, None),
]

# Sprites provisoires par classe [D] (les planches de la série 25 ne sont pas encore intégrées).
CLASS_SPRITES = {
	"Pêcheur": "haru", "Motard": "rocker", "Ornithologue": "naturalist", "Loubard": "docker",
	"Jeune Dresseur": "youngster", "Jeune Dresseuse": "lass", "Rockeur": "rocker",
	"Beauté": "beauty",
}

# Textes des panneaux, PNJ et Pokémon du décor : (carte, position) → (orateur, pages).
# Dossier 25 §16 ; « / » des bulles = page ; retour à la ligne dans une bulle = « \n ».
NARRATION = None
TEXTS = {
	("route_12_south", "panneau_route_12_sud"): (NARRATION, ["ROUTE 12\nNord : Lavanville"]),
	("route_13", "panneau_route_13"): (NARRATION, ["ROUTE 13\nAttention aux clôtures !"]),
	# [R] conseil du Dresseur (RB : deux panneaux de conseils).
	("route_13", "panneau_conseil"): (NARRATION, [
		"CONSEIL DU DRESSEUR\nUn Dresseur attend parfois", "derrière une clôture.\nRegarde bien autour de toi !"]),
	("route_14", "panneau_route_14"): (NARRATION, ["ROUTE 14"]),
	("route_15", "panneau_route_15"): (NARRATION, ["ROUTE 15\nOuest : Parmanie"]),
	# [R] garde du poste 15 (aucune règle : il salue).
	("route_15_gate", "garde"): ("Garde", ["Parmanie est tout près, à l'ouest.\nBonne route !"]),
	("route_15_gate_2f", "assistant"): ("Assistant", [
		"Je travaille pour le Prof. Chen.\nTon Pokédex en est à {caught} espèces !",
		"Continue ! Chaque Pokémon\na quelque chose à t'apprendre."]),
	("route_15_gate_2f", "jumelles_ouest"): (NARRATION, [
		"Au loin, on voit Parmanie\net la mer qui scintille."]),
	("route_15_gate_2f", "jumelles_est"): (NARRATION, [
		"Au loin, on voit Parmanie\net la mer qui scintille."]),
	("route_16_west", "panneau_piste"): (NARRATION, ["PISTE CYCLABLE\nCéladopole ↕ Parmanie"]),
	("route_16_west", "panneau_route_16"): (NARRATION, ["ROUTE 16\nCéladopole ↔ Piste Cyclable"]),
	("route_17", "panneau_depart"): (NARRATION, ["PISTE CYCLABLE\nCéladopole ↕ Parmanie"]),
	("route_17", "panneau_palier_1"): (NARRATION, [
		"Halte ! Reprends ton souffle.\nLa descente continue plus bas."]),
	("route_17", "panneau_palier_2"): (NARRATION, [
		"Halte ! Reprends ton souffle.\nLa descente continue plus bas."]),
	("route_17", "panneau_palier_3"): (NARRATION, [
		"Halte ! Reprends ton souffle.\nLa descente continue plus bas."]),
	# [R] fin de la Piste.
	("route_17", "panneau_fin"): (NARRATION, ["FIN DE LA PISTE CYCLABLE\nParmanie : Route 18, à l'est"]),
	("route_18", "panneau_piste"): (NARRATION, ["PISTE CYCLABLE\nCéladopole ↕ Parmanie"]),
	("route_18", "panneau_route_18"): (NARRATION, ["ROUTE 18\nEst : Parmanie"]),
	("fuchsia_city", "panneau_ouest"): (NARRATION, ["PARMANIE\nVille ouverte sur la nature"]),
	("fuchsia_city", "panneau_est"): (NARRATION, ["PARMANIE\nVille ouverte sur la nature"]),
	("fuchsia_city", "panneau_arene"): (NARRATION, ["ARÈNE DE PARMANIE\nChampion : Koga"]),
	("fuchsia_city", "panneau_safari"): (NARRATION, ["PARC SAFARI\nDes Pokémon rares vous attendent !"]),
	("fuchsia_city", "panneau_kangourex"): (NARRATION, ["Kangourex garde son petit bien au chaud."]),
	("fuchsia_city", "panneau_ramoloss"): (NARRATION, ["Ramoloss bâille… et oublie pourquoi."]),
	("fuchsia_city", "panneau_leveinard"): (NARRATION, ["LEVEINARD\nUn Pokémon rare, très doux."]),
	("fuchsia_city", "panneau_lokhlass"): (NARRATION, [
		"LOKHLASS\nIl aime transporter les gens sur l'eau."]),
	("fuchsia_city", "panneau_voltorbe"): (NARRATION, [
		"VOLTORBE\nNe pas confondre avec une Poké Ball !"]),
	("fuchsia_city", "panneau_fossile"): (NARRATION, ["FOSSILE\nUn Pokémon d'avant l'histoire."]),
	("fuchsia_city", "kangourex"): (NARRATION, ["Kangourex garde son petit bien au chaud."]),
	("fuchsia_city", "ramoloss"): (NARRATION, ["Ramoloss bâille… et oublie pourquoi."]),
	("fuchsia_city", "garcon_safari"): ("Garçon", [
		"Le Parc Safari, c'est au nord.\nIl paraît qu'on y voit des Pokémon rares !"]),
	("fuchsia_city", "joueur"): ("Joueur", [
		"Koga ? Un vrai ninja, à ce qu'on dit.\nPersonne ne le voit venir."]),
	("fuchsia_city", "pecheur_assis"): ("Pêcheur", ["L'étang est calme aujourd'hui."]),
	("fuchsia_city", "femme_enclos"): ("Femme", [
		"Ces Pokémon viennent du Parc Safari.\nOn les montre aux visiteurs."]),
}

# Sprites des PNJ (carte, position) [D].
PNJ_SPRITES = {
	("route_15_gate", "garde"): "guard",
	("route_15_gate_2f", "assistant"): "researcher",
	("route_16_gate", "garde_piste"): "guard",
	("route_18_gate", "garde_piste"): "guard",
	("fuchsia_city", "garcon_safari"): "kid",
	("fuchsia_city", "joueur"): "gambler",
	("fuchsia_city", "pecheur_assis"): "haru",
	("fuchsia_city", "femme_enclos"): "beauty",
}

# Gardes de la Piste : dialogue à variantes (sans Bicyclette : T-1 ; avec : T-2).
GATE_GUARDS = {
	("route_16_gate", "garde_piste"): "j22_cycling_guard",
	("route_18_gate", "garde_piste"): "j22_cycling_guard",
}

FACINGS = {"up", "down", "left", "right"}
CELL_RE = re.compile(r"^(\d+)(?:\.\.(\d+))?,(\d+)(?:\.\.(\d+))?$")


def read_plan(name):
	"""Positions de la grille : id → (type, cases, attributs, commentaire)."""
	positions = {}
	section = None
	with open(os.path.join(PLANS, name + ".txt"), encoding="utf-8") as handle:
		for raw in handle:
			line = raw.rstrip("\n")
			if line.startswith("POSITIONS"):
				section = "pos"
				continue
			if line.startswith("FIN"):
				section = None
				continue
			if section != "pos" or not line.strip() or line.startswith("#"):
				continue
			body, _, comment = line.partition("#")
			words = body.split()
			ident, kind, cells_text = words[0], words[1], words[2]
			attrs = {}
			for word in words[4:]:
				if "=" in word:
					key, _, value = word.partition("=")
					attrs[key] = value
			positions[ident] = (kind, parse_cells(cells_text), attrs, comment.strip())
	return positions


def parse_cells(text):
	cells = []
	for group in text.split(";"):
		match = CELL_RE.match(group)
		if not match:
			raise ValueError("cases illisibles : " + text)
		x0, x1, y0, y1 = match.groups()
		for y in range(int(y0), int(y1 or y0) + 1):
			for x in range(int(x0), int(x1 or x0) + 1):
				cells.append((x, y))
	return cells


def load_json(path):
	with open(path, encoding="utf-8") as handle:
		return json.load(handle)


def write_json(path, data):
	text = json.dumps(data, ensure_ascii=False, indent="\t") + "\n"
	with open(path, "w", encoding="utf-8") as handle:
		handle.write(text)
	print("écrit :", os.path.relpath(path, ROOT))


def dialogue(speaker, pages):
	entry = {}
	if speaker:
		entry["speaker"] = speaker
	entry["pages"] = pages
	return entry


def main():
	trainers_all = {}
	for plan, map_id, draft, x0, width in MAPS:
		positions = read_plan(plan)
		npcs = {}
		dialogues = {}
		cutscenes = {}
		trainers = {}
		if draft:
			trainers = load_json(os.path.join(DRAFTS, "trainers", draft + ".json"))
			trainers_all.update(trainers)
			dialogues.update(load_json(os.path.join(DRAFTS, "dialogues", draft + ".json")))
		for ident, (kind, cells, attrs, comment) in positions.items():
			inside = [(x - x0, y) for (x, y) in cells if x >= x0 and (width is None or x < x0 + width)]
			if not inside:
				continue
			cell = list(inside[0])
			key = (map_id, ident)
			if kind == "dresseur":
				trainer_id = attrs["trainer"]
				data = trainers[trainer_id]
				name = data["name"]
				klass = " ".join(name.split(" ")[:-1])
				npcs[ident] = {
					"cell": cell, "facing": attrs["facing"],
					"sprite": CLASS_SPRITES[klass],
					"dialogue": trainer_id + "_after",
					"trainer": {
						"id": trainer_id, "sight": int(attrs["sight"]),
						"before": trainer_id + "_before",
						"defeated": trainer_id + "_defeated",
					},
				}
			elif kind == "pnj":
				facing = attrs.get("facing", "down")
				entry = {"cell": cell, "facing": facing, "sprite": PNJ_SPRITES[key]}
				if key in GATE_GUARDS:
					entry["dialogue"] = GATE_GUARDS[key]
				else:
					dialogue_id = "%s_%s" % (map_id, ident)
					entry["dialogue"] = dialogue_id
					speaker, pages = TEXTS[key]
					dialogues[dialogue_id] = dialogue(speaker, pages)
				npcs[ident] = entry
			elif kind in ("panneau", "pokemon"):
				dialogue_id = "%s_%s" % (map_id, ident)
				speaker, pages = TEXTS[key]
				dialogues[dialogue_id] = dialogue(speaker, pages)
			elif kind == "objet_visible":
				flag = attrs["drapeau"]
				npcs[ident] = {
					"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
					"dialogue": ident, "verb": "take", "turn_to_player": False,
					"unless": [flag],
				}
				dialogues[ident] = {"cutscene": ident}
				cutscenes[ident] = {"variants": [{"unless": [flag], "steps": [
					{"despawn": ident},
					{"give": item_of(attrs["item"]), "count": 1, "found": True},
					{"set": [flag]},
				]}]}
			elif kind == "cache":
				flag = attrs["drapeau"]
				dialogues[ident] = {"cutscene": ident}
				cutscenes[ident] = {"variants": [{"unless": [flag], "steps": [
					{"give": item_of(attrs["item"]), "count": 1, "found": True},
					{"set": [flag]},
				]}]}
		if npcs:
			write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)
		if dialogues:
			write_json(os.path.join(DATA, "dialogues", "j22_%s.json" % map_id), dialogues)
		if cutscenes:
			write_json(os.path.join(DATA, "cutscenes", "j22_%s.json" % map_id), cutscenes)
		if trainers:
			write_json(os.path.join(DATA, "trainers", draft + ".json"), trainers)
		if draft:
			source = os.path.join(DRAFTS, "encounters", draft + ".json")
			if os.path.exists(source):
				write_json(os.path.join(DATA, "encounters", draft + ".json"), load_json(source))
	# Route 16 ouest (voie haute) : RB version Rouge (dossier §8.8), pondérations RB [D].
	write_json(os.path.join(DATA, "encounters", "route_16_ouest.json"), {
		"route_16_west_grass": {
			"maps": ["route_16_west"], "terrain": "grass", "rate": 25,
			"ramp": {"from_step": 15, "max_steps": 20},
			"slots": [
				{"species": "spearow", "levels": [20, 20], "weight": 51},
				{"species": "spearow", "levels": [22, 22], "weight": 51},
				{"species": "rattata", "levels": [18, 18], "weight": 39},
				{"species": "doduo", "levels": [20, 20], "weight": 25},
				{"species": "rattata", "levels": [20, 20], "weight": 25},
				{"species": "doduo", "levels": [18, 18], "weight": 25},
				{"species": "doduo", "levels": [22, 22], "weight": 13},
				{"species": "rattata", "levels": [22, 22], "weight": 13},
				{"species": "raticate", "levels": [23, 23], "weight": 11},
				{"species": "raticate", "levels": [25, 25], "weight": 3},
			],
		},
	})
	print("Dresseurs :", len(trainers_all))


# CT20 (Frénésie) : l'effet « rage » n'existe pas dans le moteur (pending_effects) ; T10 [D] :
# CT09 Bélier, capacité existante jamais distribuée (recul déjà codé).
ITEM_FIXES = {"tm20": "tm09"}


def item_of(item):
	return ITEM_FIXES.get(item, item)


if __name__ == "__main__":
	main()
