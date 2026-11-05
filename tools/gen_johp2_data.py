#!/usr/bin/env python3
"""Données de jeu du jalon JOHP2 (arc des Pierres : Goéland, Irisia, Grotte de la Marée), générées
depuis les grilles.

Lit les positions de `tools/plans/goeland_deck.txt`, `cianwood_city.txt`, `tide_cave_1f.txt`,
`tide_cave_b1f.txt` et des variantes ARC d'`oliville.txt` et `rosalia.txt` (grilles validées le
2026-11-05, elles font foi) et écrit, d'après `docs/design/dossier-joh-11-arc-pierres.md` (textes §17
P-11 à P-19b, P-40, P-41, P-46 à P-48, P-55, P-59 validés le 2026-11-05 ; Dresseurs §10, rencontres
§11, objets §12) et le plan `docs/tech/jalon-joh-pierres.md` §4 :
  - `data/npcs/<carte>.json` (Dresseurs, PNJ, objets visibles, habitants des intérieurs) ;
  - `data/trainers/<carte>.json` ;
  - `data/encounters/cianwood_city.json`, `tide_cave.json` ;
  - `data/dialogues/johp2_*.json`, `data/cutscenes/johp2_*.json` ;
  - et **complète** `data/npcs/olivine_city.json` (Goulven) et `ecruteak_city.json` (Corentin et son
    Dracolosse), sans toucher à leurs autres entrées.

Sens de la traversée (une seule carte pour le pont) : drapeau de travail `johto_goeland_outbound`,
levé en montant à Oliville, baissé en montant à Irisia [D]. Tout passe par le pont : on en descend
en parlant à Goulven (`tools/plans/goeland_deck.txt`).

Les textes absents du dossier sont marqués « draft » et listés dans
`tests/integration/test_no_draft_in_data.gd` (PENDING_DRAFTS).

Usage : python3 -I tools/gen_johp2_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")
PREFIX = "johp2_"

# Grille → identifiant de carte.
MAPS = [("goeland_deck", "goeland_deck"), ("cianwood_city", "cianwood_city"),
	("tide_cave_1f", "tide_cave_1f"), ("tide_cave_b1f", "tide_cave_b1f")]

# Largeur d'une ligne de bulle (3 lignes au plus, `UiTokens.DIALOG_MAX_LINES`) [D].
WRAP = 36
NARRATION = None
OUTBOUND = "johto_goeland_outbound"
TIDE_LOST = "johto_stone_tide_lost"
QUEST = "johto_stones_quest"
ROSALIA_TOLD = "johto_goulven_rosalia_told"

# --- Dresseurs (dossier §10) ------------------------------------------------------------------
# id : (nom, classe de combat [D], sprite [D], prize_per_level [D], équipe, (avant, défaite, après))
TRAINERS = {
	"goeland_deck": {
		"goeland_sailor_yvon": ("Marin Yvon", None, "sailor", 30,
			[("machoke", 33), ("tentacruel", 33)],
			("À bord, on se bat pour passer le temps !", "Le temps a passé vite.",
				"Goulven n'a jamais raté une traversée.")),
	},
	"cianwood_city": {
		"cianwood_fisher_ronan": ("Pêcheur Ronan", None, "fisher_route_12", 30,
			[("seadra", 34), ("tentacruel", 34)],
			("Sur cette île, le poisson décide.", "Il a décidé.",
				"La grotte ne se remplit plus. Les poissons ont fui.")),
		"cianwood_blackbelt_tanguy": ("Karatéka Tanguy", None, "blackbelt", 30,
			[("machoke", 34), ("hitmonlee", 34)],
			("Je m'entraîne contre les vagues. Tu seras plus facile.",
				"Les vagues frappent moins fort.",
				"Ces hommes en noir n'ont pas salué l'île. Ça ne se fait pas.")),
		"cianwood_cooltrainer_maelle": ("Topdresseuse Maëlle", None, "cooltrainer_f", 40,
			[("starmie", 35), ("goldeen", 34)],
			("On vient à Irisia pour une seule raison : la mer. Et toi ?", "Tu as une bonne raison.",
				"Le bateau noir est là depuis hier.")),
	},
	"tide_cave_1f": {
		"tide_grunt_y": ("Sbire Rocket", "sbire_rocket", "rocket_grunt_m", 35,
			[("golbat", 34), ("weezing", 34)],
			("Les pompes tournent, personne n'entre !", "Ça tourne sans moi.",
				"Une grotte qu'on vide, c'est long.")),
		"tide_grunt_z": ("Sbire Rocket", "sbire_rocket_f", "rocket_grunt_f", 35,
			[("raticate", 35), ("arbok", 35)],
			("Encore toi ? On t'a vu aux ruines !", "Et on te reverra, c'est ça le problème.",
				"Cenere a dit qu'on aurait fini à l'heure. Elle a toujours raison.")),
	},
	"tide_cave_b1f": {
		"tide_grunt_aa": ("Sbire Rocket", "sbire_rocket", "rocket_grunt_m", 35,
			[("houndoom", 36), ("murkrow", 36)],
			("Cenere est déjà descendue. Tu perds ton temps !", "C'est moi qui perds.",
				"Vas-y, cours. Elle a calculé ça aussi.")),
		"tide_scientist": ("Scientifique Rocket", None, "researcher", 35,
			[("electrode", 36), ("magneton", 36), ("porygon", 35)],
			("Niveau de l'eau, débit, durée : tout est prévu. Sauf toi.", "Sauf toi.",
				"Tourne les vannes si tu veux. Il est trop tard.")),
	},
}
# Chef de cale (P-16) : combat obligatoire, repéré sur le seul passage (grille).
CHIEF_ID = "tide_hold_chief"
CHIEF = {
	"name": "Chef de cale", "class": "sbire_rocket", "ai": "smart", "can_lose": False,
	"heal_after": False, "gives_exp": True, "prize_money": 0, "prize_per_level": 60,
	"team": [{"species": "muk", "level": 37}, {"species": "noctowl", "level": 37},
		{"species": "houndoom", "level": 38}],
}
CHIEF_BEFORE = ["Tu arrives trop tard, le gamin.", "Mais je vais quand même te faire regretter le voyage."]
CHIEF_DEFEATED = ["Vas-y, regarde. Tu verras bien."]

# --- Textes (dossier §17) ---------------------------------------------------------------------
P11 = ["Le Goéland reste à quai.", "Je ne fais pas la traversée pour un inconnu."]
P12 = ["Héloïse t'envoie ? Elle me doit encore deux filets.", "Irisia, c'est ça ? Tiens, pour la route.",
	"Monte. La mer est bonne, aujourd'hui."]
P13 = ["Tu vois ce bateau, là-bas ? Noir, sans pavillon.", "Il fait route vers mon île depuis l'aube.",
	"Je n'aime pas ça."]
P14 = ["Depuis hier, la grotte fait un bruit de machine.", "Et la mer n'y remonte plus."]
P15 = ["Une pompe énorme aspire l'eau de la grotte.",
	"Une étiquette dit : « Team Rocket, propriété de Dante »."]
P17 = ["L'eau a baissé. Au fond du bassin, un socle de pierre.", "Il est vide."]
P18 = ["Quatorze minutes de retard.", "Tu t'améliores.",
	"La Pierre Marée est à moi. Tes Pokémon aussi.",
	"Il m'en reste une à prendre, et celle que tu as dans ta poche."]
P19 = ["Je ne me fatigue pas à te combattre. Tu viendras à moi."]
P19_SYSTEM = ["Cenere remonte sur le bateau noir. Le bateau s'éloigne…"]
P19B = ["Tu as la tête de quelqu'un qui a perdu.",
	"Tiens, un drôle de gars t'a cherché ce matin. Il est descendu du ciel sur un Dracolosse.",
	"Il a dit qu'il t'attendrait à Rosalia."]
P41_CITY = ["IRISIA", "L'île au bout de la mer"]
P41_CAVE = ["GROTTE DE LA MARÉE", "Entrée interdite à marée haute"]
P48_VALVE = ["{player} tourne la vanne.", "On entend l'eau bouger, plus bas."]
P48_BOAT = ["Un bateau noir, sans pavillon, à l'ancre devant l'île."]
P55 = ["Irisia ? Toujours.", "La mer ne change pas d'avis, et moi non plus."]
P59 = ["La mer est mauvaise au sud, en ce moment.", "Le bateau noir rôde. Fais demi-tour."]
# Ligne de système du don (T-31 : même tournure) [D].
ULTRA_RECEIVED = ["{player} reçoit 3 Hyper Balls !"]
# Choix de monter à bord (§6 étape 9 : le joueur peut refuser) [D].
BOARD_CHOICE = {"confirm": "MONTER", "cancel": "RESTER"}

# Habitants des intérieurs : aucun texte au dossier [D].
INTERIOR_TEXTS = {
	"cianwood_goulven_house_habitante": ("Habitante", [
		"Mon oncle dit que la maison tangue moins que le Goéland.",
		"Il n'y dort presque jamais."], True),
	"cianwood_house_1_habitant": ("Vieux pêcheur", [
		"La mer entrait dans cette grotte deux fois par jour, depuis toujours.",
		"Elle n'avait jamais manqué un rendez-vous."], True),
}

# --- Sprites [D] -----------------------------------------------------------------------------
ROLE_SPRITES = {"marin": "sailor", "habitante": "beauty", "cenere": "rocket_grunt_f",
	"messager": "courier"}

# --- Rencontres (dossier §11) : (identifiant, carte(s), terrain, moments, taux, créneaux) --------
ENCOUNTERS = {
	"cianwood_city": [
		("cianwood_grass_day", ["cianwood_city"], "grass", ["morning", "day"], 25,
			[("pidgeotto", 30, 34, 30), ("raticate", 30, 34, 25), ("slowpoke", 30, 34, 25),
				("machop", 30, 34, 20)]),
		("cianwood_grass_night", ["cianwood_city"], "grass", ["night"], 25,
			[("noctowl", 30, 34, 35), ("raticate", 30, 34, 30), ("slowpoke", 30, 34, 35)]),
	],
	# Grotte : toute la journée. Le B1F n'a de gravats que ses gués (a, b) : la grille y laisse le
	# sol calme, le dossier §11 y met une table [D].
	"tide_cave": [
		("tide_cave_1f_rubble", ["tide_cave_1f"], "rubble", None, 25,
			[("krabby", 31, 34, 30), ("shellder", 31, 34, 25), ("staryu", 31, 34, 20),
				("tentacool", 31, 34, 25)]),
		("tide_cave_b1f_rubble", ["tide_cave_b1f"], "rubble", None, 25,
			[("kingler", 32, 35, 25), ("tentacruel", 32, 35, 25), ("dewgong", 32, 35, 25),
				("staryu", 32, 35, 25)]),
	],
}

CELL_RE = re.compile(r"^(\d+)(?:\.\.(\d+))?,(\d+)(?:\.\.(\d+))?$")


def read_plan(name):
	"""Positions de la grille, variantes comprises : id → (type, cases, attributs)."""
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
			body = line.partition("#")[0]
			words = body.split()
			attrs = {}
			for word in words[3:]:
				if "=" in word:
					key, _, value = word.partition("=")
					attrs[key] = value
			positions[words[0]] = (words[1], parse_cells(words[2]), attrs)
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


def wrap(text):
	"""Retours à la ligne d'une bulle (au plus [WRAP] caractères par ligne, mots entiers)."""
	if len(text) <= WRAP:
		return text
	lines = []
	current = ""
	for word in text.split(" "):
		candidate = word if not current else current + " " + word
		if len(candidate) > WRAP and current:
			lines.append(current)
			current = word
		else:
			current = candidate
	lines.append(current)
	if len(lines) > 3:
		raise ValueError("bulle trop longue (%d lignes) : %s" % (len(lines), text))
	return "\n".join(lines)


