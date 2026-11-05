#!/usr/bin/env python3
"""Données de jeu du jalon JOH4 (Route 34, Bois aux Chênes, Écorcia, Puits Ramoloss), générées
depuis les grilles.

Lit les positions de `tools/plans/route_34.txt`, `ilex_forest.txt`, `azalea_town.txt`,
`slowpoke_well_b1f.txt`, `slowpoke_well_b2f.txt` (grilles validées le 2026-11-02, elles font foi)
et écrit, d'après `docs/design/dossier-joh-05-ecorcia.md` (textes §14 E-1 à E-36 validés le
2026-11-02, Dresseurs §6, objets §7, PNJ du vendredi §9, rencontres §5) et le plan
`docs/tech/jalon-joh4.md` §2.3 à §2.6 :
  - `data/npcs/<carte>.json` (Dresseurs, PNJ, objets visibles, Ramoloss, habitants des intérieurs) ;
  - `data/trainers/<carte>.json` ;
  - `data/encounters/<carte>.json` (tables par moment, grotte et eau) ;
  - `data/dialogues/joh4_<carte>.json`, `joh4_azalea_interiors.json`, `joh4_week.json` ;
  - `data/cutscenes/joh4_<carte>.json`, `joh4_azalea_interiors.json`, `joh4_week.json`.
Les textes absents du dossier sont marqués « draft » (relecture de Kevin, JOH4-Q1) et listés dans
`tests/integration/test_no_draft_in_data.gd` (PENDING_DRAFTS).

Usage : python3 -I tools/gen_joh4_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")
PREFIX = "joh4_"

# Grille → identifiant de carte.
MAPS = [("route_34", "route_34"), ("ilex_forest", "ilex_forest"), ("azalea_town", "azalea_town"),
	("slowpoke_well_b1f", "slowpoke_well_b1f"), ("slowpoke_well_b2f", "slowpoke_well_b2f")]

# Largeur d'une ligne de bulle (3 lignes au plus, `UiTokens.DIALOG_MAX_LINES`) [D].
WRAP = 36

NARRATION = None
WEEKDAYS = {"lundi": "monday", "mardi": "tuesday", "mercredi": "wednesday", "jeudi": "thursday",
	"vendredi": "friday", "samedi": "saturday", "dimanche": "sunday"}

# --- Dresseurs (dossier §6) -------------------------------------------------------------------
# id : (nom, classe de combat [D], sprite [D], prize_per_level [D], équipe, (avant, défaite, après))
TRAINERS = {
	"route_34": {
		"route_34_picnicker_sophie": ("Pique-niqueuse Sophie", "fillette", "lass", 20,
			[("marill", 18), ("nidoran_f", 18)],
			("Tu tombes bien, je m'ennuyais !", "Bon, je retourne à mon panier.",
				"Le Bois aux Chênes est sombre, ne te perds pas.")),
		"route_34_pokemaniac_bruno": ("Pokémaniac Bruno", None, "pokemaniac", 25,
			[("ditto", 19), ("slowpoke", 19)],
			("Mes Pokémon sont rares, tu vas voir !", "Rares… mais pas assez forts.",
				"Mon Métamorph imite tout, sauf la victoire.")),
		"route_34_juggler_felix": ("Jongleur Félix", None, "gambler", 25,
			[("abra", 18), ("kadabra", 20)],
			("Hop, hop ! Regarde bien mes balles !", "J'en ai fait tomber une.",
				"Au sud, c'est le Bois aux Chênes. Suis le sentier.")),
	},
	"ilex_forest": {
		"ilex_forest_scout_tom": ("Scout Tom", None, "scout", 20,
			[("paras", 19), ("caterpie", 18), ("metapod", 19)],
			("Je connais ce bois par cœur !", "Je me suis perdu dans le combat.",
				"La sortie est au sud.")),
		"ilex_forest_lass_celine": ("Dresseuse Céline", "topdresseuse", "cooltrainer_f", 35,
			[("hoothoot", 20), ("teddiursa", 20)],
			("La nuit tombe vite, sous les arbres.", "Tu as de bons yeux.",
				"Le matin, de drôles de Pokémon sortent des troncs.")),
	},
	"slowpoke_well_b1f": {
		"slowpoke_well_grunt_e": ("Sbire Rocket", "sbire_rocket", "rocket_grunt_m", 30,
			[("raticate", 20), ("ekans", 20)],
			("Tu ne passeras pas, gamin !", "Si, tu passes…",
				"Le chef est en bas. Il va te réduire en miettes.")),
		"slowpoke_well_grunt_f": ("Sbire Rocket", "sbire_rocket_f", "rocket_grunt_f", 30,
			[("koffing", 21), ("zubat", 20)],
			("On fait du commerce, rien de plus !", "Le commerce est fermé.",
				"Des queues de Ramoloss, ça pousse, tu sais. Enfin, je crois.")),
		"slowpoke_well_grunt_g": ("Sbire Rocket", "sbire_rocket", "rocket_grunt_m", 30,
			[("houndour", 21), ("murkrow", 21)],
			("Brace va te faire regretter d'être venu !", "Brace va me faire regretter d'être venu…",
				"Va-t'en tant qu'il est encore temps.")),
	},
}
# Brace (grand combat, dossier §6) : lancé par la scène du B2F, pas par sa vue.
BRACE_ID = "slowpoke_well_admin_brace"
PAPERS_DIALOGUE = "slowpoke_well_b2f_papiers"
BRACE = {
	"name": "Brace", "class": "sbire_rocket", "ai": "smart",
	"can_lose": False, "heal_after": False, "gives_exp": True, "prize_money": 2000,
	"start_message": False, "end_message": True, "bag": True,
	# Niveaux [D] réglés par simulation (dossier §6 : 24, 24, 26 donnait 0,5 à 14,5 % de victoire
	# du premier coup avec une équipe N22 ; ici 29 à 55 %, cible des grands combats 35–60 % ;
	# `tools/sim/slowpoke_well_scenario.json`, plan §2.3).
	"team": [{"species": "murkrow", "level": 21}, {"species": "koffing", "level": 21},
		{"species": "houndoom", "level": 23}],
}

# --- Textes des panneaux, PNJ et examens : (carte, position) → (orateur, pages[, brouillon]) ---
TEXTS = {
	("route_34", "panneau_route"): (NARRATION, ["ROUTE 34", "Doublonville — Bois aux Chênes"]),
	("route_34", "pecheur"): ("Pêcheur", ["Avant, les Ramoloss d'Écorcia venaient pêcher ici.",
		"Ça fait des semaines qu'on n'en voit plus un seul."]),
	("ilex_forest", "panneau_bois"): (NARRATION, ["BOIS AUX CHÊNES",
		"Forêt protégée. Respectez le gardien du bois."]),
	("ilex_forest", "vieille_femme"): ("Vieille femme", [
		"On dit que le gardien de la forêt voyage dans le temps.",
		"Il ne se montre qu'à ceux qui respectent le bois.",
		"Moi, je ne l'ai jamais vu. Mais je lui apporte des fleurs."]),
	("ilex_forest", "charbonnier"): ("Charbonnier", ["Mon Canarticho m'aide à couper le bois.",
		"Sans lui, pas de charbon pour Écorcia."]),
	# Canarticho du charbonnier, en décor (dossier §1) : aucun texte au dossier [D].
	("ilex_forest", "canarticho"): (NARRATION, ["Canarticho serre son poireau.",
		"Il veille sur les bûches de son maître."], True),
	("azalea_town", "panneau_ville"): (NARRATION, ["ÉCORCIA",
		"La ville où l'on vit au rythme des Ramoloss"]),
	("azalea_town", "panneau_puits"): (NARRATION, ["PUITS RAMOLOSS",
		"Lieu de repos des Ramoloss. Ne pas déranger."]),
}
SHRINE = ["Un petit autel de bois, couvert de mousse.", "Quelqu'un y a déposé des fleurs fraîches.",
	"On dirait qu'il attend quelque chose."]
TOWNSWOMAN_BEFORE = ["Tu vois des Ramoloss, toi ?", "Avant, ils dormaient partout dans les rues.",
	"Depuis que les hommes en noir sont là, plus un seul."]
TOWNSWOMAN_AFTER = ["Les Ramoloss sont revenus !",
	"Tu les entends bâiller ? C'est le plus beau bruit du monde."]
SLOWPOKE_TOWN = ["Ramoloss bâille.", "… Il a déjà oublié pourquoi."]
SLOWPOKE_WELLHEAD = ["Le Puits Ramoloss.", "Un Ramoloss somnole sur la margelle."]
# Ramoloss sans queue (B2F) : aucun texte au dossier [D].
SLOWPOKE_TAILLESS = ["Ramoloss n'a plus de queue.", "Il n'a pas l'air de s'en rendre compte."]

# Fargas et la Team Rocket (E-11 à E-25).
KURT = {
	"azalea_kurt_greeting": ("Fargas", ["Hein ? Qui es-tu ?", "… Le Maître de Kanto ? Ici ?",
		"Alors écoute bien, petit."]),
	"azalea_kurt_story": ("Fargas", ["Des hommes en noir se sont installés dans le Puits Ramoloss.",
		"Ils coupent la queue des Ramoloss, pour la vendre.",
		"Une queue de Ramoloss, ça vaut une fortune chez certains.",
		"Les pauvres bêtes ne sentent rien… mais c'est une honte !"]),
	"azalea_kurt_leaves": ("Fargas", ["Ça suffit. J'y vais, moi !", "Suis-moi si tu as du cran."]),
	"azalea_well_grunt_flees": ("Sbire", ["Hé, le vieux ! On ne passe pas !", "…",
		"Il a l'air furieux. Je préviens les autres !"]),
	"slowpoke_well_kurt_fall": ("Fargas", ["Aïe ! Mon dos…",
		"Je suis tombé dans le noir, comme un débutant.",
		"Vas-y sans moi, {player}. Sauve les Ramoloss !"]),
	"slowpoke_well_brace_before": ("Brace", ["Alors c'est toi, le gamin de Kanto.",
		"On m'avait dit de me méfier de toi.", "Moi, je ne me méfie de personne. Je fonce !"]),
	"slowpoke_well_brace_defeated": ("Brace",
		["Quoi ? Battu par un gamin avec des Pokémon de rien du tout ?"]),
	"slowpoke_well_brace_after": ("Brace", ["Tu crois avoir gagné ? On a déjà ce qu'on voulait.",
		"Le vrai travail commence ailleurs.", "Profite bien de ta petite victoire !"]),
	"slowpoke_well_brace_flees": (NARRATION, ["Brace s'enfuit…", "Il a laissé tomber des papiers !"]),
	"slowpoke_well_papers_taken": (NARRATION, ["{player} ramasse un Ordre de mission.",
		"{player} ramasse une Carte d'accès. Il y est écrit : « Tour Radio de Doublonville »."]),
	"slowpoke_well_kurt_thanks": ("Fargas", ["Tu les as chassés !",
		"Regarde, les Ramoloss rentrent à la maison.",
		"Leurs queues repousseront, ne t'en fais pas."]),
	"slowpoke_well_kurt_kings_rock": ("Fargas", [
		"Tiens, je l'ai trouvée au fond du puits il y a bien longtemps.", "Une Roche Royale.",
		"On dit qu'un Ramoloss qui la porte, quand on l'échange, devient un roi."]),
	"slowpoke_well_kings_rock_received": (NARRATION, ["{player} reçoit une Roche Royale !"]),
	"azalea_kurt_house_after": ("Fargas", ["Ces voleurs parlaient de Doublonville. De leur « antenne ».",
		"La Tour Radio, sans doute.", "Fais attention à toi, petit."]),
}
# Barrière du puits avant le récit de Fargas : aucun texte au dossier (E-14 s'adresse à Fargas) [D].
WELL_BLOCK = ("Sbire", ["Hé, toi ! On ne passe pas !", "Le puits est fermé. Circule."], True)

# Intérieurs (E-29, E-30 ; habitant [D]).
INTERIOR_TEXTS = {
	"azalea_center_garcon": ("Garçon", ["Il paraît que le Champion d'Écorcia est parti voyager.",
		"Dommage, j'aurais voulu le défier."]),
	"route_34_house_homme": ("Homme", ["Ma femme gardait des Pokémon pour les Dresseurs, avant.",
		"Elle a pris sa retraite. La maison est bien calme."]),
	"azalea_house_1_habitant": ("Habitant", ["Le vieux Fargas connaît le puits mieux que personne.",
		"Il y descendait déjà quand il était petit."], True),
}

# Vincent, le vendredi (E-28).
WEEK = {
	"week_friday_vincent": ("Vincent", "week_friday_gift", "super_repel", 2,
		["Le vendredi, je livre le charbon à toute la ville.",
			"Tu sens la fumée ? Ça éloigne les petites bêtes. Prends ça."],
		"{player} reçoit 2 Super Repousses !", "À vendredi !"),
}

# --- Sprites [D] -----------------------------------------------------------------------------
ROLE_SPRITES = {
	"pecheur": "fisher_route_12", "vieille_femme": "aoki", "charbonnier": "hiker",
	"habitante": "beauty", "sbire": "rocket_grunt_m", "fargas": "old_man",
}
VINCENT_SPRITE = "docker"
SLOWPOKE_SPRITE = "pokemon/slowpoke"

# --- Rencontres (dossier §5, plan §2.4) : (identifiant, terrain, moments, taux, créneaux) -------
ENCOUNTERS = {
	"route_34": [
		("route_34_grass_day", "grass", ["morning", "day"], 25, [("sentret", 16, 19, 25),
			("abra", 16, 19, 20), ("nidoran_f", 16, 19, 15), ("nidoran_m", 16, 19, 15),
			("raticate", 16, 19, 15), ("ditto", 16, 19, 10)]),
		("route_34_grass_night", "grass", ["night"], 25, [("hoothoot", 16, 19, 35),
			("raticate", 16, 19, 25), ("ditto", 16, 19, 15), ("nidoran_f", 16, 19, 12),
			("nidoran_m", 16, 19, 13)]),
		# Étang côtier : aucune ligne au dossier [D].
		("route_34_water", "water", None, 5, [("tentacool", 15, 20, 60), ("psyduck", 15, 20, 40)]),
	],
	"ilex_forest": [
		("ilex_forest_grass_morning", "grass", ["morning"], 25, [("teddiursa", 17, 20, 25),
			("paras", 17, 20, 25), ("caterpie", 17, 20, 15), ("weedle", 17, 20, 15),
			("heracross", 17, 20, 5), ("oddish", 17, 20, 15)]),
		("ilex_forest_grass_day", "grass", ["day"], 25, [("paras", 17, 20, 30),
			("caterpie", 17, 20, 20), ("weedle", 17, 20, 20), ("oddish", 17, 20, 20),
			("sentret", 17, 20, 10)]),
		("ilex_forest_grass_night", "grass", ["night"], 25, [("murkrow", 17, 20, 30),
			("noctowl", 17, 20, 15), ("hoothoot", 17, 20, 25), ("oddish", 17, 20, 20),
			("paras", 17, 20, 10)]),
	],
	# Puits : une table pour les deux niveaux, toute la journée (dossier §5) ; taux [D].
	"slowpoke_well": [
		("slowpoke_well_rubble", "rubble", None, 25, [("slowpoke", 18, 22, 45), ("zubat", 18, 22, 45),
			("geodude", 18, 22, 10)]),
		("slowpoke_well_water", "water", None, 5, [("slowpoke", 18, 22, 70), ("poliwag", 18, 22, 30)]),
	],
}
ENCOUNTER_MAPS = {"slowpoke_well": ["slowpoke_well_b1f", "slowpoke_well_b2f"]}

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
			for word in words[3:]:
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
	entry["pages"] = [wrap(page) for page in pages]
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


def well_guard_scene():
	"""Barrière du puits (plan §2.2) : le Sbire refuse le passage, un pas en arrière."""
	return {"variants": [{"unless": ["johto_kurt_told"], "steps": [
		{"face": "sbire_puits", "to": "player"},
		{"face": "player", "to": "sbire_puits"},
		{"dialogue": "azalea_well_block"},
		{"move": "player", "path": ["down"], "keep_facing": True},
	]}]}


def kurt_story_scene():
	"""E-11 à E-14 : le récit chez Fargas, puis devant le puits Fargas fait fuir le Sbire et
	descend. Le drapeau est posé avant le changement de carte (scène interrompue = jouée) ; dans
	Écorcia, le Sbire (absent avec le drapeau) et Fargas sont des acteurs de la scène."""
	return {"variants": [{"unless": ["johto_kurt_told"], "steps": [
		{"face": "fargas", "to": "player"},
		{"dialogue": "azalea_kurt_greeting"},
		{"dialogue": "azalea_kurt_story"},
		{"dialogue": "azalea_kurt_leaves"},
		{"set": ["johto_kurt_told"]},
		{"change_map": "azalea_town", "at": "kurt_scene", "facing": "up"},
		{"spawn": "sbire_scene", "sprite": "rocket_grunt_m", "cell": [38, 8], "facing": "left"},
		{"spawn": "fargas_scene", "sprite": "old_man", "cell": [36, 11], "facing": "up"},
		{"move": "fargas_scene", "to": [36, 8]},
		{"face": "fargas_scene", "to": "sbire_scene"},
		{"emote": "sbire_scene", "kind": "exclamation"},
		{"face": "sbire_scene", "to": "fargas_scene"},
		{"dialogue": "azalea_well_grunt_flees"},
		{"move": "sbire_scene", "to": [37, 8]},
		{"face": "sbire_scene", "to": "up"},
		{"move": "sbire_scene", "path": ["up"]},
		{"despawn": "sbire_scene"},
		{"move": "fargas_scene", "to": [37, 8]},
		{"face": "fargas_scene", "to": "up"},
		{"move": "fargas_scene", "path": ["up"]},
		{"despawn": "fargas_scene"},
	]}]}


def kurt_fall_scene():
	"""E-15 : Fargas, tombé près de l'échelle du B1F, parle au premier passage."""
	return {"variants": [{"if": ["johto_kurt_told"], "unless": ["johto_kurt_fell"], "steps": [
		{"set": ["johto_kurt_fell"]},
		{"emote": "fargas_b1f", "kind": "exclamation"},
		{"face": "fargas_b1f", "to": "player"},
		{"face": "player", "to": "fargas_b1f"},
		{"dialogue": "slowpoke_well_kurt_fall"},
	]}]}


