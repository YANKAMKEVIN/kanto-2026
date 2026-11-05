#!/usr/bin/env python3
"""Données de jeu du jalon JOHP3 (arc des Pierres : Ébènelle, Antre du Dragon, Sanctuaire),
générées depuis les grilles.

Lit les positions de `tools/plans/blackthorn_city.txt`, `dragons_den_1f.txt`,
`dragons_den_sanctuary.txt` (validées le 2026-11-05, elles font foi) et écrit, d'après
`docs/design/dossier-joh-11-arc-pierres.md` (textes §17 P-20 à P-39, P-49 à P-53, P-56 ; Dresseurs
§10 ; rencontres §11 ; objets §12) et le plan `docs/tech/jalon-joh-pierres.md` §5 :
  - `data/npcs/<carte>.json` (cartes et intérieurs d'Ébènelle) ;
  - `data/trainers/johp3.json` ;
  - `data/encounters/blackthorn_city.json`, `dragons_den.json` ;
  - `data/dialogues/johp3_blackthorn.json` ;
  - `data/cutscenes/johp3_blackthorn.json`.
Les textes absents du dossier sont marqués « draft » et listés dans
`tests/integration/test_no_draft_in_data.gd` (PENDING_DRAFTS).

Usage : python3 -I tools/gen_johp3_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")

MAPS = ["blackthorn_city", "dragons_den_1f", "dragons_den_sanctuary"]

# Largeur d'une ligne de bulle (3 lignes au plus, `UiTokens.DIALOG_MAX_LINES`) [D].
WRAP = 36
NARRATION = None
GRUNT = "Sbire Rocket"

# Drapeaux (dossier §7).
CALLED = "johto_clan_called"
ARRIVED = "johto_blackthorn_arrived"
TRIAL_OPEN = "johto_clan_trial_open"
GUARDIANS_DONE = "johto_clan_guardians_done"
TRIAL_DONE = "johto_clan_trial_done"
STONE_BREATH = "johto_stone_breath"
AWAKENED = "johto_stones_awakened"
CENERE_WON = "johto_cenere_defeated_arc"
RETURNED = "johto_team_returned"
ACT2 = "johto_act2"
# Drapeau de travail [D] : le soin de l'Aïeule, une fois (P-25).
HEALED = "johto_clan_healed"

YSOLDE_ID = "den_ysolde"
CENERE_ID = "den_cenere"
GUARDIANS = ["den_guardian_water", "den_guardian_stone", "den_guardian_sky"]

# --- Dresseurs (dossier §10) : id → (nom, classe, sprite, prix par niveau [D], équipe,
# (avant, défaite, après)) ---------------------------------------------------------------------
TRAINERS = {
	"blackthorn_apprentice_nolwenn": ("Apprentie Nolwenn", "topdresseuse", "cooltrainer_f", 40,
		[("dratini", 36), ("seadra", 36)],
		("Je suis apprentie, mais mon Draco, lui, ne l'est pas !",
			"Il a encore à apprendre. Moi aussi.",
			"L'Aïeule entend tout. Ne dis pas de mal d'elle, même ici.")),
	"blackthorn_apprentice_malo": ("Apprenti Malo", "topdresseur", "cooltrainer_m", 40,
		[("dragonair", 37), ("gyarados", 36)],
		("Tu es venu sur le Dracolosse de Corentin ? Il t'a parlé tout le long ?",
			"Il parle mieux qu'il ne se bat. Moi aussi.",
			"Il n'y a qu'un moyen de quitter le village : par les airs.")),
	"blackthorn_hiker_herve": ("Montagnard Hervé", "montagnard", "mountaineer", 35,
		[("graveler", 37), ("onix", 37)],
		("Je suis monté à pied. Trois semaines. Montre-moi que ça en valait la peine.",
			"Ça en valait la peine.",
			"Acajou est juste derrière ces montagnes. Il n'y a pas de chemin.")),
	"den_grunt_ab": (GRUNT, "sbire_rocket", "rocket_grunt_m", 40,
		[("houndoom", 37), ("weezing", 37)],
		("Le clan ne nous a pas vus entrer. Toi non plus, tu ne nous as pas vus !",
			"Tu nous as vus.", "On prépare le chemin de Cenere.")),
	"den_grunt_ac": (GRUNT, "sbire_rocket_f", "rocket_grunt_f", 40,
		[("raticate", 38), ("noctowl", 38)],
		("Ces dragons me font peur. Pas toi.", "Si, un peu toi aussi.",
			"Elle arrive, tu sais. Elle arrive toujours.")),
	"den_guardian_water": ("Gardienne de l'Eau", "topdresseuse", "cooltrainer_f", 50,
		[("seadra", 38), ("dewgong", 38), ("dragonair", 39)],
		("L'eau use la pierre, et elle a tout le temps.", "Tu ne t'es pas laissé user.",
			"L'Aïeule te soignera quand tu auras les trois.")),
	"den_guardian_stone": ("Gardien de la Pierre", "topdresseur", "cooltrainer_m", 50,
		[("golem", 39), ("onix", 39), ("dragonair", 39)],
		("Tu trembles ? La pierre, non.", "Tu ne trembles pas non plus.",
			"Il reste deux portes. Ou une. Je ne compte pas pour toi.")),
	"den_guardian_sky": ("Gardien du Ciel", "topdresseur", "cooltrainer_m", 50,
		[("fearow", 40), ("noctowl", 40), ("dragonair", 40)],
		("Regarde en haut. C'est là que tout tombe.", "Tu es resté debout.",
			"Ysolde t'attend au Sanctuaire.")),
}

# Grands combats (lancés par des scènes) ; réglés par simulation (dossier §10).
YSOLDE = {
	"name": "Ysolde", "class": "topdresseuse", "ai": "smart",
	"can_lose": False, "heal_after": False, "gives_exp": True, "prize_money": 0,
	"prize_per_level": 100, "start_message": False, "end_message": False, "bag": True,
	"switch": True,
	"team": [{"species": "gyarados", "level": 42}, {"species": "dragonair", "level": 42},
		{"species": "dragonair", "level": 43}, {"species": "kingdra", "level": 43},
		{"species": "dragonite", "level": 45}],
}
# Attaques [D] et niveaux [D] (décision de Kevin du 2026-11-05, au-delà de JH-74 et JH-78 : joueur
# attentif autour de 80 % du premier coup, naïf pas impuissant ; `tools/sim/gen_johp3_scenarios.py`,
# résultats au plan §5.5).
MOVE_SETS = {
	"sneasel": ["ice_beam", "feint_attack", "slash", "quick_attack"],
	"weezing": ["sludge", "flamethrower", "thunderbolt", "explosion"],
	"noctowl": ["psychic", "hypnosis", "wing_attack", "confuse_ray"],
	"dewgong": ["ice_beam", "surf", "rest", "body_slam"],
	"fearow": ["drill_peck", "agility", "double_edge", "mirror_move"],
	"arbok": ["sludge", "earthquake", "glare", "crunch"],
	"houndoom": ["flamethrower", "crunch", "solar_beam", "feint_attack"],
}
# Farfuret d'abord [D] : « Recommence, Farfuret » (P-32), « Cenere envoie Farfuret, le même » (§13.2).
CENERE = {
	"name": "Cenere", "class": "sbire_rocket_f", "ai": "smart",
	"can_lose": False, "heal_after": False, "gives_exp": True, "prize_money": 0,
	"prize_per_level": 60, "start_message": False, "end_message": False, "switch": True,
	"bag": True,
	"team": [{"species": "sneasel", "level": 61}, {"species": "weezing", "level": 59},
		{"species": "wobbuffet", "level": 59}, {"species": "noctowl", "level": 60}],
}

# --- Sprites [D] ------------------------------------------------------------------------------
ROLE_SPRITES = {"messager": "courier", "aieule": "aoki", "ysolde": "cooltrainer_f",
	"cenere": "rocket_grunt_f"}
DRAGONITE_SPRITE = "pokemon/dragonite"
SNEASEL_SPRITE = "pokemon/sneasel"

# --- Textes (dossier §17) ---------------------------------------------------------------------
T = {
	# P-20, P-21 : Corentin à Rosalia, le vol (cutscene `johto_corentin_flight`).
	"johp3_corentin_call": ("Corentin", ["Enfin ! Toi, c'est {player} ? Je te cherche depuis Oliville !",
		"Corentin, messager du clan des dragons, d'Ébènelle.",
		"L'Aïeule a entendu une pierre se réveiller. Elle a dit : « amène-moi celui qui la porte. »",
		"Tu as déjà volé sur un Dracolosse ? Non ? C'est très facile. Tiens-toi bien."]),
	"johp3_flight_takeoff": (NARRATION, ["Le Dracolosse de Corentin déploie ses ailes !",
		"{player} s'accroche !"]),
	# P-56 : après le premier vol, depuis Rosalia (JH-79).
	"johp3_corentin_rosalia": ("Corentin", ["Ébènelle ? Monte !",
		"Il paraît que je parle trop. Tu trouves que je parle trop ?"]),
	# Depuis Ébènelle, avant et après l'arc : aucun texte au dossier [D].
	"johp3_corentin_blackthorn": ("Corentin", ["Rosalia ? Monte !"], True),
	# P-52 (Corentin), P-38 : le retour.
	"johp3_corentin_missed": ("Corentin", ["J'ai tout raté ! J'étais dehors avec le Dracolosse !"]),
	"johp3_corentin_return": ("Corentin", [
		"Les pierres sont éteintes, l'Aïeule dit qu'elles ont fini leur travail.",
		"Et les sages de Rosalia ont appelé le clan. Ils te cherchent.",
		"Allez, je te dépose devant leur porte !"]),
	# Le joueur a quitté Ébènelle par son propre Vol : P-38 sans le vol.
	"johp3_corentin_return_rosalia": ("Corentin", [
		"Les pierres sont éteintes, l'Aïeule dit qu'elles ont fini leur travail.",
		"Et les sages de Rosalia ont appelé le clan. Ils te cherchent."]),
	# P-41 : le panneau d'Ébènelle et celui de l'Antre, à la barrière.
	"blackthorn_city_panneau_ville": (NARRATION, ["ÉBÈNELLE", "Le village du clan des dragons"]),
	"johp3_den_closed": (NARRATION, ["ANTRE DU DRAGON", "Réservé au clan"]),
	# Barrière de la descente au Sanctuaire : aucun texte au dossier [D].
	"johp3_sanctuary_closed": (NARRATION, ["Un souffle chaud remonte de l'escalier.",
		"Les trois Gardiens ne t'ont pas encore laissé passer."], True),
	# P-26, P-27 : Ysolde.
	"johp3_ysolde_before": ("Ysolde", ["Je suis Ysolde.",
		"Tu n'as que de jeunes Pokémon, et une mission qui n'est pas la tienne.",
		"Moi, je n'ai rien contre toi. Mes dragons non plus. C'est pour ça qu'ils ne te feront aucun cadeau."]),
	"johp3_ysolde_defeated": ("Ysolde", ["… Tu tiens debout."]),
	"johp3_ysolde_stone": ("Ysolde", ["Le clan garde cette pierre depuis sept cents ans.",
		"Elle est à toi. Porte-la à l'autel."]),
	"johp3_stone_breath_received": (NARRATION, ["{player} obtient la Pierre Souffle !"]),
	"johp3_ysolde_waiting": ("Ysolde", ["Porte-la à l'autel."]),
	# P-28 à P-33 : l'autel.
	"johp3_cenere_arrives": ("Cenere", ["Merci d'avoir fait le voyage.",
		"J'ai ma pierre. Tu as les deux autres.", "Et moi, j'ai ceci."]),
	"johp3_cenere_case": (NARRATION, ["Cenere pose une mallette à ses pieds."]),
	"johp3_cenere_deal": ("Cenere", ["Tes six Pokémon contre tes pierres. Le calcul est simple."]),
	"johp3_cenere_hesitate": ("Cenere", ["Tu hésites ? Regarde ce que valent tes Pokémon."]),
	"johp3_sneasel_strike": (NARRATION,
		["Le Farfuret de Cenere bondit ! {lead_pokemon} est projeté contre l'autel !"]),
	"johp3_cenere_proof": ("Cenere", ["Voilà ce que tu as. Voilà ce que j'ai. Les pierres, maintenant."]),
	"johp3_stones_gather": (NARRATION, ["Les pierres se mettent à trembler.",
		"La Pierre Marée s'échappe de la main de Cenere !",
		"Les trois pierres se rejoignent sur l'autel !"]),
	"johp3_ysolde_truth": ("Ysolde", ["Elles ne se donnent qu'à qui a passé l'épreuve."]),
	"johp3_cenere_error": ("Cenere", ["… Ce n'était pas dans les données."]),
	"johp3_cenere_before": ("Cenere", ["… C'est impossible. Recommence, Farfuret."]),
	"johp3_cenere_defeated": ("Cenere", ["… Ils changent tout. Deuxième erreur."]),
	"johp3_cenere_after": ("Cenere", ["La mallette n'est plus utile. Garde-la.",
		"Le maître n'a plus besoin des pierres. Il a mieux : toi.", "Tu verras."]),
	"johp3_cenere_exit": (NARRATION, ["Cenere s'en va…"]),
	# P-34, P-36, P-37 : le retour de l'équipe (T-27, T-29, T-30 déplacés). P-35 : `TeamReturnOverlay`.
	"johp3_reunion": (NARRATION, [
		"{returning_pokemon} sort de sa Poké Ball et bondit vers {player} !",
		"{player} retrouve son équipe et son sac !"]),
	"johp3_storage_back": (NARRATION, ["Connexion au réseau de Kanto…", "…",
		"Connexion rétablie ! Les autres Pokémon sont au Stockage."]),
	"johp3_bags_merged": (NARRATION, ["Les objets de ton ancien sac ont rejoint les nouveaux."]),
	# P-53 : l'autel, après.
	"dragons_den_sanctuary_autel": (NARRATION, ["Trois pierres ternes, posées sur l'autel.",
		"Elles sont froides, maintenant."]),
	# Intérieurs (habitants : aucun texte au dossier [D]).
	"blackthorn_center_apprenti": ("Apprenti", [
		"Le clan n'a pas besoin de Boutique : on vit de peu, ici.",
		"Pour le reste, il y a Corentin."], True),
	"blackthorn_house_1_habitante": ("Habitante", [
		"Mon fils veut devenir Gardien.",
		"Je lui ai dit de finir sa soupe d'abord."], True),
}

ELDER_INTRO = ["Approche. Non, ne dis rien. Je t'ai entendu monter.",
	"La pierre grise est avec toi. La bleue est partie sur l'eau. La blanche dort ici, chez nous.",
	"Mes yeux ne voient plus, mais les pierres parlent fort."]
ELDER_TRIAL = ["La blanche ne se donne pas.",
	"Le dragon ne juge pas la force. Il juge ce qui reste quand on n'en a plus.",
	"Va dans l'Antre. Trois Gardiens, puis ma petite-fille.",
	"Si tu tiens debout à la fin, la pierre est à toi."]
ELDER_AFTER = ["Ce qui dort sous Rosalia ne dormira plus longtemps.",
	"Les pierres n'y sont plus pour rien. Les hommes, si."]
# P-54 : le doyen de Rosalia pendant l'arc.
ELDER_P54 = ["Les pierres ? Une vieille histoire.",
	"Ces hommes frappent à ma porte,\net je ne l'ouvre pas.\nAlors ils en cherchent une autre."]
HEAL_LINE = "Viens, je soigne ton équipe. Une fois. Pas deux."
HEAL_DONE = "L'équipe de {player} est soignée."
YSOLDE_AFTER = ["Cette femme a porté sa pierre jusqu'à toi. Elle n'aurait pas dû.",
	"Le clan te doit la fin de sa garde."]

# --- Rencontres (dossier §11) : (identifiant, terrain, moments, taux, créneaux) -----------------
ENCOUNTERS = {
	"blackthorn_city": [
		("blackthorn_city_grass_day", "grass", ["morning", "day"], 25, [("machoke", 33, 37, 25),
			("graveler", 33, 37, 25), ("fearow", 33, 37, 25), ("marill", 33, 37, 25)]),
		("blackthorn_city_grass_night", "grass", ["night"], 25, [("noctowl", 33, 37, 35),
			("graveler", 33, 37, 30), ("golbat", 33, 37, 35)]),
	],
	"dragons_den": [
		("dragons_den_rubble", "rubble", None, 25, [("dratini", 34, 38, 45), ("dragonair", 34, 38, 10),
			("magikarp", 34, 38, 25), ("horsea", 34, 38, 20)]),
	],
}
ENCOUNTER_MAPS = {"dragons_den": ["dragons_den_1f"]}

CELL_RE = re.compile(r"^(\d+)(?:\.\.(\d+))?,(\d+)(?:\.\.(\d+))?$")


def read_plan(name):
	"""Positions de la grille : id → (type, cases, attributs, commentaire)."""
	positions = {}
	section = None
	with open(os.path.join(PLANS, name + ".txt"), encoding="utf-8") as handle:
		for raw in handle:
			line = raw.rstrip("\n")
			if line.startswith("POSITIONS"):
				section = "pos" if line.strip() == "POSITIONS" else None
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


def say(dialogue_id, **conditions):
	step = {"dialogue": dialogue_id}
	step.update(conditions)
	return step


def trainer_entry(name, klass, prize, team):
	return {"name": name, "class": klass, "ai": "random", "can_lose": False, "heal_after": False,
		"gives_exp": True, "prize_money": 0, "prize_per_level": prize,
		"team": [{"species": species, "level": level} for species, level in team]}


# --- Scènes -----------------------------------------------------------------------------------


def corentin_flight_scene():
	"""Rosalia (P-20, P-21, P-56) : le vol vers Ébènelle ; le premier appelle le clan. Drapeau posé
	avant le changement de carte (scène interrompue = jouée). Équipe rendue sans passer par son vol
	de retour (le Vol d'un Pokémon de Johto) : P-38 sans le vol, `johto_act2` tout de même."""
	fly = [
		{"dragon_flight": "out"},
		{"rest_point": "blackthorn_center"},
		{"change_map": "blackthorn_city", "at": "from_dragon", "facing": "up"},
		{"dragon_flight": "land"},
	]
	return {"variants": [
		{"if": [RETURNED], "unless": [ACT2], "steps": [
			{"face": "corentin", "to": "player"},
			say("johp3_corentin_return_rosalia"),
			{"set": [ACT2]},
		]},
		{"unless": [CALLED], "steps": [
			{"face": "corentin", "to": "player"},
			say("johp3_corentin_call"),
			say("johp3_flight_takeoff"),
			{"set": [CALLED, ARRIVED]},
		] + fly},
		{"steps": [{"face": "corentin", "to": "player"}, say("johp3_corentin_rosalia")] + fly},
	]}


def corentin_back_scene():
	"""Ébènelle : le retour (P-52, P-38) à la fin de l'arc, `johto_act2` ; sinon, simple vol [D]."""
	fly = [
		{"dragon_flight": "back"},
		{"change_map": "ecruteak_city", "at": "from_dragon", "facing": "down"},
		{"dragon_flight": "land"},
	]
	return {"variants": [
		{"if": [RETURNED], "unless": [ACT2], "steps": [
			{"face": "corentin", "to": "player"},
			say("johp3_corentin_missed"),
			say("johp3_corentin_return"),
			{"set": [ACT2]},
		] + fly},
		{"steps": [{"face": "corentin", "to": "player"}, say("johp3_corentin_blackthorn")] + fly},
	]}


def den_barrier_scene():
	"""L'Antre avant l'Aïeule (P-41 et un pas en arrière)."""
	return {"variants": [{"unless": [TRIAL_OPEN], "steps": [
		say("johp3_den_closed"),
		{"move": "player", "path": ["left"], "keep_facing": True},
	]}]}


def sanctuary_barrier_scene():
	"""Descente au Sanctuaire : les trois Gardiens battus, le passage reste ouvert."""
	beaten = ["beaten_" + ident for ident in GUARDIANS]
	return {"variants": [
		{"if": beaten, "unless": [GUARDIANS_DONE], "steps": [{"set": [GUARDIANS_DONE]}]},
		{"unless": [GUARDIANS_DONE], "steps": [
			say("johp3_sanctuary_closed"),
			{"move": "player", "path": ["down"], "keep_facing": True},
		]},
	]}


def ysolde_scene():
	"""P-26, combat, P-27, Pierre Souffle. Défaite : Centre d'Ébènelle, Gardiens toujours battus.
	Combat gagné sans pierre (application tuée) : la pierre seule, au passage suivant."""
	won = [TRIAL_DONE]
	stone = [
		say("johp3_ysolde_stone"),
		{"give": "stone_breath", "count": 1},
		say("johp3_stone_breath_received"),
		{"set": [STONE_BREATH]},
	]
	return {"variants": [
		{"unless": [TRIAL_DONE], "steps": [
			{"emote": "ysolde", "kind": "exclamation"},
			{"move": "ysolde", "to": {"near": "player", "offsets": [[0, -1], [-1, -1], [1, -1]]}},
			{"face": "ysolde", "to": "player"},
			{"face": "player", "to": "ysolde"},
			say("johp3_ysolde_before"),
			{"rest_point": "blackthorn_center"},
			{"battle": YSOLDE_ID, "win": won},
			{"wake_up": True, "unless": won},
			say("johp3_ysolde_defeated"),
		] + stone},
		{"if": [TRIAL_DONE], "unless": [STONE_BREATH], "steps": [
			{"face": "ysolde", "to": "player"},
			{"face": "player", "to": "ysolde"},
		] + stone},
	]}


def cenere_battle_steps():
	"""P-32, combat, P-33, puis le retour de l'équipe. Défaite : Centre d'Ébènelle, réveil acquis."""
	won = [CENERE_WON]
	return [
		{"face": "cenere", "to": "player"},
		{"face": "player", "to": "cenere"},
		say("johp3_cenere_before"),
		{"rest_point": "blackthorn_center"},
		{"battle": CENERE_ID, "win": won},
		{"wake_up": True, "unless": won},
		say("johp3_cenere_defeated"),
		say("johp3_cenere_after"),
		say("johp3_cenere_exit"),
		{"move": "cenere", "to": [17, 5]},
		{"despawn": "cenere"},
	]


def return_steps():
	"""P-34 à P-37 (`jalon-joh-pierres.md` §5.3) : étapes reprises du bureau, sans changement."""
	return [
		say("johp3_reunion"),
		{"return_team": True},
		say("johp3_storage_back", **{"if": ["johto_return_stored"]}),
		say("johp3_bags_merged"),
		{"save": "retour de l'équipe (Sanctuaire, JOHP3)"},
		{"unset": ["johto_return_stored"]},
	]


def altar_scene():
	"""Rangée de l'autel (dossier §13, §14) : une seule scène à variantes.
	- Première fois : P-28, P-28b, P-29, P-30, le Réveil (`stones_awaken`, une écriture), P-31, puis
	  Cenere sur le même thème.
	- Réveil acquis (défaite, application tuée) : Cenere à l'autel, sans revoir le Réveil.
	- Cenere battue, équipe pas encore rendue (application tuée) : le retour seul."""
	first = [
		{"spawn": "cenere", "sprite": ROLE_SPRITES["cenere"], "cell": [17, 5], "facing": "left"},
		{"emote": "cenere", "kind": "exclamation"},
		{"move": "cenere", "to": {"near": "player", "offsets": [[1, 0], [1, -1], [-1, 0], [-1, -1]]}},
		{"face": "cenere", "to": "player"},
		{"face": "player", "to": "cenere"},
		say("johp3_cenere_arrives"),
		say("johp3_cenere_case"),
		say("johp3_cenere_deal"),
		say("johp3_cenere_hesitate"),
		# Farfuret surgit devant l'autel, sans marcher : il n'a qu'une pose de carte.
		{"spawn": "farfuret", "sprite": SNEASEL_SPRITE, "cell": [10, 5], "facing": "down"},
		{"flash": 1},
		{"react": "player"},
		say("johp3_sneasel_strike"),
		say("johp3_cenere_proof"),
		say("johp3_stones_gather", music="stop"),
		say("johp3_ysolde_truth"),
		say("johp3_cenere_error"),
		{"despawn": "farfuret"},
		# P-31 est dite par `AwakeningOverlay` (dossier §13.2 : avant l'écran du Réveil).
		{"stones_awaken": True},
	]
	return {"variants": [
		{"if": [STONE_BREATH], "unless": [AWAKENED], "steps": first + cenere_battle_steps()
			+ return_steps()},
		{"if": [AWAKENED], "unless": [CENERE_WON], "steps": cenere_battle_steps() + return_steps()},
		{"if": [CENERE_WON], "unless": [RETURNED], "steps": return_steps()},
	]}


# --- Assemblage -------------------------------------------------------------------------------


def main():
	dialogues = {}
	cutscenes = {
		"johto_corentin_flight": corentin_flight_scene(),
		"blackthorn_corentin_back": corentin_back_scene(),
		"blackthorn_den_barrier": den_barrier_scene(),
		"dragons_den_barrier": sanctuary_barrier_scene(),
		"dragons_den_ysolde": ysolde_scene(),
		"dragons_den_altar": altar_scene(),
	}
	with_moves(CENERE)
	trainers = {YSOLDE_ID: YSOLDE, CENERE_ID: CENERE}
	for trainer_id, (name, klass, _sprite, prize, team, lines) in TRAINERS.items():
		before, defeated, after = lines
		dialogues[trainer_id + "_before"] = dialogue(name, [before])
		dialogues[trainer_id + "_defeated"] = dialogue(name, [defeated])
		dialogues[trainer_id + "_after"] = dialogue(name, [after])
		trainers[trainer_id] = trainer_entry(name, klass, prize, team)
	for ident, value in T.items():
		dialogues[ident] = dialogue(*value)
	# Corentin d'Ébènelle ; celui de Rosalia ouvre `johto_corentin_flight` (`tools/gen_johp2_data.py`).
	dialogues["blackthorn_city_corentin"] = {"cutscene": "blackthorn_corentin_back"}
	dialogues["blackthorn_city_dracolosse"] = dialogue(NARRATION,
		["Le Dracolosse de Corentin bâille.", "Il a l'air de bien connaître le chemin."], True)
	dialogues["dragons_den_sanctuary_ysolde"] = {"speaker": "Ysolde", "variants": [
		{"if": [AWAKENED], "pages": [wrap(p) for p in YSOLDE_AFTER]},
		{"if": [TRIAL_DONE], "pages": [wrap(T["johp3_ysolde_waiting"][1][0])]},
		{"cutscene": "dragons_den_ysolde"},
	]}
	dialogues["dragons_den_sanctuary_aieule"] = {"speaker": "L'Aïeule", "variants": [
		{"unless": [HEALED], "set": [HEALED], "action": "heal",
			"pages": [wrap(HEAL_LINE), {"text": wrap(HEAL_DONE), "speaker": ""}]},
		{"pages": ["Une fois. Pas deux."]},
	]}
	dialogues["blackthorn_elder_house_aieule"] = {"speaker": "L'Aïeule", "variants": [
		{"if": [RETURNED], "pages": [wrap(p) for p in ELDER_AFTER]},
		{"if": [TRIAL_OPEN], "pages": [wrap(p) for p in ELDER_TRIAL]},
		{"set": [TRIAL_OPEN], "pages": [wrap(p) for p in ELDER_INTRO + ELDER_TRIAL]},
	]}

	for map_id in MAPS:
		npcs = {}
		for ident, (kind, cells, attrs, _comment) in read_plan(map_id).items():
			cell = list(cells[0])
			if kind == "dresseur":
				trainer_id = attrs["trainer"]
				if trainer_id == YSOLDE_ID:
					npcs[ident] = {"cell": cell, "facing": attrs["facing"],
						"sprite": ROLE_SPRITES["ysolde"], "dialogue": "dragons_den_sanctuary_ysolde"}
					continue
				npcs[ident] = {
					"cell": cell, "facing": attrs["facing"], "sprite": TRAINERS[trainer_id][2],
					"dialogue": trainer_id + "_after",
					"trainer": {"id": trainer_id, "sight": int(attrs["sight"]),
						"before": trainer_id + "_before", "defeated": trainer_id + "_defeated"},
				}
			elif kind == "pnj":
				entry = {"cell": cell, "facing": attrs.get("facing", "down"),
					"sprite": ROLE_SPRITES[attrs["role"]]}
				if ident == "cenere":
					# Posée par la scène de l'autel ; à l'entrée sur la carte, seulement après le
					# Réveil (défaite, application tuée).
					entry.update({"if": [AWAKENED], "unless": [CENERE_WON],
						"dialogue": "dragons_den_sanctuary_cenere"})
					dialogues["dragons_den_sanctuary_cenere"] = {"cutscene": "dragons_den_altar"}
				elif ident == "aieule":
					entry.update({"if": [GUARDIANS_DONE], "unless": [TRIAL_DONE],
						"dialogue": "dragons_den_sanctuary_aieule"})
				elif ident == "corentin":
					entry["dialogue"] = "blackthorn_city_corentin"
				npcs[ident] = entry
			elif kind == "pokemon":
				npcs[ident] = {"cell": cell, "facing": "left", "sprite": DRAGONITE_SPRITE,
					"dialogue": "blackthorn_city_dracolosse", "turn_to_player": False}
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
		write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)

	write_interiors(dialogues, cutscenes)
	write_encounters()
	patch_elder()
	patch_act2_trainers()
	write_json(os.path.join(DATA, "trainers", "johp3.json"), trainers)
	write_json(os.path.join(DATA, "dialogues", "johp3_blackthorn.json"), dialogues)
	write_json(os.path.join(DATA, "cutscenes", "johp3_blackthorn.json"), cutscenes)