def pages(texts):
	return [wrap(text) for text in texts]


def write_json(path, data):
	text = json.dumps(data, ensure_ascii=False, indent="\t") + "\n"
	with open(path, "w", encoding="utf-8") as handle:
		handle.write(text)
	print("écrit :", os.path.relpath(path, ROOT))


def dialogue(speaker, texts, draft=False):
	entry = {}
	if speaker:
		entry["speaker"] = speaker
	else:
		entry["narration"] = True
	if draft:
		entry["draft"] = True
	entry["pages"] = pages(texts)
	return entry


def flag_lists(attrs):
	"""Conditions de présence « actif_avec » / « actif_sans » de la grille."""
	out = {}
	if "actif_avec" in attrs:
		out["if"] = attrs["actif_avec"].split(",")
	if "actif_sans" in attrs:
		out["unless"] = attrs["actif_sans"].split(",")
	return out


def item_scene(ident, item, count, flag):
	return {"variants": [{"unless": [flag], "steps": [
		{"despawn": ident},
		{"give": item, "count": count, "found": True},
		{"set": [flag]},
	]}]}


def trainer_entry(name, klass, prize, team):
	entry = {"name": name}
	if klass:
		entry["class"] = klass
	entry.update({
		"ai": "random", "can_lose": False, "heal_after": False,
		"gives_exp": True, "prize_money": 0, "prize_per_level": prize,
		"team": [{"species": species, "level": level} for species, level in team],
	})
	return entry