def brace_scene():
	"""E-17 à E-20 : Brace s'avance, combat obligatoire ; vaincu, il s'enfuit par le couloir et
	laisse ses papiers ; Fargas, remis, attend à l'échelle (acteurs posés par la scène : les
	entrées de `data/npcs/` ne se relisent qu'à l'entrée sur la carte). Défaite : réveil au
	Centre d'Écorcia, Brace reste."""
	won = ["johto_brace_defeated"]
	return {"variants": [{"unless": ["johto_brace_defeated"], "steps": [
		{"emote": "brace", "kind": "exclamation"},
		{"move": "brace", "to": {"near": "player", "offsets": [[0, -1], [-1, -1], [1, -1],
			[-1, 0], [1, 0]]}},
		{"face": "player", "to": "brace"},
		{"face": "brace", "to": "player"},
		{"dialogue": "slowpoke_well_brace_before"},
		{"battle": BRACE_ID, "win": won, "lose": ["lost_brace"]},
		{"dialogue": "slowpoke_well_brace_defeated", "if": won},
		{"dialogue": "slowpoke_well_brace_after", "if": won},
		{"move": "brace", "to": [24, 16], "if": won}, # à pied : pas de course pour les Sbires
		{"despawn": "brace", "if": won},
		{"dialogue": "slowpoke_well_brace_flees", "if": won},
		# Défaite : réveil au Centre, la scène s'arrête là (les « spawn » n'ont pas de condition).
		{"wake_up": True, "unless": won},
		{"spawn": "papiers", "sprite": "object/poke_ball_ground", "cell": [25, 5], "facing": "down",
			"dialogue": PAPERS_DIALOGUE, "verb": "take", "turn_to_player": False},
		{"spawn": "fargas_b2f", "sprite": "old_man", "cell": [5, 5], "facing": "down",
			"dialogue": "slowpoke_well_b2f_fargas_b2f"},
	]}]}


