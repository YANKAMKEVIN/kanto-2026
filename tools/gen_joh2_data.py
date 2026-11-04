#!/usr/bin/env python3
"""Données de jeu du jalon JOH2 (Routes 39 et 38, Rosalia), générées depuis les grilles.

Lit les positions de `tools/plans/route_39.txt`, `route_38.txt`, `rosalia.txt` (grilles validées
le 2026-11-02, elles font foi) et écrit, d'après `docs/design/dossier-joh-03-rosalia.md` (textes
§13 validés le 2026-11-02, Dresseurs §6, objets §7, PNJ de la semaine §8, rencontres §5) et le plan
`docs/tech/jalon-joh2.md` §2.3 à §2.6 :
  - `data/npcs/<carte>.json` (Dresseurs, PNJ, objets visibles, habitants des intérieurs) ;
  - `data/trainers/route_39.json`, `route_38.json` ;
  - `data/encounters/route_39.json`, `route_38.json`, `ecruteak_city.json` (tables par moment) ;
  - `data/dialogues/joh2_<carte>.json`, `joh2_ecruteak_interiors.json`, `joh2_week.json` ;
  - `data/cutscenes/joh2_<carte>.json`, `joh2_ecruteak_interiors.json`, `joh2_week.json`.
Les textes absents du dossier sont marqués « draft » (relecture de Kevin, JOH2-Q1) et listés dans
`tests/integration/test_no_draft_in_data.gd` (PENDING_DRAFTS).

Usage : python3 -I tools/gen_joh2_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")

# Grille → identifiant de carte.
MAPS = [("route_39", "route_39"), ("route_38", "route_38"), ("rosalia", "ecruteak_city")]

# Positions des grilles qui appartiennent à d'autres jalons (aucune donnée ici).
SKIPPED = {
	("ecruteak_city", "diane"),            # JOH6 : sonneuse du dimanche
	("ecruteak_city", "sage_blesse"),      # JOH8
	("ecruteak_city", "panneau_tour_cendree"),  # JOH6 : panneau C-3
}

# Sprites provisoires [D] par Dresseur et par rôle de PNJ.
TRAINER_SPRITES = {
	"route_39_youngster_hugo": "youngster", "route_39_schoolgirl_lina": "lass_young",
	"route_38_birdkeeper_paul": "bird_keeper", "route_38_trainer_ines": "cooltrainer_f",
	"route_38_picnicker_theo": "camper",
}
ROLE_SPRITES = {
	"fermiere": "beauty", "promeneur": "traveler", "garde": "guard", "sage": "channeler",
	"sbire": "rocket_grunt_m", "conteuse": "aoki",
}
WEEKDAYS = {"lundi": "monday", "mardi": "tuesday", "mercredi": "wednesday", "jeudi": "thursday",
	"vendredi": "friday", "samedi": "saturday", "dimanche": "sunday"}

# Dresseurs (dossier §6 ; prize_per_level [D] : 20 Gamin / Écolière, 25 Ornithologue /
# Pique-niqueur, 35 Dresseuse).
TRAINERS = {
	"route_39": {
		"route_39_youngster_hugo": ("Gamin Hugo", 20, [("rattata", 6), ("sentret", 7)]),
		"route_39_schoolgirl_lina": ("Écolière Lina", 20, [("mareep", 8)]),
	},
	"route_38": {
		"route_38_birdkeeper_paul": ("Ornithologue Paul", 25, [("pidgey", 9), ("hoothoot", 10)]),
		"route_38_trainer_ines": ("Dresseuse Inès", 35, [("meowth", 10), ("oddish", 10),
			("mareep", 11)]),
		"route_38_picnicker_theo": ("Pique-niqueur Théo", 25, [("sentret", 11), ("rattata", 11)]),
	},
}
# Classes de combat (`data/battle/trainer_intro.json`) des noms sans préfixe connu [D] : Écolière →
# Fillette, Dresseuse → Topdresseuse, Pique-niqueur → Campeur (même feuille, même genre).
TRAINER_CLASSES = {
	"route_39_schoolgirl_lina": "fillette", "route_38_trainer_ines": "topdresseuse",
	"route_38_picnicker_theo": "campeur",
}
# Répliques des Dresseurs (R-4, R-5, R-7, R-8, R-9) : avant · défaite · après.
TRAINER_LINES = {
	"route_39_youngster_hugo": ("Toi aussi tu viens d'avoir\nton premier Pokémon ?",
		"D'accord, tu as plus\nd'expérience que moi !", "J'ai l'impression que tu as\ndéjà fait ça…"),
	"route_39_schoolgirl_lina": ("Mon Wattouat a une laine\ntoute douce !",
		"Il est tout électrique\nmaintenant…", "On va réviser nos leçons."),
	"route_38_birdkeeper_paul": ("La nuit, les Hoothoot comptent\nle temps. Et toi ?",
		"Ton heure était venue…\nla mienne aussi.", "Reviens la nuit, tu en verras plein."),
	"route_38_trainer_ines": ("Personne ne passe sans\nun petit combat !", "Bon, tu peux passer.",
		"Rosalia est juste à l'est.\nSes tours valent le détour."),
	"route_38_picnicker_theo": ("Tu interromps mon pique-nique !", "Mon sandwich est tombé…",
		"Il en reste un peu, tu veux ?"),
}

NARRATION = None
# Textes des panneaux, PNJ et examens : (carte, position) → (orateur, pages[, brouillon]).
# « / » du dossier = page ; retour à la ligne dans une bulle = « \n ».
TEXTS = {
	("route_39", "panneau_route"): (NARRATION, ["ROUTE 39\nOliville — Rosalia"]),
	("route_39", "panneau_ferme"): (NARRATION, ["FERME MEUMEU\nLait frais tous les matins"]),
	("route_39", "fermiere"): ("Fermière", ["Les Tauros sont nerveux\ndepuis quelques nuits.",
		"Des gens passent sur la route\nsans lumière.", "Je n'aime pas ça."]),
	# Pokémon de la ferme [D] (JH-28 : décor ; aucune planche d'Écrémeuh) : à relire (JOH2-Q1).
	("route_39", "ecremeuh"): (NARRATION, ["Meuuh !\nÉcrémeuh broute, paisible."], True),
	("route_39", "tauros"): (NARRATION, ["Tauros gratte le sol du sabot.\nIl n'a pas l'air tranquille."], True),
	("route_39", "ponyta"): (NARRATION, ["Ponyta somnole au soleil.\nSa crinière crépite doucement."], True),
	("route_38", "panneau_route"): (NARRATION, ["ROUTE 38\nRosalia — Route 39"]),
	("route_38", "promeneur"): ("Promeneur", ["À Rosalia, il y a deux tours.",
		"L'une a brûlé il y a longtemps.", "L'autre, personne n'a le droit\nd'y monter."]),
	("ecruteak_city", "panneau_ville"): (NARRATION, ["ROSALIA\nVille historique, où le passé\nreste vivant"]),
	("ecruteak_city", "porte_tour_cendree"): (NARRATION, ["La porte est fermée.",
		"Une odeur de vieux bois brûlé\nflotte encore."]),
	("ecruteak_city", "garde_carillon"): ("Garde", ["La Tour Carillon est sacrée.",
		"Seuls ceux que les sages autorisent\npeuvent y entrer."]),
	# Garde de la Route 42 : « texte à écrire avec le JOH6 » (dossier §3) ; [D] en attendant.
	("ecruteak_city", "garde_route_42"): ("Garde", ["La Route 42 est fermée.",
		"Des éboulements, du côté d'Acajou.\nReviens plus tard."], True),
}

# Scène des Sbires (R-12 à R-15) et les deux PNJ de la semaine (R-21, R-22), textes validés.
ROCKET_LINES = {
	"ecruteak_rocket_1": ("Sbire", ["Alors, vieux ? Où sont-ils,\nces trois Pokémon ?",
		"On sait qu'ils dorment\nsous la tour."]),
	"ecruteak_sage_refuses": ("Sage", ["Vous n'obtiendrez rien de moi.",
		"La tour est fermée,\net le restera."]),
	"ecruteak_rocket_2": ("Sbire", ["Hé ! On nous regarde.",
		"On s'en va. Le chef n'aime pas\nqu'on se fasse remarquer."]),
}
SAGE_AFTER = ["Merci, jeune Dresseur.\nCes hommes reviennent chaque nuit.",
	"Va voir notre doyen,\ndans la maison au toit rouge."]
ELDER_LEGEND = ["Il y a cent cinquante ans,\nla Tour Cendrée a brûlé.",
	"Trois Pokémon ont péri\ndans les flammes.",
	"Alors un Pokémon arc-en-ciel\nest descendu du ciel…",
	"et les a fait renaître\nde leurs cendres.",
	"On dit qu'ils dorment encore\nsous la tour.",
	"Ces hommes en noir\nveulent les réveiller.",
	"Pour quoi faire ?\nJe n'ose y penser.",
	"Tant que je vivrai,\nla tour restera fermée."]
ELDER_AFTER = ["Le Pokémon arc-en-ciel\ns'appelle Ho-Oh.",
	"Il ne se montre qu'aux Dresseurs\nau cœur pur."]
WEEK = {
	# id : (orateur, drapeau, jour, objet, nombre, pages avant, ligne système, page après)
	"week_monday_lucien": ("Lucien", "week_monday_gift", "monday", "super_potion", 3,
		["Le lundi, je reviens toujours\nau port.", "Tiens, ça porte chance\npour la semaine !"],
		"{player} reçoit 3 Super Potions !", "À lundi prochain, peut-être !"),
	"week_tuesday_margot": ("Margot", "week_tuesday_gift", "tuesday", "revive", 2,
		["Le mardi, je raconte les vieilles\nhistoires de Rosalia.",
			"Tu as écouté jusqu'au bout ?\nTiens, pour la route."],
		"{player} reçoit 2 Rappels !", "Reviens un mardi,\nj'en connais d'autres."),
}

# Rencontres (dossier §5, plan §2.4) : (identifiant, carte, moments, taux, créneaux).
ENCOUNTERS = {
	"route_39": [
		("route_39_grass_day", ["morning", "day"], 25, [("sentret", 4, 7, 30), ("mareep", 4, 7, 30),
			("rattata", 4, 7, 18), ("pidgey", 4, 7, 18), ("miltank", 4, 7, 4)]),
		("route_39_grass_night", ["night"], 25, [("hoothoot", 4, 7, 40), ("rattata", 4, 7, 30),
			("oddish", 4, 7, 30)]),
	],
	"route_38": [
		("route_38_grass_day", ["morning", "day"], 25, [("sentret", 7, 11, 30), ("mareep", 7, 11, 25),
			("pidgey", 7, 11, 20), ("rattata", 7, 11, 12), ("meowth", 7, 11, 9), ("miltank", 7, 11, 4)]),
		("route_38_grass_night", ["night"], 25, [("hoothoot", 7, 11, 40), ("rattata", 7, 11, 30),
			("meowth", 7, 11, 20), ("oddish", 7, 11, 10)]),
	],
	# Herbe des tours : nuit seulement, rare (≈ 10 % du taux habituel) [D] ; aucune table de jour.
	"ecruteak_city": [
		("ecruteak_towers_night", ["night"], 3, [("murkrow", 10, 12, 50), ("hoothoot", 10, 12, 50)]),
	],
}

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


def flag_lists(attrs):
	"""Conditions de présence « actif_avec » / « actif_sans » de la grille."""
	out = {}
	if "actif_avec" in attrs:
		out["if"] = attrs["actif_avec"].split(",")
	if "actif_sans" in attrs:
		out["unless"] = attrs["actif_sans"].split(",")
	return out


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


def rockets_scene():
	"""R-12 à R-14 : les Sbires interrogent le sage, voient le joueur et filent vers l'est par
	l'avenue (à pied, effacés au bout de 12 cases), sans combat. Le drapeau est posé en tête
	(scène interrompue = jouée)."""
	return {"variants": [{"unless": ["johto_rosalia_rockets_seen"], "steps": [
		{"set": ["johto_rosalia_rockets_seen"]},
		{"face": "sage_tour", "to": "sbire_1"},
		{"dialogue": "ecruteak_rocket_1"},
		{"dialogue": "ecruteak_sage_refuses"},
		{"emote": "sbire_2", "kind": "exclamation"},
		{"face": "sbire_2", "to": "player"},
		{"face": "sbire_1", "to": "player"},
		{"dialogue": "ecruteak_rocket_2"},
		# Fuite à pied vers l'est par l'avenue (aucune animation de course pour les Sbires),
		# effacement au bout de 12 cases [D].
		{"move": "sbire_1", "to": [24, 15], "background": True},
		{"move": "sbire_2", "to": [24, 16]},
		{"despawn": "sbire_1"},
		{"despawn": "sbire_2"},
		{"face": "sage_tour", "to": "player"},
	]}]}


def week_scene(flag, item, count, received_id):
	return {"variants": [{"unless": [flag], "steps": [
		{"give": item, "count": count},
		{"dialogue": received_id},
		{"set": [flag]},
	]}]}


def main():
	all_trainers = {}
	for plan, map_id in MAPS:
		positions = read_plan(plan)
		npcs = {}
		dialogues = {}
		cutscenes = {}
		trainers = TRAINERS.get(map_id, {})
		for trainer_id, (name, prize, team) in trainers.items():
			before, defeated, after = TRAINER_LINES[trainer_id]
			dialogues[trainer_id + "_before"] = dialogue(name, [before])
			dialogues[trainer_id + "_defeated"] = dialogue(name, [defeated])
			dialogues[trainer_id + "_after"] = dialogue(name, [after])
			all_trainers[trainer_id] = {"name": name}
			if trainer_id in TRAINER_CLASSES:
				all_trainers[trainer_id]["class"] = TRAINER_CLASSES[trainer_id]
			all_trainers[trainer_id].update({
				"ai": "random", "can_lose": False, "heal_after": False,
				"gives_exp": True, "prize_money": 0, "prize_per_level": prize,
				"team": [{"species": species, "level": level} for species, level in team],
			})
		for ident, (kind, cells, attrs, comment) in positions.items():
			key = (map_id, ident)
			if key in SKIPPED:
				continue
			cell = list(cells[0])
			if kind == "dresseur":
				trainer_id = attrs["trainer"]
				npcs[ident] = {
					"cell": cell, "facing": attrs["facing"], "sprite": TRAINER_SPRITES[trainer_id],
					"dialogue": trainer_id + "_after",
					"trainer": {"id": trainer_id, "sight": int(attrs["sight"]),
						"before": trainer_id + "_before", "defeated": trainer_id + "_defeated"},
				}
			elif kind == "pnj":
				role = attrs.get("role", "")
				entry = {"cell": cell, "facing": attrs.get("facing", "down"),
					"sprite": ROLE_SPRITES[role]}
				if ident == "sbire_2":
					entry["sprite"] = "rocket_grunt_f"
				if "jour" in attrs:
					entry["if_weekday"] = [WEEKDAYS[attrs["jour"]]]
				entry.update(flag_lists(attrs))
				if role == "conteuse":
					entry["dialogue"] = "week_tuesday_margot"
				elif role == "sbire":
					pass  # ils parlent dans la scène seulement
				elif ident == "sage_tour":
					entry["dialogue"] = "ecruteak_city_sage_tour"
					dialogues["ecruteak_city_sage_tour"] = {"speaker": "Sage", "variants": [
						{"if": ["johto_rosalia_rockets_seen"], "pages": SAGE_AFTER},
						{"pages": ROCKET_LINES["ecruteak_sage_refuses"][1]},
					]}
				else:
					dialogue_id = "%s_%s" % (map_id, ident)
					entry["dialogue"] = dialogue_id
					dialogues[dialogue_id] = dialogue(*TEXTS[key])
				npcs[ident] = entry
			elif kind in ("panneau", "examen"):
				dialogues["%s_%s" % (map_id, ident)] = dialogue(*TEXTS[key])
			elif kind == "pokemon":
				# Un dialogue par espèce (les trois Écrémeuh partagent le leur).
				species = ident.rstrip("0123456789").rstrip("_")
				dialogues["%s_%s" % (map_id, species)] = dialogue(*TEXTS[(map_id, species)])
			elif kind == "objet_visible":
				flag = "got_" + ident
				npcs[ident] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
					"dialogue": ident, "verb": "take", "turn_to_player": False, "unless": [flag]}
				dialogues[ident] = {"cutscene": ident}
				cutscenes[ident] = item_scene(ident, attrs["item"], int(attrs.get("count", 1)),
					flag, True)
			elif kind == "cache":
				flag = "got_" + ident
				dialogues[ident] = {"cutscene": ident}
				cutscenes[ident] = item_scene(ident, attrs["item"], 1, flag, False)
			elif kind == "declencheur":
				if ident == "scene_sbires":
					cutscenes["ecruteak_rockets"] = rockets_scene()
					for rid, (speaker, pages) in ROCKET_LINES.items():
						dialogues[rid] = dialogue(speaker, pages)
				elif ident == "barriere_carillon":
					cutscenes["ecruteak_bell_tower_guard"] = guard_scene("garde_carillon",
						"johto_bell_tower_open", "ecruteak_city_garde_carillon", "down")
				elif ident == "barriere_route_42":
					cutscenes["ecruteak_route_42_guard"] = guard_scene("garde_route_42",
						"johto_act2", "ecruteak_city_garde_route_42", "left")
		write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)
		write_json(os.path.join(DATA, "dialogues", "joh2_%s.json" % map_id), dialogues)
		if cutscenes:
			write_json(os.path.join(DATA, "cutscenes", "joh2_%s.json" % map_id), cutscenes)
		if trainers:
			write_json(os.path.join(DATA, "trainers", map_id + ".json"),
				{tid: all_trainers[tid] for tid in trainers})
		tables = {}
		for table_id, periods, rate, slots in ENCOUNTERS[map_id]:
			tables[table_id] = {
				"maps": [map_id], "terrain": "grass", "period": periods, "rate": rate,
				"ramp": {"from_step": 15, "max_steps": 20},
				"slots": [{"species": s, "levels": [lo, hi], "weight": w} for s, lo, hi, w in slots],
			}
		write_json(os.path.join(DATA, "encounters", map_id + ".json"), tables)
	write_interiors()
	write_week()


def write_interiors():
	"""Maison des sages (doyen R-16 à R-18, deux sages [D]), Maison 1 (Antidote ×2 d'une
	habitante, textes [D]), Maison 2 (habitant [D]). Cases des grilles de Lavanville réutilisées
	(plan §2.1)."""
	dialogues = {
		"ecruteak_elders_house_doyen": {"speaker": "Doyen", "variants": [
			{"unless": ["johto_tower_legend_heard"], "set": ["johto_tower_legend_heard"],
				"pages": ELDER_LEGEND},
			{"if": ["johto_tower_legend_heard"], "pages": ELDER_AFTER},
		]},
		"ecruteak_elders_house_sage": dialogue("Sage",
			["Le doyen veille sur la Tour Cendrée\ndepuis plus de soixante ans."], True),
		"ecruteak_house_1_habitante": {"speaker": "Habitante", "variants": [
			{"unless": ["got_ecruteak_house_1_antidote"], "cutscene": "ecruteak_house_1_antidote",
				"draft": True, "pages": ["L'herbe des tours est pleine\nde Pokémon la nuit.",
					"Tiens, prends ça.\nOn ne sait jamais."]},
			{"if": ["got_ecruteak_house_1_antidote"], "draft": True,
				"pages": ["Fais attention la nuit,\nautour des tours."]},
		]},
		"ecruteak_house_1_received": dialogue(NARRATION, ["{player} reçoit 2 Antidotes !"], True),
		"ecruteak_house_2_habitant": dialogue("Habitant",
			["Les cloches de la Tour Carillon\nn'ont pas sonné depuis des années.",
				"Mon grand-père disait\nqu'elles sonnent pour Ho-Oh."], True),
	}
	cutscenes = {"ecruteak_house_1_antidote": {"variants": [
		{"unless": ["got_ecruteak_house_1_antidote"], "steps": [
			{"give": "antidote", "count": 2},
			{"dialogue": "ecruteak_house_1_received"},
			{"set": ["got_ecruteak_house_1_antidote"]},
		]}]}}
	write_json(os.path.join(DATA, "npcs", "ecruteak_elders_house.json"), {
		"doyen": {"cell": [7, 5], "facing": "down", "sprite": "mr_fuji",
			"dialogue": "ecruteak_elders_house_doyen"},
		"sage_1": {"cell": [1, 5], "facing": "right", "sprite": "channeler",
			"dialogue": "ecruteak_elders_house_sage"},
		"sage_2": {"cell": [12, 6], "facing": "left", "sprite": "channeler",
			"dialogue": "ecruteak_elders_house_sage"},
	})
	# Centre et Boutique : l'infirmière et le vendeur derrière leur comptoir, comme à Kanto
	# (définitions communes : `nurse` / `clerk` en (7, 3), dialogues partagés).
	write_json(os.path.join(DATA, "npcs", "ecruteak_center.json"), {
		"nurse": {"cell": [7, 3], "facing": "down", "sprite": "nurse"},
	})
	write_json(os.path.join(DATA, "npcs", "ecruteak_mart.json"), {
		"clerk": {"cell": [7, 3], "facing": "down", "sprite": "clerk"},
	})
	write_json(os.path.join(DATA, "npcs", "ecruteak_house_1.json"), {
		"habitante": {"cell": [4, 5], "facing": "right", "sprite": "aoki",
			"dialogue": "ecruteak_house_1_habitante"},
	})
	write_json(os.path.join(DATA, "npcs", "ecruteak_house_2.json"), {
		"habitant": {"cell": [12, 6], "facing": "left", "sprite": "old_man",
			"dialogue": "ecruteak_house_2_habitant"},
	})
	write_json(os.path.join(DATA, "dialogues", "joh2_ecruteak_interiors.json"), dialogues)
	write_json(os.path.join(DATA, "cutscenes", "joh2_ecruteak_interiors.json"), cutscenes)


def write_week():
	"""PNJ de la semaine (cadre §5.2, dossier §8) : Lucien (lundi, Oliville : PNJ posé par le
	JOH1 dans `data/npcs/olivine_city.json`), Margot (mardi, Rosalia). Don une seule fois."""
	dialogues = {}
	cutscenes = {}
	for did, (speaker, flag, _day, item, count, before, system, after) in WEEK.items():
		scene_id = flag
		received_id = flag.replace("_gift", "_received")
		dialogues[did] = {"speaker": speaker, "variants": [
			{"unless": [flag], "cutscene": scene_id, "pages": before},
			{"if": [flag], "pages": [after]},
		]}
		dialogues[received_id] = dialogue(NARRATION, [system])
		cutscenes[scene_id] = week_scene(flag, item, count, received_id)
	write_json(os.path.join(DATA, "dialogues", "joh2_week.json"), dialogues)
	write_json(os.path.join(DATA, "cutscenes", "joh2_week.json"), cutscenes)


if __name__ == "__main__":
	main()