# --- Scènes -----------------------------------------------------------------------------------

def board_outbound_steps():
	"""À quai à Oliville : monter à bord."""
	return [
		{"set": [OUTBOUND]},
		{"change_map": "goeland_deck", "at": "from_quai", "facing": "right"},
	]


def depart_scene():
	"""P-12 : Goulven accepte (Pierre Mémoire en poche), donne 3 Ultra Balls ; le joueur peut rester
	à quai, le passage reste ouvert (§6 étape 9)."""
	return {"variants": [{"if": ["johto_stone_memory"], "unless": ["johto_ferry_open"], "steps": [
		{"dialogue": "olivine_goulven_send"},
		{"give": "ultra_ball", "count": 3},
		{"dialogue": "olivine_goulven_ultra"},
		{"set": ["johto_ferry_open"]},
		{"dialogue": "olivine_goulven_board"},
		{"change_map": "goeland_deck", "at": "from_quai", "facing": "right", "if": [OUTBOUND]},
	]}]}


def to_cianwood_scene():
	"""Fondu vers Irisia ; le passage déclenche le titre de zone à l'arrivée."""
	return {"steps": [
		{"change_map": "cianwood_city", "at": "from_goeland", "facing": "left"},
	]}


def to_olivine_scene():
	"""Fondu vers Oliville ; P-19b au premier retour après le revers."""
	said = {"if": [TIDE_LOST], "unless": [ROSALIA_TOLD]}
	return {"steps": [
		{"change_map": "olivine_city", "at": "from_goeland", "facing": "left"},
		dict({"face": "goulven", "to": "player"}, **said),
		dict({"dialogue": "olivine_goulven_rosalia"}, **said),
		{"set": [ROSALIA_TOLD], "if": [TIDE_LOST]},
	]}