def papers_scene():
	"""E-21 : l'Ordre de mission et la Carte d'accès entrent au Sac."""
	return {"variants": [{"unless": ["johto_radio_pass"], "steps": [
		{"despawn": "papiers"},
		{"give": "mission_order", "count": 1},
		{"give": "radio_card", "count": 1},
		{"dialogue": "slowpoke_well_papers_taken"},
		{"set": ["johto_radio_pass"]},
	]}]}


def kings_rock_scene():
	"""E-23, E-24 : Fargas remercie et donne la Roche Royale ; les Ramoloss rentrent."""
	return {"variants": [{"unless": ["johto_slowpoke_well_cleared"], "steps": [
		{"face": "fargas_b2f", "to": "player"},
		{"dialogue": "slowpoke_well_kurt_thanks"},
		{"dialogue": "slowpoke_well_kurt_kings_rock"},
		{"give": "kings_rock", "count": 1},
		{"dialogue": "slowpoke_well_kings_rock_received"},
		{"set": ["johto_slowpoke_well_cleared"]},
	]}]}


def week_scene(flag, item, count, received_id):
	return {"variants": [{"unless": [flag], "steps": [
		{"give": item, "count": count},
		{"dialogue": received_id},
		{"set": [flag]},
	]}]}


def trainer_entry(trainer_id, name, klass, prize, team):
	entry = {"name": name}
	if klass:
		entry["class"] = klass
	entry.update({
		"ai": "random", "can_lose": False, "heal_after": False,
		"gives_exp": True, "prize_money": 0, "prize_per_level": prize,
		"team": [{"species": species, "level": level} for species, level in team],
	})
	return entry


