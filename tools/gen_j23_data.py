#!/usr/bin/env python3
"""Données de jeu du jalon 23 (Parc Safari, Porte, maisons, maison du Gardien), depuis les grilles.

Lit `tools/plans/<grille>.txt` (positions) ; écrit :
  - `data/npcs/<carte>.json` (PNJ et objets visibles, d'après les cases de la grille) ;
  - `data/dialogues/j23_<carte>.json` (panneaux, PNJ, objets, Porte, Gardien, Pêcheur expert) ;
  - `data/cutscenes/j23_<carte>.json` (objets, péage, sortie, fin de visite, CS03, CS04).
Textes : dossier 26 §8 (validés par Kevin le 2026-10-16) et annexe A de `docs/tech/jalon-23.md`
(validée le 2026-10-19). Les textes marqués « [R] » manquaient : recommandés, validés d'avance par
Kevin (« validé par Kevin le 2026-10-21, validation d'avance »).
L'Arène de Koga a ses propres données (`tools/build_fuchsia_gym.gd`).

Usage : python3 -I tools/gen_j23_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")

# Grille → carte (une grille de maison de repos sert quatre cartes).
MAPS = [
	("safari_porte", "safari_zone_gate"),
	("safari_centre", "safari_zone_center"),
	("safari_est", "safari_zone_east"),
	("safari_nord", "safari_zone_north"),
	("safari_ouest", "safari_zone_west"),
	("safari_maison_repos", "safari_zone_rest_house_center"),
	("safari_maison_repos", "safari_zone_rest_house_east"),
	("safari_maison_repos", "safari_zone_rest_house_north"),
	("safari_maison_repos", "safari_zone_rest_house_west"),
	("safari_maison_secrete", "safari_zone_secret_house"),
	("parmanie_maison_gardien", "wardens_house"),
]

NARRATION = None
EMPLOYEE = "Employé"
REST = "Visiteur"

# Panneaux de zone (annexe A.1).
REST_SIGN = (NARRATION, ["MAISON DE REPOS"])
TIP = "CONSEIL DE DRESSEUR"
TEXTS = {
	("safari_zone_center", "panneau_maison_repos"): REST_SIGN,
	("safari_zone_center", "panneau_conseils"): (NARRATION, [
		"PARC SAFARI — ZONE CENTRE", "Respectez les Pokémon, ne les nourrissez qu'aux appâts."]),
	("safari_zone_east", "panneau_maison_repos"): REST_SIGN,
	("safari_zone_east", "panneau_conseils"): (NARRATION, [
		TIP, "Le compteur ne baisse que quand tu marches !"]),
	("safari_zone_east", "panneau_zone"): (NARRATION, [
		"PARC SAFARI — ZONE EST", "Ouest : ZONE CENTRE"]),
	("safari_zone_north", "panneau_maison_repos"): REST_SIGN,
	("safari_zone_north", "panneau_conseils_1"): (NARRATION, [
		TIP, "La Maison Secrète est encore plus loin !"]),
	("safari_zone_north", "panneau_zone"): (NARRATION, [
		"PARC SAFARI — ZONE NORD", "Sud : ZONES OUEST et CENTRE"]),
	("safari_zone_north", "panneau_conseils_2"): (NARRATION, [
		TIP, "Les Pokémon se cachent dans les herbes.", "Zigzague pour les débusquer !"]),
	("safari_zone_north", "panneau_conseils_3"): (NARRATION, [
		"GRANDE EXPLORATION !", "Qui trouvera la Maison Secrète ?"]),
	("safari_zone_west", "panneau_maison_repos"): REST_SIGN,
	("safari_zone_west", "panneau_dents_or"): (NARRATION, [
		"Avis : le Gardien a perdu ses dents en or.", "Merci de les lui rapporter !"]),
	("safari_zone_west", "panneau_conseils"): (NARRATION, [
		TIP, "Une CS en prix pour qui trouve", "la Maison Secrète !"]),
	("safari_zone_west", "panneau_zone"): (NARRATION, [
		"PARC SAFARI — ZONE OUEST", "Est : ZONE CENTRE"]),
	# Maison du Gardien (A-13, A-14 : vitrine en deux moitiés ; texte 46 : rocher).
	("wardens_house", "vitrine"): (NARRATION, ["Des photos de Pokémon et des fossiles."]),
	("wardens_house", "vitrine_1"): (NARRATION, ["De vieux souvenirs du Parc Safari."]),
	("wardens_house", "rocher"): (NARRATION, [
		"Un gros rocher.", "Il faudrait beaucoup de force pour le pousser."]),
}
REST_HOUSE_TEXTS = {
	"pnj_1": ["Les Pokémon rapides fuient vite.", "Un caillou, et ils filent encore plus vite !"],
	"pnj_2": ["J'ai marché toute la journée…", "Et pas un seul Tauros."],
	"pnj_3": ["On dit qu'un Leveinard rôde au nord."],
}
# Maison de repos du Centre : deux visiteurs seulement (texte 17 : Est, Nord, Ouest).
REST_HOUSE_ABSENT = {("safari_zone_rest_house_center", "pnj_3")}

SPRITES = {
	("safari_zone_gate", "employe_entree"): "clerk",
	("safari_zone_gate", "employe_zones"): "clerk",
	("safari_zone_secret_house", "pecheur_expert"): "haru",
	("wardens_house", "gardien"): "old_man",
}
REST_SPRITES = {"pnj_1": "naturalist", "pnj_2": "hiker", "pnj_3": "traveler"}

CELL_RE = re.compile(r"^(\d+)(?:\.\.(\d+))?,(\d+)(?:\.\.(\d+))?$")


def read_plan(name):
	positions = {}
	section = None
	with open(os.path.join(PLANS, name + ".txt"), encoding="utf-8") as handle:
		for line in handle:
			line = line.rstrip("\n")
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
			attrs = {}
			for word in words[4:]:
				if "=" in word:
					key, _, value = word.partition("=")
					attrs[key] = value
			positions[words[0]] = (words[1], parse_cells(words[2]), attrs)
	return positions


def parse_cells(text):
	cells = []
	for group in text.split(";"):
		x0, x1, y0, y1 = CELL_RE.match(group).groups()
		for y in range(int(y0), int(y1 or y0) + 1):
			for x in range(int(x0), int(x1 or x0) + 1):
				cells.append((x, y))
	return cells


def write_json(path, data):
	text = json.dumps(data, ensure_ascii=False, indent="\t") + "\n"
	with open(path, "w", encoding="utf-8") as handle:
		handle.write(text)
	print("écrit :", os.path.relpath(path, ROOT))


def dialogue(speaker, pages):
	entry = {}
	if speaker:
		entry["speaker"] = speaker
	else:
		entry["narration"] = True
	entry["pages"] = pages
	return entry


def item_flag(map_id, ident):
	"""Drapeau de ramassage (même règle que `tools/build_j23_maps.gd`)."""
	return "got_%s_%s" % (map_id, ident)


def gate_data():
	"""Porte : employés, péage (textes 1 à 4), sortie (7 à 9), fin de visite (10 à 12)."""
	dialogues = {
		"safari_zone_gate_employe_entree": {"speaker": EMPLOYEE, "variants": [
			{"if": ["safari_active"], "pages": ["Bonne chasse !"]},
			# [R] hors visite : il invite à passer au comptoir.
			{"pages": ["Bienvenue au PARC SAFARI !", "Passe au comptoir pour entrer."]},
		]},
		"safari_zone_gate_employe_zones": {"speaker": EMPLOYEE, "variants": [
			{"unless": ["safari_intro_heard"], "set": ["safari_intro_heard"], "pages": [
				"Le PARC a quatre zones.",
				"La Maison Secrète, au fond, garde un prix pour le premier visiteur !"]},
			{"pages": ["Les Pokémon d'ici sont farouches.", "Un appât les calme, un caillou les agace."]},
		]},
		"safari_gate_welcome": {"speaker": EMPLOYEE, "pages": [
			"Bienvenue au PARC SAFARI !", "L'entrée coûte 500 ₽. Tu tentes ta chance ?"],
			"choice": {"confirm": "OUI", "cancel": "NON", "confirm_set": ["safari_gate_yes"],
				"cancel_pages": ["Reviens quand tu veux !"]}},
		"safari_gate_no_money": dialogue(EMPLOYEE, ["Oh… Il te manque de quoi payer l'entrée."]),
		"safari_gate_paid": dialogue(EMPLOYEE, [
			"Voici 30 SAFARI BALLS !", "Tu as 500 pas. On t'appellera au haut-parleur."]),
		"safari_gate_leave": {"speaker": EMPLOYEE, "pages": ["Tu pars déjà ?"],
			"choice": {"confirm": "OUI", "cancel": "NON", "confirm_set": ["safari_gate_leave_yes"],
				"confirm_pages": ["Les SAFARI BALLS restantes restent ici. Merci !"],
				"cancel_pages": ["Bonne chasse !"]}},
		"safari_speaker_time_up": dialogue(NARRATION, [
			"Ding-dong ! Le temps est écoulé !", "Ta visite du PARC SAFARI est terminée."]),
		"safari_speaker_out_of_balls": dialogue(NARRATION, [
			"Ding-dong ! Tu n'as plus de SAFARI BALLS !", "Ta visite du PARC SAFARI est terminée."]),
		"safari_gate_end": dialogue(EMPLOYEE, ["Alors, bonne pêche ? Reviens vite !"]),
		# [D] (plan §2.15) : partie rechargée dans le Parc sans visite en cours.
		"safari_gate_no_visit": dialogue(NARRATION, ["Tu n'as pas de visite en cours. Retour à l'accueil du PARC SAFARI."]),
	}
	cutscenes = {
		# Comptoir, en venant du sud sans visite : péage (§2.2). NON ou refus : un pas en arrière.
		"j23_safari_gate_enter": {"variants": [{"unless": ["safari_active"], "steps": [
			{"dialogue": "safari_gate_welcome"},
			{"safari": "enter", "if": ["safari_gate_yes"]},
			{"dialogue": "safari_gate_no_money", "if": ["safari_pay_failed"]},
			{"dialogue": "safari_gate_paid", "if": ["safari_active"]},
			{"move": "player", "path": ["down"], "keep_facing": True, "unless": ["safari_active"]},
			{"safari": "clear"},
		]}]},
		# Comptoir, en venant du nord avec une visite : « Partir maintenant ? » (§2.1).
		"j23_safari_gate_leave": {"variants": [{"if": ["safari_active"], "steps": [
			{"dialogue": "safari_gate_leave"},
			{"safari": "leave", "if": ["safari_gate_leave_yes"]},
			{"move": "player", "path": ["up"], "keep_facing": True, "if": ["safari_active"]},
			{"safari": "clear"},
		]}]},
		# Fin de visite (§2.1), jouées par SafariDirector : haut-parleur, fondu vers la Porte, mot
		# de l'employé.
		"j23_safari_time_up": {"steps": [
			{"dialogue": "safari_speaker_time_up"},
			{"change_map": "safari_zone_gate", "at": "arrivee_fin", "facing": "down"},
			{"dialogue": "safari_gate_end"},
		]},
		"j23_safari_out_of_balls": {"steps": [
			{"dialogue": "safari_speaker_out_of_balls"},
			{"change_map": "safari_zone_gate", "at": "arrivee_fin", "facing": "down"},
			{"dialogue": "safari_gate_end"},
		]},
		"j23_safari_no_visit": {"steps": [
			{"change_map": "safari_zone_gate", "at": "arrivee_fin", "facing": "down"},
			{"dialogue": "safari_gate_no_visit"},
		]},
	}
	return dialogues, cutscenes


def secret_house_data():
	"""Maison Secrète : CS03 (textes 18 et 19, §2.8)."""
	dialogues = {
		"safari_zone_secret_house_pecheur_expert": {"speaker": "Pêcheur expert", "variants": [
			{"unless": ["got_hm03"], "cutscene": "j23_secret_house_hm03"},
			{"pages": ["Surf te portera sur l'eau.", "Il te faudra le Badge Âme de Koga."]},
		]},
		"j23_secret_house_prize": dialogue("Pêcheur expert", [
			"Bravo ! Tu as trouvé la Maison Secrète !", "Voici ton prix : la CS03, Surf !"]),
		"j23_secret_house_after": dialogue("Pêcheur expert", [
			"Surf te portera sur l'eau.", "Il te faudra le Badge Âme de Koga."]),
	}
	cutscenes = {"j23_secret_house_hm03": {"variants": [{"unless": ["got_hm03"], "steps": [
		{"face": "pecheur_expert", "to": "player"},
		{"dialogue": "j23_secret_house_prize"},
		{"give": "hm03", "count": 1},
		{"set": ["got_hm03"]},
		{"dialogue": "j23_secret_house_after"},
	]}]}}
	return dialogues, cutscenes


def warden_data():
	"""Gardien : Dents d'Or → CS04 (textes 30 à 34, §2.9)."""
	speaker = "Gardien"
	dialogues = {
		"wardens_house_gardien": {"speaker": speaker, "variants": [
			# Interrompu entre le retrait des Dents d'Or et la CS : il la redonne (RB).
			{"if": ["gave_gold_teeth"], "unless": ["got_hm04"], "cutscene": "j23_warden_hm04"},
			{"if": ["got_hm04"], "pages": [
				"Il faut le Badge Prisme pour s'en servir.", "Essaie-la sur un rocher !"]},
			{"if_items": ["gold_teeth"], "cutscene": "j23_warden_teeth"},
			{"pages": ["Hif fuff hefifoo !", "Hoffuh hoff !"],
				"choice": {"confirm": "OUI", "cancel": "NON", "confirm_pages": ["Huh ? Hoffu… !"],
					"cancel_pages": ["Hoffuh… fuff…"]}},
		]},
		"j23_warden_thanks": dialogue(speaker, [
			"Hfuff… ? Mes dents ! Merci !", "Personne ne me comprenait."]),
		"j23_warden_gift": dialogue(speaker, [
			"Tiens, prends ça. C'est la CS04, Force.", "Un Pokémon fort pourra pousser les rochers."]),
		"j23_warden_after": dialogue(speaker, [
			"Il faut le Badge Prisme pour s'en servir.", "Essaie-la sur un rocher !"]),
	}
	give = [
		{"dialogue": "j23_warden_gift"},
		{"give": "hm04", "count": 1},
		{"set": ["got_hm04"]},
		{"dialogue": "j23_warden_after"},
	]
	cutscenes = {
		"j23_warden_teeth": {"variants": [{"unless": ["gave_gold_teeth"], "steps": [
			{"face": "gardien", "to": "player"},
			{"dialogue": "j23_warden_thanks"},
			{"take": "gold_teeth", "count": 1},
			{"set": ["gave_gold_teeth"]},
		] + give}]},
		"j23_warden_hm04": {"variants": [{"if": ["gave_gold_teeth"], "unless": ["got_hm04"],
			"steps": [{"face": "gardien", "to": "player"}] + give}]},
	}
	return dialogues, cutscenes