def socle_scene():
	"""P-17 à P-19 (JH-62) : le socle est vide, Cenere repart par la mer avec la Pierre Marée, qui
	n'entre jamais dans le Sac. Le drapeau en dernier : scène interrompue = rejouée."""
	return {"variants": [{"unless": [TIDE_LOST], "steps": [
		{"dialogue": "tide_cave_b1f_socle"},
		{"emote": "cenere", "kind": "exclamation"},
		{"face": "player", "to": "cenere"},
		{"face": "cenere", "to": "player"},
		{"dialogue": "tide_cave_cenere_late"},
		{"dialogue": "tide_cave_cenere_leaves"},
		{"despawn": "cenere"},
		{"dialogue": "tide_cave_cenere_gone"},
		{"animate": "Decor/BateauNoir", "offset": [-6, 0], "duration": 2.0, "fade": True},
		{"set": [TIDE_LOST]},
	]}]}


def sea_block_scene():
	"""A-13, P-59 : la mer au sud d'Oliville est fermée tant que `johto_act2` manque. Le pas en
	arrière remonte au nord quel que soit le sens d'arrivée sur la rangée."""
	return {"variants": [{"unless": ["johto_act2"], "steps": [
		{"dialogue": "olivine_south_sea_block"},
		{"move": "player", "path": ["up"], "keep_facing": True},
	]}]}