def write_interiors(dialogues, cutscenes):
	"""Centre (infirmière, apprenti), maison de l'Aïeule (partie au Sanctuaire pendant le soin et
	Ysolde), maison et Rappel Max (§12). Cases des grilles de Lavanville réutilisées."""
	write_json(os.path.join(DATA, "npcs", "blackthorn_center.json"), {
		"nurse": {"cell": [7, 3], "facing": "down", "sprite": "nurse"},
		"apprenti": {"cell": [11, 5], "facing": "left", "sprite": "cooltrainer_m",
			"dialogue": "blackthorn_center_apprenti"},
	})
	write_json(os.path.join(DATA, "npcs", "blackthorn_elder_house.json"), {
		"aieule": {"cell": [7, 5], "facing": "down", "sprite": ROLE_SPRITES["aieule"],
			"dialogue": "blackthorn_elder_house_aieule", "unless": [GUARDIANS_DONE]},
		"aieule_home": {"cell": [7, 5], "facing": "down", "sprite": ROLE_SPRITES["aieule"],
			"dialogue": "blackthorn_elder_house_aieule", "if": [TRIAL_DONE]},
	})
	ident = "blackthorn_house_item"
	flag = "got_" + ident
	write_json(os.path.join(DATA, "npcs", "blackthorn_house_1.json"), {
		"habitante": {"cell": [12, 6], "facing": "left", "sprite": "beauty",
			"dialogue": "blackthorn_house_1_habitante"},
		ident: {"cell": [2, 5], "facing": "down", "sprite": "object/poke_ball_ground",
			"dialogue": ident, "verb": "take", "turn_to_player": False, "unless": [flag]},
	})
	dialogues[ident] = {"cutscene": ident}
	cutscenes[ident] = item_scene(ident, "max_repel", 1, flag, True)