def main():
	gate_dialogues, gate_cutscenes = gate_data()
	secret_dialogues, secret_cutscenes = secret_house_data()
	warden_dialogues, warden_cutscenes = warden_data()
	for plan, map_id in MAPS:
		positions = read_plan(plan)
		npcs = {}
		dialogues = {}
		cutscenes = {}
		if map_id == "safari_zone_gate":
			dialogues.update(gate_dialogues)
			cutscenes.update(gate_cutscenes)
		elif map_id == "safari_zone_secret_house":
			dialogues.update(secret_dialogues)
			cutscenes.update(secret_cutscenes)
		elif map_id == "wardens_house":
			dialogues.update(warden_dialogues)
			cutscenes.update(warden_cutscenes)
		for ident, (kind, cells, attrs) in positions.items():
			cell = list(cells[0])
			key = (map_id, ident)
			if kind == "pnj":
				if key in REST_HOUSE_ABSENT:
					continue
				dialogue_id = "%s_%s" % (map_id, ident)
				if plan == "safari_maison_repos":
					sprite = REST_SPRITES[ident]
					dialogues[dialogue_id] = dialogue(REST, REST_HOUSE_TEXTS[ident])
				else:
					sprite = SPRITES[key]
				npcs[ident] = {"cell": cell, "facing": attrs.get("facing", "down"),
					"sprite": sprite, "dialogue": dialogue_id}
			elif kind in ("panneau", "rocher"):
				for index in range(len(cells)):
					suffix = "" if index == 0 else "_%d" % index
					speaker, pages = TEXTS[(map_id, ident + suffix)]
					dialogues["%s_%s%s" % (map_id, ident, suffix)] = dialogue(speaker, pages)
			elif kind == "objet_visible":
				flag = item_flag(map_id, ident)
				dialogue_id = "%s_%s" % (map_id, ident)
				npcs[ident] = {
					"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
					"dialogue": dialogue_id, "verb": "take", "turn_to_player": False,
					"unless": [flag],
				}
				dialogues[dialogue_id] = {"cutscene": dialogue_id}
				cutscenes[dialogue_id] = {"variants": [{"unless": [flag], "steps": [
					{"despawn": ident},
					{"give": attrs["item"], "count": 1, "found": True},
					{"set": [flag]},
				]}]}
			elif kind == "objet_cache":
				flag = item_flag(map_id, ident)
				dialogue_id = "%s_%s" % (map_id, ident)
				dialogues[dialogue_id] = {"cutscene": dialogue_id}
				cutscenes[dialogue_id] = {"variants": [{"unless": [flag], "steps": [
					{"give": attrs["item"], "count": 1, "found": True},
					{"set": [flag]},
				]}]}
		if npcs:
			write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)
		if dialogues:
			write_json(os.path.join(DATA, "dialogues", "j23_%s.json" % map_id), dialogues)
		if cutscenes:
			write_json(os.path.join(DATA, "cutscenes", "j23_%s.json" % map_id), cutscenes)


if __name__ == "__main__":
	main()