def main():
	for plan, map_id in MAPS:
		build_map(plan, map_id)
	write_olivine()
	write_rosalia()
	write_interiors()
	write_encounters()


def build_map(plan, map_id):
	positions = read_plan(plan)
	npcs = {}
	dialogues = {}
	cutscenes = {}
	trainers = {}
	for trainer_id, (name, klass, _sprite, prize, team, lines) in TRAINERS.get(map_id, {}).items():
		before, defeated, after = lines
		dialogues[trainer_id + "_before"] = dialogue(name, [before])
		dialogues[trainer_id + "_defeated"] = dialogue(name, [defeated])
		dialogues[trainer_id + "_after"] = dialogue(name, [after])
		trainers[trainer_id] = trainer_entry(name, klass, prize, team)
	for ident, (kind, cells, attrs) in positions.items():
		cell = list(cells[0])
		if kind == "dresseur":
			trainer_id = attrs["trainer"]
			if trainer_id == CHIEF_ID:
				sprite = "rocket_grunt_m"
				trainers[trainer_id] = CHIEF
				name = CHIEF["name"]
				dialogues[trainer_id + "_before"] = dialogue(name, CHIEF_BEFORE)
				dialogues[trainer_id + "_defeated"] = dialogue(name, CHIEF_DEFEATED)
				dialogues[trainer_id + "_after"] = dialogue(name, CHIEF_DEFEATED)
			else:
				sprite = TRAINERS[map_id][trainer_id][2]
			npcs[ident] = {
				"cell": cell, "facing": attrs["facing"], "sprite": sprite,
				"dialogue": trainer_id + "_after",
				"trainer": {"id": trainer_id, "sight": int(attrs["sight"]),
					"before": trainer_id + "_before", "defeated": trainer_id + "_defeated"},
			}
		elif kind == "pnj":
			entry = {"cell": cell, "facing": attrs.get("facing", "down"),
				"sprite": ROLE_SPRITES[attrs["role"]]}
			entry.update(flag_lists(attrs))
			if ident == "goulven" and map_id == "goeland_deck":
				entry["dialogue"] = "goeland_goulven"
				dialogues["goeland_goulven"] = {"speaker": "Goulven", "variants": [
					{"if": [OUTBOUND], "unless": ["johto_cianwood_arrived"], "pages": pages(P13),
						"cutscene": "goeland_to_cianwood"},
					{"if": [OUTBOUND], "cutscene": "goeland_to_cianwood"},
					{"cutscene": "goeland_to_olivine"},
				]}
				cutscenes["goeland_to_cianwood"] = to_cianwood_scene()
				cutscenes["goeland_to_olivine"] = to_olivine_scene()
			elif ident == "goulven":
				entry["dialogue"] = "cianwood_goulven"
				dialogues["cianwood_goulven"] = {"speaker": "Goulven", "pages": pages(P55),
					"choice": dict(BOARD_CHOICE, confirm_cutscene="goeland_board_return")}
				cutscenes["goeland_board_return"] = {"steps": [
					{"unset": [OUTBOUND]},
					{"change_map": "goeland_deck", "at": "from_quai", "facing": "right"},
				]}
			elif ident == "habitante":
				entry["dialogue"] = "cianwood_city_habitante"
				dialogues["cianwood_city_habitante"] = dialogue("Habitante", P14)
			elif ident == "cenere":
				entry["dialogue"] = "tide_cave_cenere_leaves"
			npcs[ident] = entry
		elif kind == "panneau":
			texts = P41_CAVE if ident == "panneau_grotte" else P41_CITY
			dialogues["%s_%s" % (map_id, ident)] = dialogue(NARRATION, texts)
		elif kind == "examen":
			did = "%s_%s" % (map_id, ident)
			if ident.startswith("pompe"):
				dialogues[did] = dialogue(NARRATION, P15)
			elif ident == "bateau_noir":
				dialogues[did] = dialogue(NARRATION, P48_BOAT)
			elif ident == "socle":
				dialogues[did] = dialogue(NARRATION, P17)
			elif ident.startswith("vanne"):
				dialogues[did] = {"narration": True, "variants": [
					{"set": [attrs["drapeau"]], "pages": pages(P48_VALVE)}]}
		elif kind == "objet_visible":
			flag = "got_" + ident
			npcs[ident] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
				"dialogue": ident, "verb": "take", "turn_to_player": False, "unless": [flag]}
			dialogues[ident] = {"cutscene": ident}
			cutscenes[ident] = item_scene(ident, attrs["item"], int(attrs.get("count", 1)), flag)
		elif kind == "declencheur":
			if ident == "arrivee_titre":
				cutscenes["cianwood_arrival"] = {"variants": [{"unless": [attrs["drapeau"]],
					"steps": [{"set": [attrs["drapeau"]]}]}]}
			elif ident == "scene_socle":
				cutscenes["tide_cave_socle"] = socle_scene()
				dialogues["tide_cave_cenere_late"] = dialogue("Cenere", P18)
				dialogues["tide_cave_cenere_leaves"] = dialogue("Cenere", P19)
				dialogues["tide_cave_cenere_gone"] = dialogue(NARRATION, P19_SYSTEM)
	write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)
	write_json(os.path.join(DATA, "dialogues", PREFIX + map_id + ".json"), dialogues)
	if cutscenes:
		write_json(os.path.join(DATA, "cutscenes", PREFIX + map_id + ".json"), cutscenes)
	if trainers:
		write_json(os.path.join(DATA, "trainers", map_id + ".json"), trainers)