def with_moves(trainer):
	for member in trainer["team"]:
		if member["species"] in MOVE_SETS:
			member["moves"] = MOVE_SETS[member["species"]]
	trainer["switch"] = True


def patch_act2_trainers():
	"""Décision de Kevin du 2026-11-05 : Brace (JOH6) et Cenere des Îles Tourbillon (JOH7), au-delà de
	80 % contre une équipe mixte, reçoivent attaques choisies, changements et niveaux [D] ; Cenere
	s'arrête à 66, en dessous de Dante (1). Seuls ces deux adversaires changent. Relançable."""
	for file, ident, levels in (
			("mahogany_hideout_b3f.json", "mahogany_hideout_b3f_brace", [63, 63, 64, 65]),
			("joh7.json", "whirl_islands_cenere", [64, 64, 65, 65, 66])):
		path = os.path.join(DATA, "trainers", file)
		with open(path, encoding="utf-8") as handle:
			data = json.load(handle)
		with_moves(data[ident])
		for member, level in zip(data[ident]["team"], levels):
			member["level"] = level
		write_json(path, data)


def patch_elder():
	"""P-54 : le doyen de Rosalia pendant l'arc, devant ses répliques d'acte 1 (la scène du doyen se
	complète sur place, comme `tools/gen_joh8_data.py`). Relançable."""
	path = os.path.join(DATA, "dialogues", "joh2_ecruteak_interiors.json")
	with open(path, encoding="utf-8") as handle:
		data = json.load(handle)
	doyen = data["ecruteak_elders_house_doyen"]
	variants = [v for v in doyen["variants"] if v.get("pages", [""])[0] != ELDER_P54[0]]
	at = next(i for i, v in enumerate(variants) if "johto_dante_plan_known" in v.get("if", []))
	variants.insert(at, {"if": ["johto_stones_quest"], "unless": [ACT2], "pages": ELDER_P54})
	doyen["variants"] = variants
	write_json(path, data)


def write_encounters():
	for group, tables in ENCOUNTERS.items():
		out = {}
		for table_id, terrain, periods, rate, slots in tables:
			table = {"maps": ENCOUNTER_MAPS.get(group, [group]), "terrain": terrain}
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
