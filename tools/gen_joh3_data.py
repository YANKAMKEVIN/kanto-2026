#!/usr/bin/env python3
"""Données de jeu du jalon JOH3 (Routes 37, 36, 35, Doublonville, Souterrain), générées depuis
les grilles.

Lit les positions de `tools/plans/route_37.txt`, `route_36.txt`, `route_35.txt`,
`doublonville.txt`, `souterrain.txt` (grilles validées le 2026-11-02, elles font foi) et écrit,
d'après `docs/design/dossier-joh-04-doublonville.md` (textes D-1 à D-38 validés le 2026-11-02,
Dresseurs §6, objets §11, PNJ de la semaine §10, rencontres §5, Grand Magasin §8, œuf §7, maison
du lien §9) et le plan `docs/tech/jalon-joh3.md` §2 :
  - `data/npcs/<carte>.json` (Dresseurs, PNJ, objets visibles, habitants des intérieurs) ;
  - `data/trainers/route_37.json`, `route_36.json`, `route_35.json`, `goldenrod_underground.json` ;
  - `data/encounters/route_37.json`, `route_36.json`, `route_35.json` (tables par moment, Surf) ;
  - `data/dialogues/joh3_<carte>.json`, `joh3_goldenrod_interiors.json`, `joh3_week.json` ;
  - `data/cutscenes/joh3_<carte>.json`, `joh3_goldenrod_interiors.json`, `joh3_week.json`.
Les textes absents du dossier sont marqués « draft » et listés dans
`tests/integration/test_no_draft_in_data.gd` (PENDING_DRAFTS).

Usage : python3 -I tools/gen_joh3_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")

# Grille → identifiant de carte.
MAPS = [("route_37", "route_37"), ("route_36", "route_36"), ("route_35", "route_35"),
	("doublonville", "goldenrod_city"), ("souterrain", "goldenrod_underground")]

TRAINER_SPRITES = {
	"route_37_birdkeeper_lise": "bird_keeper", "route_37_grunt_a": "rocket_grunt_m",
	"route_37_grunt_b": "rocket_grunt_f", "route_36_scout_max": "scout",
	"route_36_medium_ernest": "youngster", "route_35_fisher_gaston": "fisher_route_12",
	"route_35_camper_anna": "lass", "route_35_gentleman_armand": "gentleman",
	"goldenrod_underground_grunt_c": "rocket_grunt_m",
	"goldenrod_underground_grunt_d": "rocket_grunt_f",
	"goldenrod_underground_boss": "rocket_grunt_m",
}
ROLE_SPRITES = {"agent": "guard", "livreur": "courier", "jardiniere": "beauty"}
WEEKDAYS = {"lundi": "monday", "mardi": "tuesday", "mercredi": "wednesday", "jeudi": "thursday",
	"vendredi": "friday", "samedi": "saturday", "dimanche": "sunday"}
PERIODS = {"nuit": ["night"], "jour": ["morning", "day"]}

# Dresseurs (dossier §6) : (nom, prize_per_level [D], équipe, ia [D]).
TRAINERS = {
	"route_37": {
		"route_37_birdkeeper_lise": ("Ornithologue Lise", 25, [("pidgey", 14), ("hoothoot", 15)]),
		"route_37_grunt_a": ("Sbire Rocket", 30, [("houndour", 15), ("rattata", 14)]),
		"route_37_grunt_b": ("Sbire Rocket", 30, [("murkrow", 15), ("ekans", 15)]),
	},
	"route_36": {
		"route_36_scout_max": ("Scout Max", 30, [("growlithe", 15), ("nidoran_m", 14)]),
		"route_36_medium_ernest": ("Médium Ernest", 30, [("abra", 16)]),
	},
	"route_35": {
		"route_35_fisher_gaston": ("Pêcheur Gaston", 35, [("magikarp", 13), ("magikarp", 13),
			("poliwag", 15)]),
		"route_35_camper_anna": ("Campeuse Anna", 20, [("nidoran_f", 15), ("ponyta", 16)]),
		"route_35_gentleman_armand": ("Gentleman Armand", 70, [("growlithe", 17)]),
	},
	"goldenrod_underground": {
		"goldenrod_underground_grunt_c": ("Sbire Rocket", 30, [("rattata", 15), ("ekans", 16)]),
		"goldenrod_underground_grunt_d": ("Sbire Rocket", 30, [("murkrow", 16), ("houndour", 16)]),
		"goldenrod_underground_boss": ("Chef de bande", 40, [("houndour", 17), ("murkrow", 17),
			("koffing", 18)]),
	},
}
# Classes de combat des noms sans préfixe connu ou des Sbires femmes [D]. Campeuse Anna :
# pas de classe « campeuse » peinte, elle prend la classe féminine Jeune Dresseuse [D] ;
# Médium Ernest : feuille youngster, comme les Médiums de l'Arène de Safrania.
TRAINER_CLASSES = {
	"route_37_grunt_b": "sbire_rocket_f", "route_35_camper_anna": "jeune_dresseuse",
	"goldenrod_underground_grunt_d": "sbire_rocket_f", "goldenrod_underground_boss": "sbire_rocket",
}
SMART = {"goldenrod_underground_boss"}

# Répliques des Dresseurs (D-2, D-3, D-4, D-7, D-9, D-29) : avant · défaite · après.
TRAINER_LINES = {
	"route_37_birdkeeper_lise": (["Chut ! Tu vas faire fuir\nles oiseaux."],
		["Bon, ils sont partis\nde toute façon."],
		["La nuit, il y a des gens bizarres\nsur cette route."]),
	"route_37_grunt_a": (["Un gamin seul, la nuit ?\nDonne-moi tes Pokémon !"],
		["Tu n'es pas un gamin ordinaire…"], ["On a l'ordre de ne pas traîner.\nJe file."]),
	"route_37_grunt_b": (["On t'a vu à Rosalia, toi."], ["Le chef ne va pas aimer ça."],
		["Doublonville, c'est chez nous,\nmaintenant."]),
	"route_36_scout_max": (["Un scout est toujours prêt !"], ["Pas assez prêt, apparemment."],
		["Doublonville est au sud,\npar la Route 35."]),
	"route_36_medium_ernest": (["Mon Abra a vu ta victoire…\nou ta défaite ?"], ["Il avait mal vu."],
		["Il a dormi pendant tout le combat."]),
	"route_35_fisher_gaston": (["Ça mord ! Ah non, c'est toi."], ["Raté."],
		["Les Ptitard aiment l'étang."]),
	"route_35_camper_anna": (["Tu veux passer ?\nIl faut me battre !"],
		["D'accord, la ville est à toi."], ["Doublonville est immense,\ntu vas t'y perdre !"]),
	"route_35_gentleman_armand": (["Un combat, entre gens\nbien élevés ?"], ["Quelle élégance."],
		["Ma radio ne capte plus\nque des grésillements."]),
	"goldenrod_underground_grunt_c": (["Le Souterrain est à nous,\ndégage !"], ["Ouille."],
		["Va voir le chef, au fond.\nIl va t'apprendre la politesse."]),
	"goldenrod_underground_grunt_d": (["Encore toi ?\nOn t'avait dit de disparaître !"],
		["Tu es tenace."], ["Le chef ne recule jamais."]),
	# D-30, D-31 ; l'indice D-32 est sa réplique « après » (elle pose johto_azalea_clue).
	"goldenrod_underground_boss": (["Alors c'est toi, le gamin\nqui fouine partout.",
		"Ici, c'est notre territoire.\nPersonne ne passe."],
		["Grr… Comment un gamin peut-il\nêtre aussi fort ?"], None),
}
CLUE = ["Tu crois qu'on est seulement ici ?",
	"Les copains font de bonnes affaires\nà Écorcia, au sud.",
	"Les queues de Ramoloss,\nça se vend très cher.",
	"Et les ordres viennent d'en haut.\nDe très haut."]

NARRATION = None
# JOH5 (T-1, T-37) : les messages du haut-parleur pendant et après la prise de la Tour Radio.
SPEAKER_ROCKET_TEXT = ["Ici Radio Rocket.", "À tous les membres de la Team Rocket, où que vous soyez :",
	"Giovanni, reviens ! La Team Rocket t'attend à Johto.",
	"Rassemblez-vous. Le grand retour approche."]
SPEAKER_AFTER_TEXT = ["Ici Radio Doublonville ! Les programmes reprennent.",
	"Et un grand merci à un jeune Dresseur venu de Kanto !"]
SPEAKER_TEXT = ["Ici Radio Doublonville…\nbonne jour…", "…crrr… R… reviens… crrr…",
	"…nous nous excusons\npour cette interruption."]
# Textes des panneaux, PNJ et examens : (carte, position) → (orateur, pages[, brouillon]).
TEXTS = {
	("route_37", "panneau_route"): (NARRATION, ["ROUTE 37\nRosalia — Route 36"]),
	("route_36", "panneau_route"): (NARRATION, ["ROUTE 36\nRoute 37 — Route 35"]),
	("route_36", "panneau_pont"): (NARRATION, ["Pont en travaux.",
		"Passage interdit jusqu'à nouvel ordre."]),
	# Grille du Parc National « fermé pour entretien » (dossier §3.1) : texte [D] à relire.
	("route_36", "grille_parc"): (NARRATION, ["La grille du Parc National est fermée.",
		"Un écriteau : « Fermé pour entretien. »"], True),
	("route_35", "panneau_route"): (NARRATION, ["ROUTE 35\nDoublonville — Route 36"]),
	("goldenrod_city", "panneau_ville"): (NARRATION,
		["DOUBLONVILLE\nLa ville scintillante,\nau carrefour de Johto"]),
	("goldenrod_underground", "panneau_souterrain"): (NARRATION,
		["SOUTERRAIN DE DOUBLONVILLE\nBoutiques ouvertes de 10 h à 20 h",
			"(un papier collé :\n« Fermé jusqu'à nouvel ordre »)"]),
}
WEEK = {
	# id : (orateur, drapeau, jour, objet, nombre, pages avant, ligne système, page après)
	"week_wednesday_mercedes": ("Mercédès", "week_wednesday_gift", "wednesday", "great_ball", 3,
		["Le mercredi, j'arrose les fleurs\nde la route.",
			"Tu as l'air pressé…\nTiens, ça pourra servir."],
		"{player} reçoit 3 Super Balls !", "Reviens un mercredi,\nles fleurs seront plus belles."),
	"week_thursday_jerome": ("Jérôme", "week_thursday_gift", "thursday", "fresh_water", 3,
		["Le jeudi, je livre\nle Grand Magasin.",
			"Oups, il me reste des bouteilles\nen trop. Prends !"],
		"{player} reçoit 3 Eaux Fraîches !", "À jeudi prochain !"),
}
WEEK_ROLES = {"jardiniere": "week_wednesday_mercedes", "livreur": "week_thursday_jerome"}

# Rencontres (dossier §5) : (identifiant, moments, taux, terrain, créneaux (espèce, min, max,
# poids)). Route 36 : Chenipan le matin seulement, reporté sur Fouinette le jour.
ENCOUNTERS = {
	"route_37": [
		("route_37_grass_day", ["morning", "day"], 25, "grass", [("furret", 13, 16, 25),
			("growlithe", 13, 16, 25), ("pidgey", 13, 16, 20), ("ponyta", 13, 16, 15),
			("rattata", 13, 16, 15)]),
		("route_37_grass_night", ["night"], 25, "grass", [("hoothoot", 13, 16, 35),
			("houndour", 13, 16, 30), ("oddish", 13, 16, 20), ("raticate", 13, 16, 15)]),
	],
	"route_36": [
		("route_36_grass_morning", ["morning"], 25, "grass", [("sentret", 12, 15, 30),
			("growlithe", 12, 15, 20), ("nidoran_f", 12, 15, 15), ("nidoran_m", 12, 15, 15),
			("pidgey", 12, 15, 10), ("caterpie", 12, 15, 10)]),
		("route_36_grass_day", ["day"], 25, "grass", [("sentret", 12, 15, 40),
			("growlithe", 12, 15, 20), ("nidoran_f", 12, 15, 15), ("nidoran_m", 12, 15, 15),
			("pidgey", 12, 15, 10)]),
		("route_36_grass_night", ["night"], 25, "grass", [("hoothoot", 12, 15, 40),
			("nidoran_f", 12, 15, 15), ("nidoran_m", 12, 15, 15), ("oddish", 12, 15, 20),
			("rattata", 12, 15, 10)]),
	],
	"route_35": [
		("route_35_grass_day", ["morning", "day"], 25, "grass", [("nidoran_f", 13, 16, 15),
			("nidoran_m", 13, 16, 15), ("pidgey", 13, 16, 20), ("marill", 13, 16, 20),
			("abra", 13, 16, 15), ("sentret", 13, 16, 15)]),
		("route_35_grass_night", ["night"], 25, "grass", [("hoothoot", 13, 16, 30),
			("nidoran_f", 13, 16, 15), ("nidoran_m", 13, 16, 15), ("oddish", 13, 16, 20),
			("marill", 13, 16, 20)]),
		# Étang (Surf, JH-36) : toute la journée.
		("route_35_surf", None, 10, "water", [("poliwag", 13, 17, 60), ("marill", 13, 17, 40)]),
	],
}

# Identifiants d'objets déjà pris par le souterrain de Kanto (`underground_7_8.json`) : préfixe
# de la carte.
def object_id(ident):
	return "goldenrod_underground_" + ident[len("souterrain_"):] \
		if ident.startswith("souterrain_") else ident


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


def write_json(path, data):
	text = json.dumps(data, ensure_ascii=False, indent="\t") + "\n"
	with open(path, "w", encoding="utf-8") as handle:
		handle.write(text)
	print("écrit :", os.path.relpath(path, ROOT))


def dialogue(speaker, pages, draft=False):
	entry = {}
	if speaker:
		entry["speaker"] = speaker
	else:
		entry["narration"] = True
	if draft:
		entry["draft"] = True
	entry["pages"] = pages
	return entry


def item_scene(ident, item, count, flag, visible):
	steps = []
	if visible:
		steps.append({"despawn": ident})
	steps.append({"give": item, "count": count, "found": True})
	steps.append({"set": [flag]})
	return {"variants": [{"unless": [flag], "steps": steps}]}


def guard_scene(guard, flag, dialogue_id, back):
	return {"variants": [{"unless": [flag], "steps": [
		{"face": guard, "to": "player"},
		{"face": "player", "to": guard},
		{"dialogue": dialogue_id},
		{"move": "player", "path": [back], "keep_facing": True},
	]}]}


def week_scene(flag, item, count, received_id):
	return {"variants": [{"unless": [flag], "steps": [
		{"give": item, "count": count},
		{"dialogue": received_id},
		{"set": [flag]},
	]}]}


def trainer_entry(trainer_id, attrs, cell):
	entry = {
		"cell": cell, "facing": attrs["facing"], "sprite": TRAINER_SPRITES[trainer_id],
		"dialogue": trainer_id + "_after",
		"trainer": {"id": trainer_id, "sight": int(attrs["sight"]),
			"before": trainer_id + "_before", "defeated": trainer_id + "_defeated"},
	}
	if "periode" in attrs:
		entry["if_period"] = PERIODS[attrs["periode"]]
	return entry


def main():
	for plan, map_id in MAPS:
		positions = read_plan(plan)
		npcs = {}
		dialogues = {}
		cutscenes = {}
		trainers = TRAINERS.get(map_id, {})
		trainer_data = {}
		for trainer_id, (name, prize, team) in trainers.items():
			before, defeated, after = TRAINER_LINES[trainer_id]
			dialogues[trainer_id + "_before"] = dialogue(name, before)
			if after is None:
				# JH-31 : le chef vaincu dit D-31 puis l'indice D-32 tout de suite (le joueur ne
				# peut pas le manquer) ; le drapeau est posé à la fin de la réplique.
				dialogues[trainer_id + "_defeated"] = {"speaker": name, "variants": [
					{"set": ["johto_azalea_clue"], "pages": defeated + CLUE}]}
			else:
				dialogues[trainer_id + "_defeated"] = dialogue(name, defeated)
			if after is None:
				# Le chef du Souterrain : l'indice (D-32) pose johto_azalea_clue, chaque fois
				# qu'on lui parle (une partie fermée juste après le combat le retrouve).
				dialogues[trainer_id + "_after"] = {"speaker": name, "variants": [
					{"set": ["johto_azalea_clue"], "pages": CLUE}]}
			else:
				dialogues[trainer_id + "_after"] = dialogue(name, after)
			data = {"name": name}
			if trainer_id in TRAINER_CLASSES:
				data["class"] = TRAINER_CLASSES[trainer_id]
			data.update({
				"ai": "smart" if trainer_id in SMART else "random", "can_lose": False,
				"heal_after": False, "gives_exp": True, "prize_money": 0,
				"prize_per_level": prize,
				"team": [{"species": species, "level": level} for species, level in team],
			})
			trainer_data[trainer_id] = data
		for ident, (kind, cells, attrs, comment) in positions.items():
			key = (map_id, ident)
			cell = list(cells[0])
			if kind == "dresseur":
				npcs[ident] = trainer_entry(attrs["trainer"], attrs, cell)
			elif kind == "pnj":
				role = attrs.get("role", "")
				entry = {"cell": cell, "facing": attrs.get("facing", "down"),
					"sprite": ROLE_SPRITES[role]}
				if "jour" in attrs:
					entry["if_weekday"] = [WEEKDAYS[attrs["jour"]]]
				if role in WEEK_ROLES:
					entry["dialogue"] = WEEK_ROLES[role]
					npcs[ident] = entry
				elif role == "agent":
					# D-33 / D-34 : l'agent barre la sortie sud, puis se range en (33, 55) [D].
					entry["dialogue"] = "goldenrod_city_agent"
					entry["unless"] = ["johto_azalea_clue"]
					npcs[ident] = entry
					npcs["agent_range"] = {"cell": [cell[0], cell[1] - 1],
						"facing": "right", "sprite": "guard", "dialogue": "goldenrod_city_agent",
						"if": ["johto_azalea_clue"]}
					dialogues["goldenrod_city_agent"] = {"speaker": "Agent", "variants": [
						{"unless": ["johto_azalea_clue"], "pages": ["La Route 34 ?\nPas aujourd'hui.",
							"Avec ce qui se passe\ndans le Souterrain,\non ne laisse sortir personne."]},
						{"if": ["johto_azalea_clue"], "pages": [
							"C'est toi qui as chassé les hommes\ndu Souterrain ?",
							"Merci.\nLa route du sud est ouverte."]},
					]}
			elif kind in ("panneau", "examen"):
				dialogues["%s_%s" % (map_id, ident)] = dialogue(*TEXTS[key])
			elif kind == "decor" and ident == "haut_parleur":
				# JOH5 : T-1 au retour du Bois aux Chênes, T-37 après Cenere (dossier JOH-06 §4, §14).
				dialogues["goldenrod_speaker"] = {"speaker": "Haut-parleur", "variants": [
					{"if": ["johto_cenere_defeated"], "pages": SPEAKER_AFTER_TEXT},
					{"if": ["johto_slowpoke_well_cleared"], "pages": SPEAKER_ROCKET_TEXT},
					{"pages": SPEAKER_TEXT},
				]}
			elif kind == "objet_visible":
				ident = object_id(ident)
				flag = "got_" + ident
				npcs[ident] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
					"dialogue": ident, "verb": "take", "turn_to_player": False, "unless": [flag]}
				dialogues[ident] = {"cutscene": ident}
				cutscenes[ident] = item_scene(ident, attrs["item"], int(attrs.get("count", 1)),
					flag, True)
			elif kind == "cache":
				ident = object_id(ident)
				flag = "got_" + ident
				dialogues[ident] = {"cutscene": ident}
				cutscenes[ident] = item_scene(ident, attrs["item"], int(attrs.get("count", 1)),
					flag, False)
			elif kind == "declencheur":
				if ident == "arrivee_titre":
					# Étape 4 : titre de zone (automatique) puis le haut-parleur (D-10), une fois.
					cutscenes["goldenrod_arrival"] = {"variants": [
						{"unless": ["johto_goldenrod_arrived"], "steps": [
							{"set": ["johto_goldenrod_arrived"]},
							{"dialogue": "goldenrod_speaker"},
						]}]}
				elif ident == "barriere_sud":
					cutscenes["goldenrod_south_guard"] = guard_scene("agent_sud",
						"johto_azalea_clue", "goldenrod_city_agent", "up")
		write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)
		write_json(os.path.join(DATA, "dialogues", "joh3_%s.json" % map_id), dialogues)
		if cutscenes:
			write_json(os.path.join(DATA, "cutscenes", "joh3_%s.json" % map_id), cutscenes)
		if trainers:
			write_json(os.path.join(DATA, "trainers", map_id + ".json"), trainer_data)
		if map_id in ENCOUNTERS:
			tables = {}
			for table_id, periods, rate, terrain, slots in ENCOUNTERS[map_id]:
				table = {"maps": [map_id], "terrain": terrain}
				if periods:
					table["period"] = periods
				table["rate"] = rate
				table["ramp"] = {"from_step": 15, "max_steps": 20}
				table["slots"] = [{"species": s, "levels": [lo, hi], "weight": w}
					for s, lo, hi, w in slots]
				tables[table_id] = table
			write_json(os.path.join(DATA, "encounters", map_id + ".json"), tables)
	write_interiors()
	write_week()


# Promotion du jour (dossier §8.2, D-21) : jour → article affiché sur le panneau.
PROMOTION_ARTICLES = [("monday", "Poké Ball"), ("tuesday", "Potion et Super Potion"),
	("wednesday", "Super Ball"), ("thursday", "Repousse et Super Repousse"),
	("friday", "Rappel"), ("saturday", "Total Soin"), ("sunday", "boissons du toit")]
CLERK = ["Bonjour ! Qu'est-ce qu'il te faut aujourd'hui ?"]
DISPENSER = ["Un distributeur de boissons fraîches."]


def write_interiors():
	"""Centre (infirmière, Orme et l'œuf), Grand Magasin (hôtesse, panneau de la promotion,
	vendeurs, distributeurs, vieil homme, Améliorator), maison du lien (Mme Clémence), maisons 1
	(D-37) et 2 ([D]), textes D-18 et D-19 de la Tour Radio (placés par le JOH5)."""
	dialogues = {
		# Œuf de Togepi (JH-32, D-12 à D-15). {g:…|…} : accord de la joueuse (JR-7) ;
		# {pokemon} : le compagnon (sans compagnon, la page est omise).
		"goldenrod_orme": {"speaker": "Orme", "variants": [
			{"unless": ["johto_goldenrod_orme_met"], "set": ["johto_goldenrod_orme_met"],
				"cutscene": "goldenrod_orme_egg", "pages": [
					"{player} !\nTu es {g:venu|venue} jusqu'ici, bravo.",
					"Et ton {pokemon}\na bien grandi.",
					"Ici aussi, la Team Rocket s'agite.",
					"La Tour Radio diffuse des messages\nbrouillés depuis une semaine.",
					"Et des hommes en noir traînent\ndans le Souterrain."]},
			# Équipe pleine la première fois : il redonne l'œuf dès qu'on lui reparle.
			{"unless": ["johto_egg_received"], "cutscene": "goldenrod_orme_egg"},
			{"pages": ["Fais attention à toi, {player}.",
				"Ceux qui ont volé tes Pokémon\nne sont pas loin."]},
		]},
		"goldenrod_orme_egg_talk": dialogue("Orme", ["J'ai quelque chose pour toi.",
			"Un ami de Doublonville\nm'a confié cet œuf.",
			"Je ne sais pas encore\nce qui en sortira.",
			"Garde-le dans ton équipe :\nles Pokémon nés d'un œuf s'attachent\nvite à qui les a portés."]),
		"goldenrod_orme_egg_received": dialogue(NARRATION, ["{player} reçoit un Œuf !"]),
		"goldenrod_orme_full": dialogue("Orme", ["Ton équipe est pleine…",
			"Et le réseau de stockage\nest toujours coupé.",
			"Reviens me voir quand tu auras\nune place."]),
		# Tour Radio (D-18, D-19) : joués par le hall du JOH5 (goldenrod_radio_tower_1f).
		"goldenrod_radio_tower_impostor_closed": dialogue("Employé", [
			"Désolé, la Tour est fermée\nau public.", "Travaux techniques.",
			"Revenez… plus tard.\nBeaucoup plus tard."]),
		"goldenrod_radio_tower_elevator_closed": dialogue(NARRATION, [
			"Un écriteau : « Étages fermés ».",
			"Des voix étouffées descendent\nde là-haut."]),
		# Grand Magasin (D-20 à D-23).
		"goldenrod_dept_hostess": dialogue("Hôtesse", [
			"Bienvenue au Grand Magasin\nde Doublonville !",
			"Les soins au 1er,\nles accessoires au 2e,",
			"et une vue magnifique sur le toit."]),
		"goldenrod_dept_board": {"narration": True, "variants": [
			{"if_weekday": day, "pages": ["PROMOTION DU JOUR\nAujourd'hui, %s\nà moitié prix !"
				% article]} for day, article in PROMOTION_ARTICLES] + [
			# Sans jour (ne devrait pas arriver : Doublonville est à Johto).
			{"pages": ["PROMOTION DU JOUR"]}]},
		"goldenrod_dept_2f_clerk": {"speaker": "Marchand", "pages": CLERK,
			"action": "open_shop", "shop": "goldenrod_dept_2f"},
		"goldenrod_dept_3f_clerk": {"speaker": "Marchand", "pages": CLERK,
			"action": "open_shop", "shop": "goldenrod_dept_3f"},
		"goldenrod_dept_roof_upgrade_found": dialogue(NARRATION, [
			"{player} trouve un Améliorator !", "Une étrange boîte de la Sylphe SARL."]),
		"goldenrod_dept_roof_old_man": dialogue("Vieil homme", ["D'ici, on voit toute la ville.",
			"Et la Tour Radio.",
			"Depuis une semaine, sa lumière\nclignote toute la nuit."]),
		"goldenrod_dept_roof_upgrade": {"cutscene": "goldenrod_dept_roof_upgrade"},
		# Maison du lien (D-24 à D-27) : D-24, le palier, D-26 ; œuf en tête : D-27.
		"goldenrod_bond_house_clemence": {"speaker": "Mme Clémence", "variants": [
			{"if_lead_bond_tier": "egg", "pages": ["Un œuf !\nJe ne peux pas encore lire son cœur.",
				"Mais il entend déjà ta voix,\ntu sais."]},
		] + [{"if_lead_bond_tier": tier, "pages": BOND_INTRO + [line] + BOND_AFTER}
			for tier, line in enumerate(BOND_TIERS)] + [
			# Équipe vide (ne devrait pas arriver) : l'accueil seul.
			{"pages": BOND_INTRO}]},
		# JOH5 (T-35) : son mari est rentré ; don et textes dans `data/*/joh5_radio_tower.json`.
		"goldenrod_house_1_woman": {"speaker": "Femme", "variants": [
			{"if": ["goldenrod_husband_gift"], "pages": [
				"Il dort depuis hier soir. Il dit qu'il ne remontera jamais dans le noir."]},
			{"if": ["johto_act2"], "cutscene": "goldenrod_husband_gift"},
			{"pages": ["Mon mari travaille à la Tour Radio.",
				"Il n'est pas rentré\ndepuis trois jours.", "Ils disent qu'il fait\ndes heures en plus…"]},
		]},
		# Maison 2 : aucun texte au dossier [D].
		"goldenrod_house_2_man": dialogue("Habitant", ["Le soir, on entend la radio\ngrésiller dans toute la rue.",
			"Avant, elle passait de la musique\ntoute la nuit."], True),
	}
	for drink in ("water", "soda", "lemonade"):
		dialogues["goldenrod_dept_roof_" + drink] = {"narration": True, "pages": DISPENSER,
			"action": "open_shop", "shop": "goldenrod_dept_roof_" + drink}
	cutscenes = {
		"goldenrod_orme_egg": {"variants": [{"unless": ["johto_egg_received"], "steps": [
			{"dialogue": "goldenrod_orme_egg_talk"},
			{"give_egg": "togepi", "steps": 2000, "say": "goldenrod_orme_egg_received",
				"say_full": "goldenrod_orme_full", "flag": "johto_egg_received"},
		]}]},
		"goldenrod_dept_roof_upgrade": {"variants": [{"unless": ["goldenrod_upgrade_taken"],
			"steps": [
				{"despawn": "upgrade_ball"},
				{"give": "up_grade", "count": 1},
				{"dialogue": "goldenrod_dept_roof_upgrade_found"},
				{"set": ["goldenrod_upgrade_taken"]},
			]}]},
	}
	npcs = {
		"goldenrod_center": {
			"nurse": {"cell": [7, 3], "facing": "down", "sprite": "nurse"},
			"orme": {"cell": [10, 5], "facing": "left", "sprite": "researcher",
				"dialogue": "goldenrod_orme"},
		},
		"goldenrod_dept_store_1f": {
			"hostess": {"cell": [9, 4], "facing": "down", "sprite": "hostess"},
		},
		"goldenrod_dept_store_2f": {
			"clerk_a": {"cell": [7, 4], "facing": "down", "sprite": "clerk"},
			"clerk_b": {"cell": [12, 4], "facing": "down", "sprite": "clerk"},
		},
		"goldenrod_dept_store_3f": {
			"clerk": {"cell": [10, 4], "facing": "down", "sprite": "clerk"},
		},
		"goldenrod_dept_store_roof": {
			"old_man": {"cell": [5, 6], "facing": "up", "sprite": "old_man",
				"dialogue": "goldenrod_dept_roof_old_man"},
			"upgrade_ball": {"cell": [17, 5], "facing": "down", "sprite": "object/poke_ball_ground",
				"dialogue": "goldenrod_dept_roof_upgrade", "verb": "take",
				"turn_to_player": False, "unless": ["goldenrod_upgrade_taken"]},
		},
		"goldenrod_bond_house": {
			"clemence": {"cell": [7, 5], "facing": "down", "sprite": "aoki",
				"dialogue": "goldenrod_bond_house_clemence"},
		},
		"goldenrod_house_1": {
			"woman": {"cell": [4, 5], "facing": "right", "sprite": "mom",
				"dialogue": "goldenrod_house_1_woman"},
			# JOH5 (T-36) : Raphaël, de retour après la Tour Radio.
			"raphael": {"cell": [6, 5], "facing": "left", "sprite": "engineer",
				"dialogue": "goldenrod_radio_raphael_home", "if": ["johto_act2"]},
		},
		"goldenrod_house_2": {
			"man": {"cell": [12, 6], "facing": "left", "sprite": "old_man",
				"dialogue": "goldenrod_house_2_man"},
		},
	}
	for map_id, entries in npcs.items():
		write_json(os.path.join(DATA, "npcs", map_id + ".json"), entries)
	write_json(os.path.join(DATA, "dialogues", "joh3_goldenrod_interiors.json"), dialogues)
	write_json(os.path.join(DATA, "cutscenes", "joh3_goldenrod_interiors.json"), cutscenes)


BOND_INTRO = ["Bonjour, mon petit.\nJe suis Clémence.", "Je sais lire dans le cœur\ndes Pokémon.",
	"Montre-moi celui qui marche\ndevant toi."]
BOND_TIERS = ["Hum… Il ne te connaît pas encore\ntrès bien. Laisse-lui du temps.",
	"Il commence à t'apprécier.\nContinuez ensemble.",
	"Il t'aime beaucoup.\nÇa se voit dans ses yeux.",
	"Je n'ai jamais vu un lien pareil.\nIl te suivrait n'importe où."]
BOND_AFTER = ["Un Pokémon qui t'aime\npeut changer, parfois.", "Prends soin de lui."]


def write_week():
	"""PNJ de la semaine (cadre §5.2, dossier §10) : Mercédès (mercredi, Route 36), Jérôme
	(jeudi, Doublonville). Don une seule fois (modèle du JOH2)."""
	dialogues = {}
	cutscenes = {}
	for did, (speaker, flag, _day, item, count, before, system, after) in WEEK.items():
		received_id = flag.replace("_gift", "_received")
		dialogues[did] = {"speaker": speaker, "variants": [
			{"unless": [flag], "cutscene": flag, "pages": before},
			{"if": [flag], "pages": [after]},
		]}
		dialogues[received_id] = dialogue(NARRATION, [system])
		cutscenes[flag] = week_scene(flag, item, count, received_id)
	write_json(os.path.join(DATA, "dialogues", "joh3_week.json"), dialogues)
	write_json(os.path.join(DATA, "cutscenes", "joh3_week.json"), cutscenes)


if __name__ == "__main__":
	main()