def complete_npcs(map_id, entries):
	"""Ajoute ou remplace [entries] dans `data/npcs/<map_id>.json`, sans toucher au reste."""
	path = os.path.join(DATA, "npcs", map_id + ".json")
	with open(path, encoding="utf-8") as handle:
		npcs = json.load(handle)
	npcs.update(entries)
	write_json(path, npcs)


def write_olivine():
	"""Goulven au ponton est (derrière `johto_stones_quest`, que rien ne pose avant la bascule du
	JOHP3), ses textes, la barrière de la mer (A-13)."""
	positions = read_plan("oliville")
	_kind, cells, attrs = positions["goulven"]
	complete_npcs("olivine_city", {"goulven": {"cell": list(cells[0]), "facing": attrs["facing"],
		"sprite": ROLE_SPRITES["marin"], "dialogue": "olivine_goulven", "if": [QUEST]}})
	send = {"speaker": "Goulven", "pages": pages(P12[:2])}
	board = {"speaker": "Goulven", "pages": pages(P12[2:]),
		"choice": dict(BOARD_CHOICE, confirm_set=[OUTBOUND])}
	dialogues = {
		"olivine_goulven": {"speaker": "Goulven", "variants": [
			{"unless": ["johto_stone_memory"], "pages": pages(P11)},
			{"unless": ["johto_ferry_open"], "cutscene": "olivine_goulven_depart"},
			{"pages": pages(P55), "choice": dict(BOARD_CHOICE,
				confirm_cutscene="goeland_board_outbound")},
		]},
		"olivine_goulven_send": send,
		"olivine_goulven_ultra": dialogue(NARRATION, ULTRA_RECEIVED),
		"olivine_goulven_board": board,
		"olivine_goulven_rosalia": dialogue("Goulven", P19B),
		"olivine_south_sea_block": dialogue("Marin", P59),
	}
	cutscenes = {
		"olivine_goulven_depart": depart_scene(),
		"goeland_board_outbound": {"steps": board_outbound_steps()},
		"olivine_south_sea_block": sea_block_scene(),
	}
	write_json(os.path.join(DATA, "dialogues", PREFIX + "olivine.json"), dialogues)
	write_json(os.path.join(DATA, "cutscenes", PREFIX + "olivine.json"), cutscenes)