def main():
	for plan, map_id in MAPS:
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
			trainers[trainer_id] = trainer_entry(trainer_id, name, klass, prize, team)
		for ident, (kind, cells, attrs, _comment) in positions.items():
			key = (map_id, ident)
			cell = list(cells[0])
			if kind == "dresseur":
				trainer_id = attrs["trainer"]
				if trainer_id == BRACE_ID:
					npcs[ident] = {"cell": cell, "facing": attrs["facing"], "sprite": "rocket_grunt_m"}
					npcs[ident].update(flag_lists(attrs))
					trainers[trainer_id] = BRACE
					continue
				sprite = TRAINERS[map_id][trainer_id][2]
				npcs[ident] = {
					"cell": cell, "facing": attrs["facing"], "sprite": sprite,
					"dialogue": trainer_id + "_after",
					"trainer": {"id": trainer_id, "sight": int(attrs["sight"]),
						"before": trainer_id + "_before", "defeated": trainer_id + "_defeated"},
				}
			elif kind == "pnj":
				role = attrs.get("role", "")
				entry = {"cell": cell, "facing": attrs.get("facing", "down")}
				if "jour" in attrs:
					entry["if_weekday"] = [WEEKDAYS[attrs["jour"]]]
				entry.update(flag_lists(attrs))
				if ident == "vincent":
					entry["sprite"] = VINCENT_SPRITE
					entry["dialogue"] = "week_friday_vincent"
				elif ident == "habitante":
					entry["sprite"] = ROLE_SPRITES[role]
					entry["dialogue"] = "azalea_town_habitante"
					dialogues["azalea_town_habitante"] = {"speaker": "Habitante", "variants": [
						{"if": ["johto_slowpoke_well_cleared"],
							"pages": [wrap(p) for p in TOWNSWOMAN_AFTER]},
						{"pages": [wrap(p) for p in TOWNSWOMAN_BEFORE]},
					]}
				elif ident == "sbire_puits":
					entry["sprite"] = ROLE_SPRITES[role]
					entry["dialogue"] = "azalea_well_block"
					dialogues["azalea_well_block"] = dialogue(*WELL_BLOCK)
				elif ident == "fargas_b1f":
					entry["sprite"] = ROLE_SPRITES[role]
					entry["dialogue"] = "slowpoke_well_kurt_fall"
				elif ident == "fargas_b2f":
					entry["sprite"] = ROLE_SPRITES[role]
					entry["dialogue"] = "slowpoke_well_b2f_fargas_b2f"
				else:
					entry["sprite"] = ROLE_SPRITES[role]
					dialogue_id = "%s_%s" % (map_id, ident)
					entry["dialogue"] = dialogue_id
					dialogues[dialogue_id] = dialogue(*TEXTS[key])
				npcs[ident] = entry
			elif kind == "panneau":
				dialogues["%s_%s" % (map_id, ident)] = dialogue(*TEXTS[key])
			elif kind == "examen":
				if ident == "autel":
					# JOH9 : la Balle Verte posée sur l'autel fait venir Celebi (dossier JOH-10 §11).
					dialogues["ilex_forest_autel"] = {"narration": True, "variants": [
						{"if": ["johto_green_ball_received"], "unless": ["johto_celebi_done"],
							"cutscene": "ilex_altar_celebi"},
						{"set": [attrs["drapeau"]], "pages": [wrap(p) for p in SHRINE]}]}
				elif ident == "ramoloss_margelle":
					# Un Ramoloss peint sur la margelle (PNJ, examen E-31) après le puits.
					entry = {"cell": cell, "facing": "down", "sprite": SLOWPOKE_SPRITE,
						"dialogue": "azalea_town_ramoloss_margelle", "turn_to_player": False}
					entry.update(flag_lists(attrs))
					npcs[ident] = entry
					dialogues["azalea_town_ramoloss_margelle"] = dialogue(NARRATION, SLOWPOKE_WELLHEAD)
			elif kind == "pokemon":
				species = attrs["espece"]
				if species == "farfetchd":
					# Aucune planche de Canarticho : examen seul (outil des cartes) [D].
					dialogues["ilex_forest_canarticho"] = dialogue(*TEXTS[key])
					continue
				entry = {"cell": cell, "facing": "down", "sprite": SLOWPOKE_SPRITE,
					"turn_to_player": False}
				entry.update(flag_lists(attrs))
				if attrs.get("variante") == "sans_queue":
					entry["dialogue"] = "slowpoke_well_b2f_ramoloss_sans_queue"
					dialogues["slowpoke_well_b2f_ramoloss_sans_queue"] = dialogue(NARRATION,
						SLOWPOKE_TAILLESS, True)
				else:
					entry["dialogue"] = "azalea_town_ramoloss"
					dialogues["azalea_town_ramoloss"] = dialogue(NARRATION, SLOWPOKE_TOWN)
				npcs[ident] = entry
			elif kind == "objet_visible":
				if ident == "papiers":
					# Posés par la scène de Brace ; au rechargement, l'entrée prend le relais.
					npcs[ident] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
						"dialogue": PAPERS_DIALOGUE, "verb": "take", "turn_to_player": False}
					npcs[ident].update(flag_lists(attrs))
					dialogues[PAPERS_DIALOGUE] = {"cutscene": "slowpoke_well_papers"}
					cutscenes["slowpoke_well_papers"] = papers_scene()
					continue
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
				if ident == "barriere_puits":
					cutscenes["azalea_well_guard"] = well_guard_scene()
				elif ident == "scene_brace":
					cutscenes["slowpoke_well_brace"] = brace_scene()
					for did in ("slowpoke_well_brace_before", "slowpoke_well_brace_defeated",
							"slowpoke_well_brace_after", "slowpoke_well_brace_flees"):
						dialogues[did] = dialogue(*KURT[did])
		# Scènes propres à une carte (hors grille) : chute de Fargas (B1F), Fargas et la Roche
		# Royale (B2F).
		if map_id == "slowpoke_well_b1f":
			cutscenes["slowpoke_well_kurt_fall"] = kurt_fall_scene()
			dialogues["slowpoke_well_kurt_fall"] = dialogue(*KURT["slowpoke_well_kurt_fall"])
		if map_id == "slowpoke_well_b2f":
			dialogues["slowpoke_well_b2f_fargas_b2f"] = {"speaker": "Fargas", "variants": [
				{"unless": ["johto_slowpoke_well_cleared"], "cutscene": "slowpoke_well_kings_rock"},
				{"pages": [wrap(KURT["slowpoke_well_kurt_thanks"][1][2])]}]}
			cutscenes["slowpoke_well_kings_rock"] = kings_rock_scene()
			for did in ("slowpoke_well_kurt_thanks", "slowpoke_well_kurt_kings_rock",
					"slowpoke_well_kings_rock_received", "slowpoke_well_papers_taken"):
				dialogues[did] = dialogue(*KURT[did])
		write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)
		write_json(os.path.join(DATA, "dialogues", PREFIX + map_id + ".json"), dialogues)
		if cutscenes:
			write_json(os.path.join(DATA, "cutscenes", PREFIX + map_id + ".json"), cutscenes)
		if trainers:
			write_json(os.path.join(DATA, "trainers", map_id + ".json"), trainers)
	write_encounters()
	write_interiors()
	write_week()