def write_rosalia():
	"""Corentin et son Dracolosse (variante ARC), présents après le revers. P-20 et son vol sont au
	JOHP3 (`tools/gen_johp3_data.py`, scène `johto_corentin_flight`)."""
	positions = read_plan("rosalia")
	_kind, cells, attrs = positions["corentin"]
	_kind, mount_cells, mount_attrs = positions["dracolosse"]
	complete_npcs("ecruteak_city", {
		"corentin": {"cell": list(cells[0]), "facing": attrs["facing"],
			"sprite": ROLE_SPRITES["messager"], "dialogue": "ecruteak_corentin", "if": [TIDE_LOST]},
		"dracolosse": {"cell": list(mount_cells[-1]), "facing": "left",
			"sprite": "pokemon/" + mount_attrs["espece"], "turn_to_player": False,
			"if": mount_attrs["actif_avec"].split(",")},
	})
	write_json(os.path.join(DATA, "dialogues", PREFIX + "ecruteak.json"),
		{"ecruteak_corentin": {"cutscene": "johto_corentin_flight"}})


def write_interiors():
	"""Centre (infirmière, marchand : `data/shops/cianwood_center.json`), maison de Goulven, maison.
	Cases des grilles de Lavanville réutilisées, comme les maisons de Johto."""
	write_json(os.path.join(DATA, "npcs", "cianwood_center.json"), {
		"nurse": {"cell": [7, 3], "facing": "down", "sprite": "nurse"},
		"clerk": {"cell": [13, 5], "facing": "left", "sprite": "clerk", "dialogue": "clerk"},
	})
	write_json(os.path.join(DATA, "npcs", "cianwood_goulven_house.json"), {
		"habitante": {"cell": [12, 6], "facing": "left", "sprite": "beauty",
			"dialogue": "cianwood_goulven_house_habitante"},
	})
	write_json(os.path.join(DATA, "npcs", "cianwood_house_1.json"), {
		"habitant": {"cell": [5, 6], "facing": "right", "sprite": "old_man",
			"dialogue": "cianwood_house_1_habitant"},
	})
	dialogues = {did: dialogue(*spec) for did, spec in INTERIOR_TEXTS.items()}
	write_json(os.path.join(DATA, "dialogues", PREFIX + "cianwood_interiors.json"), dialogues)
	write_json(os.path.join(DATA, "shops", "cianwood_center.json"), {"cianwood_center": {"stock": [
		{"item": "poke_ball"}, {"item": "great_ball"}, {"item": "potion"}, {"item": "super_potion"},
		{"item": "antidote"}, {"item": "repel"}]}})


def write_encounters():
	for group, tables in ENCOUNTERS.items():
		out = {}
		for table_id, maps, terrain, periods, rate, slots in tables:
			table = {"maps": maps, "terrain": terrain}
			if periods:
				table["period"] = periods
			table["rate"] = rate
			table["ramp"] = {"from_step": 15, "max_steps": 20}
			table["slots"] = [{"species": s, "levels": [lo, hi], "weight": w}
				for s, lo, hi, w in slots]
			out[table_id] = table
		write_json(os.path.join(DATA, "encounters", group + ".json"), out)


if __name__ == "__main__":
	main()