def write_encounters():
	for group, tables in ENCOUNTERS.items():
		out = {}
		for table_id, terrain, periods, rate, slots in tables:
			table = {"maps": ENCOUNTER_MAPS.get(group, [group]), "terrain": terrain}
			if periods:
				table["period"] = periods
			table["rate"] = rate
			if terrain != "water":
				table["ramp"] = {"from_step": 15, "max_steps": 20}
			table["slots"] = [{"species": s, "levels": [lo, hi], "weight": w}
				for s, lo, hi, w in slots]
			out[table_id] = table
		write_json(os.path.join(DATA, "encounters", group + ".json"), out)


def write_interiors():
	"""Maison de Fargas (récit E-11 à E-13, puis E-25), Centre (garçon E-29), Boutique, maison
	d'Écorcia (habitant [D]), maison de la Route 34 (E-30). Cases des grilles de Lavanville
	réutilisées (plan §2.1)."""
	dialogues = {
		"azalea_kurt_house_fargas": {"speaker": "Fargas", "variants": [
			{"unless": ["johto_kurt_told"], "cutscene": "azalea_kurt_story"}]},
		"azalea_kurt_house_fargas_home": {"speaker": "Fargas", "variants": [
			{"pages": [wrap(p) for p in KURT["azalea_kurt_house_after"][1]]}]},
	}
	for did in ("azalea_kurt_greeting", "azalea_kurt_story", "azalea_kurt_leaves",
			"azalea_well_grunt_flees"):
		dialogues[did] = dialogue(*KURT[did])
	for did, spec in INTERIOR_TEXTS.items():
		dialogues[did] = dialogue(*spec)
	cutscenes = {"azalea_kurt_story": kurt_story_scene()}
	write_json(os.path.join(DATA, "npcs", "azalea_kurt_house.json"), {
		"fargas": {"cell": [7, 5], "facing": "down", "sprite": "old_man",
			"dialogue": "azalea_kurt_house_fargas", "unless": ["johto_kurt_told"]},
		"fargas_home": {"cell": [7, 5], "facing": "down", "sprite": "old_man",
			"dialogue": "azalea_kurt_house_fargas_home", "if": ["johto_slowpoke_well_cleared"]},
	})
	write_json(os.path.join(DATA, "npcs", "azalea_center.json"), {
		"nurse": {"cell": [7, 3], "facing": "down", "sprite": "nurse"},
		"garcon": {"cell": [11, 5], "facing": "left", "sprite": "kid",
			"dialogue": "azalea_center_garcon"},
	})
	write_json(os.path.join(DATA, "npcs", "azalea_mart.json"), {
		"clerk": {"cell": [7, 3], "facing": "down", "sprite": "clerk"},
	})
	write_json(os.path.join(DATA, "npcs", "azalea_house_1.json"), {
		"habitant": {"cell": [12, 6], "facing": "left", "sprite": "old_man",
			"dialogue": "azalea_house_1_habitant"},
	})
	write_json(os.path.join(DATA, "npcs", "route_34_house.json"), {
		"homme": {"cell": [10, 6], "facing": "left", "sprite": "gentleman",
			"dialogue": "route_34_house_homme"},
	})
	write_json(os.path.join(DATA, "dialogues", PREFIX + "azalea_interiors.json"), dialogues)
	write_json(os.path.join(DATA, "cutscenes", PREFIX + "azalea_interiors.json"), cutscenes)


def write_week():
	"""Vincent, charbonnier du vendredi (dossier §9) : don une seule fois."""
	dialogues = {}
	cutscenes = {}
	for did, (speaker, flag, item, count, before, system, after) in WEEK.items():
		received_id = flag.replace("_gift", "_received")
		dialogues[did] = {"speaker": speaker, "variants": [
			{"unless": [flag], "cutscene": flag, "pages": [wrap(p) for p in before]},
			{"if": [flag], "pages": [after]},
		]}
		dialogues[received_id] = dialogue(NARRATION, [system])
		cutscenes[flag] = week_scene(flag, item, count, received_id)
	write_json(os.path.join(DATA, "dialogues", PREFIX + "week.json"), dialogues)
	write_json(os.path.join(DATA, "cutscenes", PREFIX + "week.json"), cutscenes)


if __name__ == "__main__":
	main()
